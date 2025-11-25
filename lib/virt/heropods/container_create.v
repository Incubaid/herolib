module heropods

import incubaid.herolib.osal.core as osal
import incubaid.herolib.virt.crun
import incubaid.herolib.installers.virt.crun_installer
import os
import json

// Image metadata structures for podman inspect
// These structures map to the JSON output of `podman inspect <image>`
// All fields are optional since different images may have different configurations
struct ImageInspectResult {
	config ImageConfig @[json: 'Config']
}

struct ImageConfig {
pub mut:
	entrypoint  []string @[json: 'Entrypoint'; omitempty]
	cmd         []string @[json: 'Cmd'; omitempty]
	env         []string @[json: 'Env'; omitempty]
	working_dir string   @[json: 'WorkingDir'; omitempty]
}

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

// CrunConfigArgs defines parameters for creating crun configuration
@[params]
pub struct CrunConfigArgs {
pub:
	container_name string @[required] // Container name
	rootfs_path    string @[required] // Path to container rootfs
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
	mut crun_config := self.create_crun_config(
		container_name: args.name
		rootfs_path:    rootfs_path
	)!

	// Ensure crun is installed on host
	if !osal.cmd_exists('crun') {
		mut crun_inst := crun_installer.get()!
		crun_inst.install(reset: false)!
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
// This creates an OCI-compliant runtime configuration that respects the image's
// ENTRYPOINT and CMD according to the OCI standard:
// - If image metadata exists (from podman inspect), use ENTRYPOINT + CMD
// - Otherwise, use a default shell command
// - Apply environment variables and working directory from image metadata
// - No terminal (background container)
// - Standard resource limits
fn (mut self HeroPods) create_crun_config(args CrunConfigArgs) !&crun.CrunConfig {
	// Create crun configuration using the factory pattern
	mut config := crun.new(mut self.crun_configs, name: args.container_name)!

	// Configure for heropods use case - disable terminal for background containers
	config.set_terminal(false)
	config.set_user(0, 0, [])
	config.set_rootfs(args.rootfs_path, false)
	config.set_hostname('container')
	config.set_no_new_privileges(true)

	// Check if image metadata exists (from podman inspect)
	image_dir := os.dir(args.rootfs_path)
	metadata_path := '${image_dir}/image_metadata.json'

	if os.exists(metadata_path) {
		// Load and apply OCI image metadata
		self.logger.log(
			cat:     'container'
			log:     'Loading image metadata from ${metadata_path}'
			logtype: .stdout
		) or {}

		metadata_json := os.read_file(metadata_path)!
		image_config := json.decode(ImageConfig, metadata_json) or {
			return error('Failed to parse image metadata: ${err}')
		}

		// Build command according to OCI spec:
		// - If ENTRYPOINT exists: final_command = ENTRYPOINT + CMD
		// - Else if CMD exists: final_command = CMD
		// - Else: use default shell
		//
		// Note: We respect the image's original ENTRYPOINT and CMD without modification.
		// If keep_alive is needed, it will be injected after the entrypoint completes.
		mut final_command := []string{}

		if image_config.entrypoint.len > 0 {
			// ENTRYPOINT exists - combine with CMD
			final_command << image_config.entrypoint
			if image_config.cmd.len > 0 {
				final_command << image_config.cmd
			}
			self.logger.log(
				cat:     'container'
				log:     'Using ENTRYPOINT + CMD: ${final_command}'
				logtype: .stdout
			) or {}
		} else if image_config.cmd.len > 0 {
			// Only CMD exists
			final_command = image_config.cmd.clone()

			// Warn if CMD is a bare shell that will exit immediately
			if final_command.len == 1
				&& final_command[0] in ['/bin/sh', '/bin/bash', '/bin/ash', '/bin/dash'] {
				self.logger.log(
					cat:     'container'
					log:     'WARNING: CMD is a bare shell (${final_command[0]}) which will exit immediately when run non-interactively. Consider using keep_alive:true when starting this container.'
					logtype: .stdout
				) or {}
			}

			self.logger.log(
				cat:     'container'
				log:     'Using CMD: ${final_command}'
				logtype: .stdout
			) or {}
		} else {
			// No ENTRYPOINT or CMD - use default shell with keep-alive
			// Since there's no entrypoint to run, we start with keep-alive directly
			final_command = ['tail', '-f', '/dev/null']
			self.logger.log(
				cat:     'container'
				log:     'No ENTRYPOINT or CMD found, using keep-alive: ${final_command}'
				logtype: .stdout
			) or {}
		}

		config.set_command(final_command)

		// Apply environment variables from image
		for env_var in image_config.env {
			parts := env_var.split_nth('=', 2)
			if parts.len == 2 {
				config.add_env(parts[0], parts[1])
			}
		}

		// Apply working directory from image
		if image_config.working_dir != '' {
			config.set_working_dir(image_config.working_dir)
		} else {
			config.set_working_dir('/')
		}
	} else {
		// No metadata - use default configuration for built-in images
		self.logger.log(
			cat:     'container'
			log:     'No image metadata found, using default shell configuration'
			logtype: .stdout
		) or {}

		config.set_command(['/bin/sh'])
		config.set_working_dir('/')
		config.add_env('PATH', '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin')
		config.add_env('TERM', 'xterm')
	}

	// Add resource limits
	config.add_rlimit(.rlimit_nofile, 1024, 1024)

	// Validate the configuration
	config.validate()!

	// Create config directory and save JSON
	config_dir := '${self.base_dir}/configs/${args.container_name}'
	osal.exec(cmd: 'mkdir -p ${config_dir}', stdout: false)!

	config_path := '${config_dir}/config.json'
	config.save_to_file(config_path)!

	return config
}

// Pull a Docker image using podman and extract its rootfs and metadata
//
// This method:
// 1. Pulls the image from Docker registry
// 2. Extracts image metadata (ENTRYPOINT, CMD, ENV, WorkingDir) via podman inspect
// 3. Saves metadata to image_metadata.json for later use
// 4. Creates a temporary container from the image
// 5. Exports the container filesystem to rootfs_path
// 6. Cleans up the temporary container
fn (mut self HeroPods) podman_pull_and_export(docker_url string, image_name string, rootfs_path string) ! {
	// Pull image
	osal.exec(
		cmd:    'podman pull ${docker_url}'
		stdout: true
	)!

	// Extract image metadata (ENTRYPOINT, CMD, ENV, WorkingDir)
	// This is critical for OCI-compliant behavior - we need to respect the image's configuration
	image_dir := os.dir(rootfs_path)
	metadata_path := '${image_dir}/image_metadata.json'

	self.logger.log(
		cat:     'images'
		log:     'Extracting image metadata from ${docker_url}...'
		logtype: .stdout
	) or {}

	inspect_result := osal.exec(
		cmd:    'podman inspect ${docker_url}'
		stdout: false
	)!

	// Parse the inspect output (it's a JSON array with one element)
	inspect_data := json.decode([]ImageInspectResult, inspect_result.output) or {
		return error('Failed to parse podman inspect output: ${err}')
	}

	if inspect_data.len == 0 {
		return error('podman inspect returned empty result for ${docker_url}')
	}

	// Create image directory if it doesn't exist
	osal.exec(cmd: 'mkdir -p ${image_dir}', stdout: false)!

	// Save the metadata for later use in create_crun_config
	os.write_file(metadata_path, json.encode(inspect_data[0].config))!

	self.logger.log(
		cat:     'images'
		log:     'Saved image metadata to ${metadata_path}'
		logtype: .stdout
	) or {}

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

	self.logger.log(
		cat:     'images'
		log:     'Exporting container filesystem to ${rootfs_path}...'
		logtype: .stdout
	) or {}

	osal.exec(
		cmd:    'podman export ${temp_name} | tar -C ${rootfs_path} -xf -'
		stdout: false
	)!

	self.logger.log(
		cat:     'images'
		log:     'Container filesystem exported successfully'
		logtype: .stdout
	) or {}

	// Cleanup temp container
	osal.exec(
		cmd:    'podman rm ${temp_name}'
		stdout: false
	)!
}
