module heropods

import incubaid.herolib.ui.console
import incubaid.herolib.osal.core as osal
import incubaid.herolib.virt.crun
import incubaid.herolib.installers.virt.herorunner as herorunner_installer
import os

// Updated enum to be more flexible
pub enum ContainerImageType {
	alpine_3_20
	ubuntu_24_04
	ubuntu_25_04
	custom // For custom images downloaded via podman
}

@[params]
pub struct ContainerNewArgs {
pub:
	name              string @[required]
	image             ContainerImageType = .alpine_3_20
	custom_image_name string // Used when image = .custom
	docker_url        string // Docker image URL for new images
	reset             bool
}

pub fn (mut self HeroPods) container_new(args ContainerNewArgs) !&Container {
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
				console.print_debug('Pulling image ${args.docker_url} with podman...')
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

	// Always install hero binary in container rootfs
	self.install_hero_in_rootfs(rootfs_path)!

	return container
}

// Create crun configuration using the crun module
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

	// Add the specific rlimit for file descriptors
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

// Use podman to pull image and extract rootfs
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

// Install hero binary into container rootfs
// This copies the hero binary from the host into the container's rootfs
// If the hero binary doesn't exist on the host, it will be compiled first
fn (mut self HeroPods) install_hero_in_rootfs(rootfs_path string) ! {
	console.print_debug('Installing hero binary into container rootfs: ${rootfs_path}')

	// Check if hero binary already exists in rootfs
	hero_bin_path := '${rootfs_path}/usr/local/bin/hero'
	if os.exists(hero_bin_path) {
		console.print_debug('Hero binary already exists in rootfs, skipping installation')
		return
	}

	// Ensure /usr/local/bin exists in rootfs
	osal.dir_ensure('${rootfs_path}/usr/local/bin')!

	// Get the hero binary path using osal utility
	// This returns ~/hero/bin on all platforms
	hero_bin_dir := osal.bin_path()!
	host_hero_path := '${hero_bin_dir}/hero'

	// If hero binary doesn't exist on host, compile it
	if !os.exists(host_hero_path) {
		console.print_debug('Hero binary not found on host at ${host_hero_path}')
		console.print_debug('Compiling hero binary using compile script...')

		// Get herolib directory
		herolib_dir := os.join_path(os.home_dir(), 'code/github/incubaid/herolib')
		if !os.exists(herolib_dir) {
			return error('Herolib source not found at ${herolib_dir}. Cannot compile hero binary.')
		}

		// Run the compile script
		compile_script := '${herolib_dir}/cli/compile.vsh'
		if !os.exists(compile_script) {
			return error('Hero compile script not found at ${compile_script}')
		}

		osal.exec(
			cmd:    compile_script
			stdout: true
		)!

		// Verify compilation succeeded
		if !os.exists(host_hero_path) {
			return error('Hero compilation failed - binary not found at ${host_hero_path}')
		}
	}

	// Copy hero binary to container rootfs
	console.print_debug('Copying hero binary from ${host_hero_path} to ${hero_bin_path}')
	os.cp(host_hero_path, hero_bin_path)!

	// Make it executable
	os.chmod(hero_bin_path, 0o755)!

	console.print_debug('Hero binary successfully installed in container rootfs')
}
