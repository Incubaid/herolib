module heropods

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import os
import crypto.sha256

// Network configuration for HeroPods
//
// This module provides container networking similar to Docker/Podman:
// - Bridge networking with automatic IP allocation
// - NAT for outbound internet access
// - DNS configuration
// - veth pair management
//
// Thread Safety:
// All network_config operations are protected by HeroPods.network_mutex.
// The struct is not marked as `shared` to maintain compatibility with
// paramsparser's compile-time reflection.
//
// Future extension possibilities:
// - IPv6 support
// - Custom per-container DNS servers
// - iptables isolation (firewall per container)
// - Multiple bridges for isolated networks
// - Port forwarding/mapping
// - Network policies and traffic shaping

// NetworkConfig holds network configuration for HeroPods containers
struct NetworkConfig {
mut:
	bridge_name    string   = 'heropods0'
	subnet         string   = '10.10.0.0/24'
	gateway_ip     string   = '10.10.0.1'
	dns_servers    []string = ['8.8.8.8', '8.8.4.4']
	allocated_ips  map[string]string // container_name -> IP address
	freed_ip_pool  []int             // Pool of freed IP offsets for reuse (e.g., [15, 23, 42])
	next_ip_offset int = 10 // Start allocating from 10.10.0.10 (only used when pool is empty)
}

// Initialize network configuration in HeroPods factory
fn (mut self HeroPods) network_init() ! {
	console.print_debug('Initializing HeroPods network layer...')

	// Setup host bridge if it doesn't exist
	self.network_setup_bridge()!

	console.print_debug('HeroPods network layer initialized')
}

// Setup the host bridge network (one-time setup, idempotent)
fn (mut self HeroPods) network_setup_bridge() ! {
	bridge_name := self.network_config.bridge_name
	gateway_ip := '${self.network_config.gateway_ip}/${self.network_config.subnet.split('/')[1]}'
	subnet := self.network_config.subnet

	// Check if bridge already exists
	result := osal.exec(
		cmd:         'ip link show ${bridge_name}'
		stdout:      false
		raise_error: false
	) or {
		osal.Job{
			exit_code: 1
		}
	}

	if result.exit_code == 0 {
		console.print_debug('Bridge ${bridge_name} already exists')
		return
	}

	console.print_debug('Creating bridge ${bridge_name}...')

	// Create bridge
	osal.exec(
		cmd:    'ip link add name ${bridge_name} type bridge'
		stdout: false
	)!

	// Assign IP to bridge
	osal.exec(
		cmd:    'ip addr add ${gateway_ip} dev ${bridge_name}'
		stdout: false
	)!

	// Bring bridge up
	osal.exec(
		cmd:    'ip link set ${bridge_name} up'
		stdout: false
	)!

	// Enable IP forwarding (with error resilience)
	osal.exec(
		cmd:    'sysctl -w net.ipv4.ip_forward=1'
		stdout: false
	) or {
		console.print_stderr('Warning: Failed to enable IPv4 forwarding. Containers may not have internet access.')
		console.print_debug('You may need to run: sudo sysctl -w net.ipv4.ip_forward=1')
	}

	// Get primary network interface for NAT
	primary_iface := self.network_get_primary_interface() or {
		console.print_stderr('Warning: Could not detect primary network interface. NAT may not work.')
		'eth0' // fallback
	}

	// Setup NAT for outbound traffic (with error resilience)
	console.print_debug('Setting up NAT rules for ${primary_iface}...')
	osal.exec(
		cmd:    'iptables -t nat -C POSTROUTING -s ${subnet} -o ${primary_iface} -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s ${subnet} -o ${primary_iface} -j MASQUERADE'
		stdout: false
	) or {
		console.print_stderr('Warning: Failed to setup NAT rules. Containers may not have internet access.')
		console.print_debug('You may need to run: sudo iptables -t nat -A POSTROUTING -s ${subnet} -o ${primary_iface} -j MASQUERADE')
	}

	console.print_green('Bridge ${bridge_name} created and configured')
}

// Get the primary network interface for NAT
fn (self HeroPods) network_get_primary_interface() !string {
	// Try to get the default route interface
	result := osal.exec(
		cmd:    "ip route | grep default | awk '{print \$5}' | head -n1"
		stdout: false
	)!

	iface := result.output.trim_space()
	if iface == '' {
		return error('Could not determine primary network interface')
	}

	return iface
}

// Allocate an IP address for a container (thread-safe)
//
// IP REUSE STRATEGY:
// 1. First, try to reuse an IP from the freed_ip_pool (recycled IPs from deleted containers)
// 2. If pool is empty, allocate a new IP by incrementing next_ip_offset
// 3. This prevents IP exhaustion in a /24 subnet (254 usable IPs)
//
// Thread Safety:
// This function uses network_mutex to ensure atomic IP allocation.
// Multiple concurrent container starts will be serialized at the IP allocation step,
// preventing race conditions where two containers could receive the same IP.
fn (mut self HeroPods) network_allocate_ip(container_name string) !string {
	self.network_mutex.@lock()
	defer {
		self.network_mutex.unlock()
	}

	// Check if already allocated
	if container_name in self.network_config.allocated_ips {
		return self.network_config.allocated_ips[container_name]
	}

	// Extract base IP from subnet (e.g., "10.10.0.0/24" -> "10.10.0")
	subnet_parts := self.network_config.subnet.split('/')
	base_ip_parts := subnet_parts[0].split('.')
	base_ip := '${base_ip_parts[0]}.${base_ip_parts[1]}.${base_ip_parts[2]}'

	// Determine IP offset: reuse from pool first, then increment
	mut ip_offset := 0
	if self.network_config.freed_ip_pool.len > 0 {
		// Reuse a freed IP from the pool (LIFO - pop from end)
		ip_offset = self.network_config.freed_ip_pool.last()
		self.network_config.freed_ip_pool.delete_last()
		console.print_debug('Reusing IP offset ${ip_offset} from freed pool (pool size: ${self.network_config.freed_ip_pool.len})')
	} else {
		// No freed IPs available, allocate a new one
		// This increment is atomic within the mutex lock
		ip_offset = self.network_config.next_ip_offset
		self.network_config.next_ip_offset++

		// Check if we're approaching the subnet limit (254 usable IPs in /24)
		if ip_offset > 254 {
			return error('IP address pool exhausted: subnet ${self.network_config.subnet} has no more available IPs. Consider using a larger subnet or multiple bridges.')
		}

		console.print_debug('Allocated new IP offset ${ip_offset} (next: ${self.network_config.next_ip_offset})')
	}

	// Build the full IP address
	ip := '${base_ip}.${ip_offset}'
	self.network_config.allocated_ips[container_name] = ip

	console.print_debug('Allocated IP ${ip} to container ${container_name}')
	return ip
}

// Setup network for a container (creates veth pair, assigns IP, configures routing)
fn (mut self HeroPods) network_setup_container(container_name string, container_pid int) ! {
	console.print_debug('Setting up network for container ${container_name} (PID: ${container_pid})...')

	// Allocate IP address (thread-safe)
	container_ip := self.network_allocate_ip(container_name)!

	bridge_name := self.network_config.bridge_name
	subnet_mask := self.network_config.subnet.split('/')[1]
	gateway_ip := self.network_config.gateway_ip

	// Create veth pair with unique names using hash to avoid collisions
	// Interface names are limited to 15 chars, so we use a hash suffix
	short_hash := sha256.hexhash(container_name)[..6]
	veth_container_short := 'veth-${short_hash}'
	veth_bridge_short := 'vbr-${short_hash}'

	// Delete veth pair if it already exists (cleanup from previous run)
	osal.exec(cmd: 'ip link delete ${veth_container_short} 2>/dev/null', stdout: false) or {}
	osal.exec(cmd: 'ip link delete ${veth_bridge_short} 2>/dev/null', stdout: false) or {}

	// Create veth pair
	console.print_debug('Creating veth pair: ${veth_container_short} <-> ${veth_bridge_short}')
	osal.exec(
		cmd:    'ip link add ${veth_container_short} type veth peer name ${veth_bridge_short}'
		stdout: false
	)!

	// Attach bridge end to bridge
	osal.exec(
		cmd:    'ip link set ${veth_bridge_short} master ${bridge_name}'
		stdout: false
	)!

	osal.exec(
		cmd:    'ip link set ${veth_bridge_short} up'
		stdout: false
	)!

	// Move container end into container's network namespace
	console.print_debug('Moving ${veth_container_short} into container namespace (PID: ${container_pid})')
	osal.exec(
		cmd:    'ip link set ${veth_container_short} netns ${container_pid}'
		stdout: false
	)!

	// Configure network inside container
	console.print_debug('Configuring network inside container: ${container_ip}/${subnet_mask}')

	// Rename veth to eth0 inside container for consistency
	osal.exec(
		cmd:    'nsenter -t ${container_pid} -n ip link set ${veth_container_short} name eth0'
		stdout: false
	)!

	// Assign IP address
	osal.exec(
		cmd:    'nsenter -t ${container_pid} -n ip addr add ${container_ip}/${subnet_mask} dev eth0'
		stdout: false
	)!

	// Bring interface up
	osal.exec(
		cmd:    'nsenter -t ${container_pid} -n ip link set dev eth0 up'
		stdout: false
	)!

	// Add default route using gateway IP
	osal.exec(
		cmd:    'nsenter -t ${container_pid} -n ip route add default via ${gateway_ip}'
		stdout: false
	)!

	console.print_green('Network configured for container ${container_name}: ${container_ip}')
}

// Configure DNS inside container by writing resolv.conf
fn (self HeroPods) network_configure_dns(container_name string, rootfs_path string) ! {
	console.print_debug('Configuring DNS for container ${container_name}...')

	resolv_conf_path := '${rootfs_path}/etc/resolv.conf'

	// Ensure /etc directory exists
	etc_dir := '${rootfs_path}/etc'
	if !os.exists(etc_dir) {
		os.mkdir_all(etc_dir)!
	}

	// Build DNS configuration from configured DNS servers
	mut dns_lines := []string{}
	for dns_server in self.network_config.dns_servers {
		dns_lines << 'nameserver ${dns_server}'
	}
	dns_content := dns_lines.join('\n') + '\n'

	os.write_file(resolv_conf_path, dns_content)!

	dns_servers_str := self.network_config.dns_servers.join(', ')
	console.print_debug('DNS configured: ${dns_servers_str}')
}

// Cleanup network for a container (removes veth pair and deallocates IP)
//
// Thread Safety:
// IP deallocation is protected by network_mutex to prevent race conditions
// when multiple containers are being deleted concurrently.
fn (mut self HeroPods) network_cleanup_container(container_name string) ! {
	console.print_debug('Cleaning up network for container ${container_name}...')

	// Remove veth interfaces (they should be auto-removed when container stops, but cleanup anyway)
	// Use same hash logic as setup to ensure we delete the correct interface
	short_hash := sha256.hexhash(container_name)[..6]
	veth_bridge_short := 'vbr-${short_hash}'

	osal.exec(
		cmd:    'ip link delete ${veth_bridge_short} 2>/dev/null'
		stdout: false
	) or { console.print_debug('veth interface ${veth_bridge_short} already removed') }

	// Deallocate IP address and return it to the freed pool for reuse (thread-safe)
	self.network_mutex.@lock()
	defer {
		self.network_mutex.unlock()
	}

	if container_name in self.network_config.allocated_ips {
		ip := self.network_config.allocated_ips[container_name]

		// Extract the IP offset from the full IP address (e.g., "10.10.0.42" -> 42)
		ip_parts := ip.split('.')
		if ip_parts.len == 4 {
			ip_offset := ip_parts[3].int()

			// Add to freed pool for reuse (avoid duplicates)
			if ip_offset !in self.network_config.freed_ip_pool {
				self.network_config.freed_ip_pool << ip_offset
				console.print_debug('Returned IP offset ${ip_offset} to freed pool (pool size: ${self.network_config.freed_ip_pool.len})')
			}
		}

		// Remove from allocated IPs
		self.network_config.allocated_ips.delete(container_name)
		console.print_debug('Deallocated IP ${ip} from container ${container_name}')
	}
}

// Cleanup all network resources (called on reset)
//
// Parameters:
// - full: if true, also removes the bridge (for complete teardown)
//         if false, keeps the bridge for reuse (default)
//
// Thread Safety:
// Uses separate lock/unlock calls for read and write operations to minimize
// lock contention. The container cleanup loop runs without holding the lock.
fn (mut self HeroPods) network_cleanup_all(full bool) ! {
	console.print_debug('Cleaning up all HeroPods network resources (full=${full})...')

	// Get list of containers to cleanup (thread-safe read)
	self.network_mutex.@lock()
	container_names := self.network_config.allocated_ips.keys()
	self.network_mutex.unlock()

	// Remove all veth interfaces (no lock needed - operates on local copy)
	for container_name in container_names {
		self.network_cleanup_container(container_name) or {
			console.print_debug('Failed to cleanup network for ${container_name}: ${err}')
		}
	}

	// Clear allocated IPs and freed pool (thread-safe write)
	self.network_mutex.@lock()
	self.network_config.allocated_ips.clear()
	self.network_config.freed_ip_pool.clear()
	self.network_config.next_ip_offset = 10
	self.network_mutex.unlock()

	console.print_debug('Cleared IP allocations and freed pool')

	// Optionally remove the bridge for full cleanup
	if full {
		bridge_name := self.network_config.bridge_name

		console.print_debug('Removing bridge ${bridge_name}...')
		osal.exec(
			cmd:    'ip link delete ${bridge_name}'
			stdout: false
		) or { console.print_debug('Bridge ${bridge_name} already removed or does not exist') }
	}

	console.print_debug('Network cleanup complete')
}
