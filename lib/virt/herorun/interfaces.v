module herorun

// Base image types for containers
pub enum BaseImage {
	alpine        // Standard Alpine Linux minirootfs
	alpine_python // Alpine Linux with Python 3 pre-installed
}

// Shared parameter structs used across the module
@[params]
pub struct SendCommandArgs {
pub:
	cmd string @[required]
}

@[params]
pub struct NewContainerArgs {
pub:
	name         string @[required]
	image_script string // Optional path to entry point script (e.g., './images/python_server.sh')
	base_image   BaseImage = .alpine // Base image type (default: alpine)
}

@[params]
pub struct ContainerCommandArgs {
pub:
	cmd string @[required]
}

// NodeBackend defines the contract that all node providers must follow
pub interface NodeBackend {
mut:
	// Connect to the node and ensure required packages
	connect(args NodeConnectArgs) !

	// Send command to the node
	send_command(args SendCommandArgs) !

	// Container lifecycle
	get_or_create_container(args NewContainerArgs) !Container

	// Get node information
	get_info() !NodeInfo
}

// ContainerBackend defines container operations
pub interface ContainerBackend {
mut:
	// Attach to container tmux session
	attach() !

	// Send command to container
	send_command(args ContainerCommandArgs) !

	// Get container logs
	get_logs() !string
}
