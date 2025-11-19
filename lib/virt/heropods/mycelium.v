module heropods

import incubaid.herolib.osal.core as osal
import incubaid.herolib.clients.mycelium
import incubaid.herolib.installers.net.mycelium_installer
import time
import crypto.sha256

// Initialize Mycelium for HeroPods
//
// This method:
// 1. Validates required configuration
// 2. Installs Mycelium binary if not present
// 3. Starts Mycelium service with configured peers
// 4. Retrieves the host's Mycelium IPv6 address
//
// Thread Safety:
// This is called during HeroPods initialization, before any concurrent operations.
fn (mut self HeroPods) mycelium_init() ! {
	if !self.mycelium_config.enabled {
		return
	}

	// Validate required configuration
	if self.mycelium_config.version == '' {
		return error('Mycelium configuration error: "version" is required. Use heropods.enable_mycelium to configure.')
	}
	if self.mycelium_config.ipv6_range == '' {
		return error('Mycelium configuration error: "ipv6_range" is required. Use heropods.enable_mycelium to configure.')
	}
	if self.mycelium_config.key_path == '' {
		return error('Mycelium configuration error: "key_path" is required. Use heropods.enable_mycelium to configure.')
	}
	if self.mycelium_config.peers.len == 0 {
		return error('Mycelium configuration error: "peers" is required. Use heropods.enable_mycelium to configure.')
	}

	self.logger.log(
		cat: 'mycelium'
		log: 'START mycelium_init() - Initializing Mycelium IPv6 overlay network'
	) or {}

	// Check if Mycelium is already installed and running
	if mycelium_installed := self.mycelium_check_installed() {
		if mycelium_installed {
			self.logger.log(
				cat:     'mycelium'
				log:     'Mycelium is already installed'
				logtype: .stdout
			) or {}
		} else {
			// Install Mycelium
			self.mycelium_install()!
		}
	}

	// Start Mycelium service if not running
	if mycelium_running := self.mycelium_check_running() {
		if mycelium_running {
			self.logger.log(
				cat:     'mycelium'
				log:     'Mycelium service is already running'
				logtype: .stdout
			) or {}
		} else {
			self.mycelium_start_service()!
		}
	}

	// Get and cache the host's Mycelium IPv6 address
	self.mycelium_get_host_address()!

	self.logger.log(
		cat:     'mycelium'
		log:     'END mycelium_init() - Mycelium initialized successfully with address ${self.mycelium_config.mycelium_ip6}'
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
	mycelium.inspect(key_file_path: self.mycelium_config.key_path) or { return false }
	return true
}

// Install Mycelium binary
fn (mut self HeroPods) mycelium_install() ! {
	self.logger.log(
		cat:     'mycelium'
		log:     'Installing Mycelium ${self.mycelium_config.version}...'
		logtype: .stdout
	) or {}

	// Use the mycelium_installer to install
	mut installer := mycelium_installer.get(create: true)!
	installer.peers = self.mycelium_config.peers

	// Install Mycelium using the instance method
	installer.install(reset: false)!

	self.logger.log(
		cat:     'mycelium'
		log:     'Mycelium installed successfully'
		logtype: .stdout
	) or {}
}

// Start Mycelium service
fn (mut self HeroPods) mycelium_start_service() ! {
	self.logger.log(
		cat:     'mycelium'
		log:     'Starting Mycelium service...'
		logtype: .stdout
	) or {}

	// Use the mycelium_installer to start the service
	mut installer := mycelium_installer.get()!
	installer.start()!

	// Wait for Mycelium to be ready
	for i in 0 .. 50 {
		if self.mycelium_check_running()! {
			self.logger.log(
				cat:     'mycelium'
				log:     'Mycelium service started successfully'
				logtype: .stdout
			) or {}
			return
		}
		if i % 10 == 0 {
			self.logger.log(
				cat:     'mycelium'
				log:     'Waiting for Mycelium service to start... (${i}/50)'
				logtype: .stdout
			) or {}
		}
		time.sleep(100 * time.millisecond)
	}

	return error('Mycelium service failed to start after 5 seconds')
}

// Get the host's Mycelium IPv6 address
fn (mut self HeroPods) mycelium_get_host_address() ! {
	self.logger.log(
		cat:     'mycelium'
		log:     'Retrieving host Mycelium IPv6 address...'
		logtype: .stdout
	) or {}

	// Use mycelium inspect to get the address
	inspect_result := mycelium.inspect(key_file_path: self.mycelium_config.key_path)!

	if inspect_result.address == '' {
		return error('Failed to get Mycelium IPv6 address from inspect')
	}

	self.mycelium_config.mycelium_ip6 = inspect_result.address

	self.logger.log(
		cat:     'mycelium'
		log:     'Host Mycelium IPv6 address: ${self.mycelium_config.mycelium_ip6}'
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
	if !self.mycelium_config.enabled {
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
	}

	// Get the link-local address of the host end of the veth pair
	veth_host_ll := self.mycelium_get_link_local_address(veth_host)!

	// Add route in container for Mycelium traffic (400::/7 via link-local)
	self.logger.log(
		cat:     'mycelium'
		log:     'Adding route for ${self.mycelium_config.ipv6_range} via ${veth_host_ll}'
		logtype: .stdout
	) or {}

	osal.exec(
		cmd:    'nsenter -t ${container_pid} -n ip route add ${self.mycelium_config.ipv6_range} via ${veth_host_ll} dev ${veth_container}'
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
	if self.mycelium_config.mycelium_ip6 == '' {
		return error('Mycelium IPv6 address not set')
	}

	// Split the address by ':' and take the first 3 parts for /64 prefix
	parts := self.mycelium_config.mycelium_ip6.split(':')
	if parts.len < 3 {
		return error('Invalid Mycelium IPv6 address format: ${self.mycelium_config.mycelium_ip6}')
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
	if !self.mycelium_config.enabled {
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
	if !self.mycelium_config.enabled {
		return error('Mycelium is not enabled')
	}

	return mycelium.inspect(key_file_path: self.mycelium_config.key_path)!
}
