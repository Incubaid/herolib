module heropods

import incubaid.herolib.osal.core as osal
import incubaid.herolib.virt.crun
import incubaid.herolib.installers.virt.herorunner as herorunner_installer
import os

// ContainerImageType defines the available container base images
pub enum ContainerImageType {
	alpine_3_20  // Alpine Linux 3.20
	ubuntu_24_04 // Ubuntu 24.04 LTS
	ubuntu_25_04 // Ubuntu 25.04
	custom       // Custom image downloaded via podman
}

// ContainerNewArgs defines parameters for creating a new container
@[params]
pub struct ContainerNewArgs {
pub:
	name              string @[required] // Unique container name
	image             ContainerImageType = .alpine_3_20 // Base image type
	custom_image_name string // Used when image = .custom
	docker_url        string // Docker image URL for new images
	reset             bool   // Reset if container already exists
}

// Create a new container
//
// This method:
// 1. Validates the container name
// 2. Determines the image to use (built-in or custom)
// 3. Creates crun configuration
// 4. Configures DNS in rootfs
//
// Note: The actual container creation in crun happens when start() is called.
// This method only prepares the configuration and rootfs.
//
// Thread Safety:
// This method doesn't interact with network_config, so no mutex is needed.
// Network setup happens later in container.start().
pub fn (mut self HeroPods) container_new(args ContainerNewArgs) !&Container {
	// Validate container name to prevent shell injection and path traversal
	validate_container_name(args.name) or { return error('Invalid container name: ${err}') }

	if args.name in self.containers && !args.reset {
		return self.containers[args.name] or { panic('bug: container should exist') }
	}

	// Determine image to use
	mut image_name := ''
	mut rootfs_path := ''

	match args.image {
		.alpine_3_20 {
			image_name = 'alpine'
			rootfs_path = '${self.base_dir}/images/alpine/rootfs'
		}
		.ubuntu_24_04 {
			image_name = 'ubuntu_24_04'
			rootfs_path = '${self.base_dir}/images/ubuntu/24.04/rootfs'
		}
		.ubuntu_25_04 {
			image_name = 'ubuntu_25_04'
			rootfs_path = '${self.base_dir}/images/ubuntu/25.04/rootfs'
		}
		.custom {
			if args.custom_image_name == '' {
				return error('custom_image_name is required when using custom image type')
			}
			image_name = args.custom_image_name
			rootfs_path = '${self.base_dir}/images/${image_name}/rootfs'

			// If image not yet extracted, pull and unpack it
			if !os.is_dir(rootfs_path) && args.docker_url != '' {
				self.logger.log(
					cat:     'images'
					log:     'Pulling image ${args.docker_url} with podman...'
					logtype: .stdout
				) or {}
				self.podman_pull_and_export(args.docker_url, image_name, rootfs_path)!
			}
		}
	}

	// Verify rootfs exists
	if !os.is_dir(rootfs_path) {
		return error('Image rootfs not found: ${rootfs_path}. Please ensure the image is available.')
	}

	// Create crun configuration using the crun module
	mut crun_config := self.create_crun_config(args.name, rootfs_path)!

	// Ensure crun is installed on host
	if !osal.cmd_exists('crun') {
		mut herorunner := herorunner_installer.new()!
		herorunner.install()!
	}

	// Create container struct but don't create the actual container in crun yet
	// The actual container creation will happen in container.start()
	mut container := &Container{
		name:        args.name
		crun_config: crun_config
		factory:     &self
	}

	self.containers[args.name] = container

	// Configure DNS in container rootfs (uses network_config but doesn't modify it)
	self.network_configure_dns(args.name, rootfs_path)!

	return container
}

// Create crun configuration for a container
//
// This creates an OCI-compliant runtime configuration with:
// - No terminal (background container)
// - Long-running sleep process
// - Standard environment variables
// - Resource limits
fn (mut self HeroPods) create_crun_config(container_name string, rootfs_path string) !&crun.CrunConfig {
	// Create crun configuration using the factory pattern
	mut config := crun.new(mut self.crun_configs, name: container_name)!

	// Configure for heropods use case - disable terminal for background containers
	config.set_terminal(false)
	config.set_command(['/bin/sh', '-c', 'while true; do sleep 30; done'])
	config.set_working_dir('/')
	config.set_user(0, 0, [])
	config.add_env('PATH', '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin')
	config.add_env('TERM', 'xterm')
	config.set_rootfs(rootfs_path, false)
	config.set_hostname('container')
	config.set_no_new_privileges(true)

	// Add resource limits
	config.add_rlimit(.rlimit_nofile, 1024, 1024)

	// Validate the configuration
	config.validate()!

	// Create config directory and save JSON
	config_dir := '${self.base_dir}/configs/${container_name}'
	osal.exec(cmd: 'mkdir -p ${config_dir}', stdout: false)!

	config_path := '${config_dir}/config.json'
	config.save_to_file(config_path)!

	return config
}

// Pull a Docker image using podman and extract its rootfs
//
// This method:
// 1. Pulls the image from Docker registry
// 2. Creates a temporary container from the image
// 3. Exports the container filesystem to rootfs_path
// 4. Cleans up the temporary container
fn (self HeroPods) podman_pull_and_export(docker_url string, image_name string, rootfs_path string) ! {
	// Pull image
	osal.exec(
		cmd:    'podman pull ${docker_url}'
		stdout: true
	)!

	// Create temp container
	temp_name := 'tmp_${image_name}_${os.getpid()}'
	osal.exec(
		cmd:    'podman create --name ${temp_name} ${docker_url}'
		stdout: true
	)!

	// Export container filesystem
	osal.exec(
		cmd:    'mkdir -p ${rootfs_path}'
		stdout: false
	)!
	osal.exec(
		cmd:    'podman export ${temp_name} | tar -C ${rootfs_path} -xf -'
		stdout: true
	)!

	// Cleanup temp container
	osal.exec(
		cmd:    'podman rm ${temp_name}'
		stdout: false
	)!
}
