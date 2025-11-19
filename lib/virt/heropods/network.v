module heropods

import incubaid.herolib.osal.core as osal
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
pub mut:
	bridge_name    string            // Name of the bridge (e.g., "heropods0")
	subnet         string            // Subnet for the bridge (e.g., "10.10.0.0/24")
	gateway_ip     string            // Gateway IP for the bridge
	dns_servers    []string          // List of DNS servers
	allocated_ips  map[string]string // container_name -> IP address
	freed_ip_pool  []int             // Pool of freed IP offsets for reuse (e.g., [15, 23, 42])
	next_ip_offset int = 10 // Start allocating from 10.10.0.10 (only used when pool is empty)
}

// Initialize network configuration in HeroPods factory
fn (mut self HeroPods) network_init() ! {
	self.logger.log(
		cat: 'network'
		log: 'START network_init() - Initializing HeroPods network layer'
	) or {}

	// Setup host bridge if it doesn't exist
	self.logger.log(
		cat:     'network'
		log:     'Calling network_setup_bridge()...'
		logtype: .stdout
	) or {}

	self.network_setup_bridge()!

	self.logger.log(
		cat:     'network'
		log:     'END network_init() - HeroPods network layer initialized successfully'
		logtype: .stdout
	) or {}
}

// Setup the host bridge network (one-time setup, idempotent)
fn (mut self HeroPods) network_setup_bridge() ! {
	bridge_name := self.network_config.bridge_name
	gateway_ip := '${self.network_config.gateway_ip}/${self.network_config.subnet.split('/')[1]}'
	subnet := self.network_config.subnet

	self.logger.log(
		cat:     'network'
		log:     'START network_setup_bridge() - bridge=${bridge_name}, gateway=${gateway_ip}, subnet=${subnet}'
		logtype: .stdout
	) or {}

	// Check if bridge already exists using os.execute (more reliable than osal.exec)
	self.logger.log(
		cat:     'network'
		log:     'Checking if bridge ${bridge_name} exists (running: ip link show ${bridge_name})...'
		logtype: .stdout
	) or {}

	check_result := os.execute('ip link show ${bridge_name} 2>/dev/null')

	self.logger.log(
		cat:     'network'
		log:     'Bridge check result: exit_code=${check_result.exit_code}'
		logtype: .stdout
	) or {}

	if check_result.exit_code == 0 {
		self.logger.log(
			cat:     'network'
			log:     'Bridge ${bridge_name} already exists - skipping creation'
			logtype: .stdout
		) or {}
		return
	}

	self.logger.log(
		cat:     'network'
		log:     'Bridge ${bridge_name} does not exist - creating new bridge'
		logtype: .stdout
	) or {}

	// Create bridge
	self.logger.log(
		cat:     'network'
		log:     'Step 1: Creating bridge (running: ip link add name ${bridge_name} type bridge)...'
		logtype: .stdout
	) or {}

	osal.exec(
		cmd:    'ip link add name ${bridge_name} type bridge'
		stdout: false
	)!

	self.logger.log(
		cat:     'network'
		log:     'Step 1: Bridge created successfully'
		logtype: .stdout
	) or {}

	// Assign IP to bridge
	self.logger.log(
		cat:     'network'
		log:     'Step 2: Assigning IP to bridge (running: ip addr add ${gateway_ip} dev ${bridge_name})...'
		logtype: .stdout
	) or {}

	osal.exec(
		cmd:    'ip addr add ${gateway_ip} dev ${bridge_name}'
		stdout: false
	)!

	self.logger.log(
		cat:     'network'
		log:     'Step 2: IP assigned successfully'
		logtype: .stdout
	) or {}

	// Bring bridge up
	self.logger.log(
		cat:     'network'
		log:     'Step 3: Bringing bridge up (running: ip link set ${bridge_name} up)...'
		logtype: .stdout
	) or {}

	osal.exec(
		cmd:    'ip link set ${bridge_name} up'
		stdout: false
	)!

	self.logger.log(
		cat:     'network'
		log:     'Step 3: Bridge brought up successfully'
		logtype: .stdout
	) or {}

	// Enable IP forwarding
	self.logger.log(
		cat:     'network'
		log:     'Step 4: Enabling IP forwarding (running: sysctl -w net.ipv4.ip_forward=1)...'
		logtype: .stdout
	) or {}

	forward_result := os.execute('sysctl -w net.ipv4.ip_forward=1 2>/dev/null')
	if forward_result.exit_code != 0 {
		self.logger.log(
			cat:     'network'
			log:     'Step 4: WARNING - Failed to enable IPv4 forwarding (exit_code=${forward_result.exit_code})'
			logtype: .error
		) or {}
	} else {
		self.logger.log(
			cat:     'network'
			log:     'Step 4: IP forwarding enabled successfully'
			logtype: .stdout
		) or {}
	}

	// Get primary network interface for NAT
	self.logger.log(
		cat:     'network'
		log:     'Step 5: Detecting primary network interface...'
		logtype: .stdout
	) or {}

	primary_iface := self.network_get_primary_interface() or {
		self.logger.log(
			cat:     'network'
			log:     'Step 5: WARNING - Could not detect primary interface: ${err}, using fallback eth0'
			logtype: .error
		) or {}
		'eth0' // fallback
	}

	self.logger.log(
		cat:     'network'
		log:     'Step 5: Primary interface detected: ${primary_iface}'
		logtype: .stdout
	) or {}

	// Setup NAT for outbound traffic

	self.logger.log(
		cat:     'network'
		log:     'Step 6: Setting up NAT rules for ${primary_iface} (running iptables command)...'
		logtype: .stdout
	) or {}

	nat_result := os.execute('iptables -t nat -C POSTROUTING -s ${subnet} -o ${primary_iface} -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s ${subnet} -o ${primary_iface} -j MASQUERADE')
	if nat_result.exit_code != 0 {
		self.logger.log(
			cat:     'network'
			log:     'Step 6: WARNING - Failed to setup NAT rules (exit_code=${nat_result.exit_code})'
			logtype: .error
		) or {}
	} else {
		self.logger.log(
			cat:     'network'
			log:     'Step 6: NAT rules configured successfully'
			logtype: .stdout
		) or {}
	}

	// Setup FORWARD rules to allow traffic from/to the bridge
	self.logger.log(
		cat:     'network'
		log:     'Step 7: Setting up FORWARD rules for ${bridge_name}...'
		logtype: .stdout
	) or {}

	// Allow forwarding from bridge to external interface
	forward_out_result := os.execute('iptables -C FORWARD -i ${bridge_name} -o ${primary_iface} -j ACCEPT 2>/dev/null || iptables -A FORWARD -i ${bridge_name} -o ${primary_iface} -j ACCEPT')
	if forward_out_result.exit_code != 0 {
		self.logger.log(
			cat:     'network'
			log:     'Step 7: WARNING - Failed to setup FORWARD rule (bridge -> external) (exit_code=${forward_out_result.exit_code})'
			logtype: .error
		) or {}
	}

	// Allow forwarding from external interface to bridge (for established connections)
	forward_in_result := os.execute('iptables -C FORWARD -i ${primary_iface} -o ${bridge_name} -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || iptables -A FORWARD -i ${primary_iface} -o ${bridge_name} -m state --state RELATED,ESTABLISHED -j ACCEPT')
	if forward_in_result.exit_code != 0 {
		self.logger.log(
			cat:     'network'
			log:     'Step 7: WARNING - Failed to setup FORWARD rule (external -> bridge) (exit_code=${forward_in_result.exit_code})'
			logtype: .error
		) or {}
	}

	// Allow forwarding between containers on the same bridge
	forward_bridge_result := os.execute('iptables -C FORWARD -i ${bridge_name} -o ${bridge_name} -j ACCEPT 2>/dev/null || iptables -A FORWARD -i ${bridge_name} -o ${bridge_name} -j ACCEPT')
	if forward_bridge_result.exit_code != 0 {
		self.logger.log(
			cat:     'network'
			log:     'Step 7: WARNING - Failed to setup FORWARD rule (bridge -> bridge) (exit_code=${forward_bridge_result.exit_code})'
			logtype: .error
		) or {}
	}

	self.logger.log(
		cat:     'network'
		log:     'Step 7: FORWARD rules configured successfully'
		logtype: .stdout
	) or {}

	self.logger.log(
		cat:     'network'
		log:     'END network_setup_bridge() - Bridge ${bridge_name} created and configured successfully'
		logtype: .stdout
	) or {}
}

// Get the primary network interface for NAT
fn (mut self HeroPods) network_get_primary_interface() !string {
	self.logger.log(
		cat:     'network'
		log:     'START network_get_primary_interface() - Detecting primary interface'
		logtype: .stdout
	) or {}

	// Try to get the default route interface
	cmd := "ip route | grep default | awk '{print \$5}' | head -n1"
	self.logger.log(
		cat:     'network'
		log:     'Running command: ${cmd}'
		logtype: .stdout
	) or {}

	result := osal.exec(
		cmd:    cmd
		stdout: false
	)!

	self.logger.log(
		cat:     'network'
		log:     'Command completed, output: "${result.output.trim_space()}"'
		logtype: .stdout
	) or {}

	iface := result.output.trim_space()
	if iface == '' {
		self.logger.log(
			cat:     'network'
			log:     'ERROR: Could not determine primary network interface (empty output)'
			logtype: .error
		) or {}
		return error('Could not determine primary network interface')
	}

	self.logger.log(
		cat:     'network'
		log:     'END network_get_primary_interface() - Detected interface: ${iface}'
		logtype: .stdout
	) or {}

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
	self.logger.log(
		cat:     'network'
		log:     'START network_allocate_ip() for container: ${container_name}'
		logtype: .stdout
	) or {}

	self.logger.log(
		cat:     'network'
		log:     'Acquiring network_mutex lock...'
		logtype: .stdout
	) or {}

	self.network_mutex.@lock()

	self.logger.log(
		cat:     'network'
		log:     'network_mutex lock acquired'
		logtype: .stdout
	) or {}

	defer {
		self.logger.log(
			cat:     'network'
			log:     'Releasing network_mutex lock...'
			logtype: .stdout
		) or {}
		self.network_mutex.unlock()
		self.logger.log(
			cat:     'network'
			log:     'network_mutex lock released'
			logtype: .stdout
		) or {}
	}

	// Check if already allocated
	if container_name in self.network_config.allocated_ips {
		existing_ip := self.network_config.allocated_ips[container_name]
		self.logger.log(
			cat:     'network'
			log:     'Container ${container_name} already has IP: ${existing_ip}'
			logtype: .stdout
		) or {}
		return existing_ip
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
		self.logger.log(
			cat:     'network'
			log:     'Reusing IP offset ${ip_offset} from freed pool (pool size: ${self.network_config.freed_ip_pool.len})'
			logtype: .stdout
		) or {}
	} else {
		// No freed IPs available, allocate a new one
		// This increment is atomic within the mutex lock
		ip_offset = self.network_config.next_ip_offset
		self.network_config.next_ip_offset++

		// Check if we're approaching the subnet limit (254 usable IPs in /24)
		if ip_offset > 254 {
			return error('IP address pool exhausted: subnet ${self.network_config.subnet} has no more available IPs. Consider using a larger subnet or multiple bridges.')
		}

		self.logger.log(
			cat:     'network'
			log:     'Allocated new IP offset ${ip_offset} (next: ${self.network_config.next_ip_offset})'
			logtype: .stdout
		) or {}
	}

	// Build the full IP address
	ip := '${base_ip}.${ip_offset}'
	self.network_config.allocated_ips[container_name] = ip

	self.logger.log(
		cat:     'network'
		log:     'Allocated IP ${ip} to container ${container_name}'
		logtype: .stdout
	) or {}
	return ip
}

// Setup network for a container (creates veth pair, assigns IP, configures routing)
fn (mut self HeroPods) network_setup_container(container_name string, container_pid int) ! {
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

	osal.exec(
		cmd:    'ip link set ${veth_container_short} netns ${container_pid}'
		stdout: false
	)!

	// Configure network inside container

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
}

// Configure DNS inside container by writing resolv.conf
fn (self HeroPods) network_configure_dns(container_name string, rootfs_path string) ! {
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
}

// Cleanup network for a container (removes veth pair and deallocates IP)
//
// Thread Safety:
// IP deallocation is protected by network_mutex to prevent race conditions
// when multiple containers are being deleted concurrently.
fn (mut self HeroPods) network_cleanup_container(container_name string) ! {
	// Remove veth interfaces (they should be auto-removed when container stops, but cleanup anyway)
	// Use same hash logic as setup to ensure we delete the correct interface
	short_hash := sha256.hexhash(container_name)[..6]
	veth_bridge_short := 'vbr-${short_hash}'

	osal.exec(
		cmd:    'ip link delete ${veth_bridge_short} 2>/dev/null'
		stdout: false
	) or {}

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
			}
		}

		// Remove from allocated IPs
		self.network_config.allocated_ips.delete(container_name)
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
	// Get list of containers to cleanup (thread-safe read)
	self.network_mutex.@lock()
	container_names := self.network_config.allocated_ips.keys()
	self.network_mutex.unlock()

	// Remove all veth interfaces (no lock needed - operates on local copy)
	for container_name in container_names {
		self.network_cleanup_container(container_name) or {
		}
	}

	// Clear allocated IPs and freed pool (thread-safe write)
	self.network_mutex.@lock()
	self.network_config.allocated_ips.clear()
	self.network_config.freed_ip_pool.clear()
	self.network_config.next_ip_offset = 10
	self.network_mutex.unlock()

	// Optionally remove the bridge for full cleanup
	if full {
		bridge_name := self.network_config.bridge_name

		osal.exec(
			cmd:    'ip link delete ${bridge_name}'
			stdout: false
		) or {}
	}
}
