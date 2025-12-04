module heropods

import incubaid.herolib.osal.core as osal
import incubaid.herolib.clients.mycelium
import crypto.sha256
import time

// Initialize Mycelium for HeroPods
//
// This method:
// 1. Validates required configuration
// 2. Checks that Mycelium binary is installed
// 3. Checks that Mycelium service is running
// 4. Retrieves the host's Mycelium IPv6 address
//
// Prerequisites:
// - Mycelium must be installed on the system
// - Mycelium service must be running
//
// Thread Safety:
// This is called during HeroPods initialization, before any concurrent operations.
fn (mut self HeroPods) mycelium_init() ! {
	if !self.mycelium_enabled {
		return
	}

	// Validate required configuration
	if self.mycelium_version == '' {
		return error('Mycelium configuration error: "version" is required. Use heropods.enable_mycelium to configure.')
	}
	if self.mycelium_ipv6_range == '' {
		return error('Mycelium configuration error: "ipv6_range" is required. Use heropods.enable_mycelium to configure.')
	}
	if self.mycelium_key_path == '' {
		return error('Mycelium configuration error: "key_path" is required. Use heropods.enable_mycelium to configure.')
	}
	if self.mycelium_peers.len == 0 {
		return error('Mycelium configuration error: "peers" is required. Use heropods.enable_mycelium to configure.')
	}

	self.logger.log(
		cat: 'mycelium'
		log: 'START mycelium_init() - Initializing Mycelium IPv6 overlay network'
	) or {}

	// Check if Mycelium is installed - it's a prerequisite
	if !self.mycelium_check_installed()! {
		return error('Mycelium is not installed. Please install Mycelium first. See: https://github.com/threefoldtech/mycelium')
	}

	self.logger.log(
		cat:     'mycelium'
		log:     'Mycelium binary found'
		logtype: .stdout
	) or {}

	// Check if Mycelium service is running - it's a prerequisite
	if !self.mycelium_check_running()! {
		return error('Mycelium service is not running. Please start Mycelium service first (e.g., mycelium --key-file ${self.mycelium_key_path} --peers <peers>)')
	}

	self.logger.log(
		cat:     'mycelium'
		log:     'Mycelium service is running'
		logtype: .stdout
	) or {}

	// Get and cache the host's Mycelium IPv6 address
	self.mycelium_get_host_address()!

	self.logger.log(
		cat:     'mycelium'
		log:     'END mycelium_init() - Mycelium initialized successfully with address ${self.mycelium_ip6}'
		logtype: .stdout
	) or {}
}

// Check if Mycelium binary is installed
fn (mut self HeroPods) mycelium_check_installed() !bool {
	return osal.cmd_exists('mycelium')
}

// Check if Mycelium service is running
fn (mut self HeroPods) mycelium_check_running() !bool {
	// Try to inspect Mycelium - if it succeeds, it's running
	mycelium.inspect(key_file_path: self.mycelium_key_path) or { return false }
	return true
}

// Get the host's Mycelium IPv6 address
fn (mut self HeroPods) mycelium_get_host_address() ! {
	self.logger.log(
		cat:     'mycelium'
		log:     'Retrieving host Mycelium IPv6 address...'
		logtype: .stdout
	) or {}

	// Use mycelium inspect to get the address
	inspect_result := mycelium.inspect(key_file_path: self.mycelium_key_path)!

	if inspect_result.address == '' {
		return error('Failed to get Mycelium IPv6 address from inspect')
	}

	self.mycelium_ip6 = inspect_result.address

	self.logger.log(
		cat:     'mycelium'
		log:     'Host Mycelium IPv6 address: ${self.mycelium_ip6}'
		logtype: .stdout
	) or {}
}

// Setup Mycelium IPv6 networking for a container
//
// This method:
// 1. Creates a veth pair for Mycelium connectivity
// 2. Moves one end into the container's network namespace
// 3. Assigns a Mycelium IPv6 address to the container
// 4. Configures IPv6 forwarding and routing
//
// Thread Safety:
// This is called from container.start() which is already serialized per container.
// Multiple containers can be started concurrently, each with their own veth pair.
fn (mut self HeroPods) mycelium_setup_container(container_name string, container_pid int) ! {
	if !self.mycelium_enabled {
		return
	}

	self.logger.log(
		cat:     'mycelium'
		log:     'Setting up Mycelium IPv6 for container ${container_name} (PID: ${container_pid})'
		logtype: .stdout
	) or {}

	// Create unique veth pair names using hash (same pattern as IPv4 networking)
	short_hash := sha256.hexhash(container_name)[..6]
	veth_container := 'vmy-${short_hash}'
	veth_host := 'vmyh-${short_hash}'

	// Delete veth pair if it already exists (cleanup from previous run)
	osal.exec(cmd: 'ip link delete ${veth_container} 2>/dev/null', stdout: false) or {}
	osal.exec(cmd: 'ip link delete ${veth_host} 2>/dev/null', stdout: false) or {}

	// Create veth pair
	self.logger.log(
		cat:     'mycelium'
		log:     'Creating veth pair: ${veth_container} <-> ${veth_host}'
		logtype: .stdout
	) or {}

	osal.exec(
		cmd:    'ip link add ${veth_container} type veth peer name ${veth_host}'
		stdout: false
	)!

	// Bring up host end
	osal.exec(
		cmd:    'ip link set ${veth_host} up'
		stdout: false
	)!

	// Move container end into container's network namespace
	self.logger.log(
		cat:     'mycelium'
		log:     'Moving ${veth_container} into container namespace'
		logtype: .stdout
	) or {}

	osal.exec(
		cmd:    'ip link set ${veth_container} netns ${container_pid}'
		stdout: false
	)!

	// Configure container end inside the namespace
	// Bring up the interface
	osal.exec(
		cmd:    'nsenter -t ${container_pid} -n ip link set ${veth_container} up'
		stdout: false
	)!

	// Get the Mycelium IPv6 prefix from the host
	// Extract the prefix from the full address (e.g., "400:1234:5678::/64" from "400:1234:5678::1")
	mycelium_prefix := self.mycelium_get_ipv6_prefix()!

	// Assign IPv6 address to container (use ::1 in the subnet)
	container_ip6 := '${mycelium_prefix}::1/64'

	self.logger.log(
		cat:     'mycelium'
		log:     'Assigning IPv6 address ${container_ip6} to container'
		logtype: .stdout
	) or {}

	osal.exec(
		cmd:    'nsenter -t ${container_pid} -n ip addr add ${container_ip6} dev ${veth_container}'
		stdout: false
	)!

	// Enable IPv6 forwarding on the host
	self.logger.log(
		cat:     'mycelium'
		log:     'Enabling IPv6 forwarding'
		logtype: .stdout
	) or {}

	osal.exec(
		cmd:    'sysctl -w net.ipv6.conf.all.forwarding=1'
		stdout: false
	) or {
		self.logger.log(
			cat:     'mycelium'
			log:     'Warning: Failed to enable IPv6 forwarding: ${err}'
			logtype: .error
		) or {}
		osal.Job{}
	}

	// Get the link-local address of the host end of the veth pair
	veth_host_ll := self.mycelium_get_link_local_address(veth_host)!

	// Add route in container for Mycelium traffic (400::/7 via link-local)
	self.logger.log(
		cat:     'mycelium'
		log:     'Adding route for ${self.mycelium_ipv6_range} via ${veth_host_ll}'
		logtype: .stdout
	) or {}

	osal.exec(
		cmd:    'nsenter -t ${container_pid} -n ip route add ${self.mycelium_ipv6_range} via ${veth_host_ll} dev ${veth_container}'
		stdout: false
	)!

	// Add route on host for container's IPv6 address
	self.logger.log(
		cat:     'mycelium'
		log:     'Adding host route for ${mycelium_prefix}::1/128'
		logtype: .stdout
	) or {}

	osal.exec(
		cmd:    'ip route add ${mycelium_prefix}::1/128 dev ${veth_host}'
		stdout: false
	)!

	self.logger.log(
		cat:     'mycelium'
		log:     'Mycelium IPv6 setup complete for container ${container_name}'
		logtype: .stdout
	) or {}
}

// Get the IPv6 prefix from the host's Mycelium address
//
// Extracts the /64 prefix from the full IPv6 address
// Example: "400:1234:5678::1" -> "400:1234:5678:"
fn (mut self HeroPods) mycelium_get_ipv6_prefix() !string {
	if self.mycelium_ip6 == '' {
		return error('Mycelium IPv6 address not set')
	}

	// Split the address by ':' and take the first 3 parts for /64 prefix
	parts := self.mycelium_ip6.split(':')
	if parts.len < 3 {
		return error('Invalid Mycelium IPv6 address format: ${self.mycelium_ip6}')
	}

	// Reconstruct the prefix (first 3 parts)
	prefix := '${parts[0]}:${parts[1]}:${parts[2]}'
	return prefix
}

// Get the link-local IPv6 address of an interface
//
// Link-local addresses are used for routing within the same network segment
// They start with fe80::
fn (mut self HeroPods) mycelium_get_link_local_address(interface_name string) !string {
	self.logger.log(
		cat:     'mycelium'
		log:     'Getting link-local address for interface ${interface_name}'
		logtype: .stdout
	) or {}

	// Get IPv6 addresses for the interface
	cmd := "ip -6 addr show dev ${interface_name} | grep 'inet6 fe80' | awk '{print \$2}' | cut -d'/' -f1"
	result := osal.exec(
		cmd:    cmd
		stdout: false
	)!

	link_local := result.output.trim_space()
	if link_local == '' {
		return error('Failed to get link-local address for interface ${interface_name}')
	}

	self.logger.log(
		cat:     'mycelium'
		log:     'Link-local address for ${interface_name}: ${link_local}'
		logtype: .stdout
	) or {}

	return link_local
}

// Cleanup Mycelium networking for a container
//
// This method:
// 1. Removes the veth pair
// 2. Removes routes
//
// Thread Safety:
// This is called from container.stop() and container.delete() which are serialized per container.
fn (mut self HeroPods) mycelium_cleanup_container(container_name string) ! {
	if !self.mycelium_enabled {
		return
	}

	self.logger.log(
		cat:     'mycelium'
		log:     'Cleaning up Mycelium IPv6 for container ${container_name}'
		logtype: .stdout
	) or {}

	// Remove veth interfaces (they should be auto-removed when container stops, but cleanup anyway)
	short_hash := sha256.hexhash(container_name)[..6]
	veth_host := 'vmyh-${short_hash}'

	osal.exec(
		cmd:    'ip link delete ${veth_host} 2>/dev/null'
		stdout: false
	) or {}

	// Remove host route (if it exists)
	mycelium_prefix := self.mycelium_get_ipv6_prefix() or {
		self.logger.log(
			cat:     'mycelium'
			log:     'Warning: Could not get Mycelium prefix for cleanup: ${err}'
			logtype: .error
		) or {}
		return
	}

	osal.exec(
		cmd:    'ip route del ${mycelium_prefix}::1/128 2>/dev/null'
		stdout: false
	) or {}

	self.logger.log(
		cat:     'mycelium'
		log:     'Mycelium IPv6 cleanup complete for container ${container_name}'
		logtype: .stdout
	) or {}
}

// Inspect Mycelium status and return information
//
// Returns the public key and IPv6 address of the Mycelium node
pub fn (mut self HeroPods) mycelium_inspect() !mycelium.MyceliumInspectResult {
	if !self.mycelium_enabled {
		return error('Mycelium is not enabled')
	}

	return mycelium.inspect(key_file_path: self.mycelium_key_path)!
}
