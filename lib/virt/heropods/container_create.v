module heropods

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.installers.virt.herorunner as herorunner_installer
import os
import x.json2

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

pub fn (mut self ContainerFactory) new(args ContainerNewArgs) !&Container {
	if args.name in self.containers && !args.reset {
		return self.containers[args.name]
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

	// Create container config (with terminal disabled) but don't create the container yet
	self.create_container_config(args.name, rootfs_path)!

	// Ensure crun is installed on host
	if !osal.cmd_exists('crun') {
		mut herorunner := herorunner_installer.new()!
		herorunner.install()!
	}

	// Create container struct but don't create the actual container in crun yet
	// The actual container creation will happen in container.start()
	mut container := &Container{
		name:    args.name
		factory: &self
	}

	self.containers[args.name] = container
	return container
}

// Create OCI config.json from template
fn (self ContainerFactory) create_container_config(container_name string, rootfs_path string) ! {
	config_dir := '${self.base_dir}/configs/${container_name}'
	osal.exec(cmd: 'mkdir -p ${config_dir}', stdout: false)!

	// Load template
	mut config_content := $tmpl('config_template.json')

	// Parse JSON with json2
	mut root := json2.raw_decode(config_content)!
	mut config := root.as_map()

	// Get or create process map
	mut process := if 'process' in config {
		config['process'].as_map()
	} else {
		map[string]json2.Any{}
	}

	// Force disable terminal
	process['terminal'] = json2.Any(false)
	config['process'] = json2.Any(process)

	// Write back to config.json
	config_path := '${config_dir}/config.json'
	mut p := pathlib.get_file(path: config_path, create: true)!
	p.write(json2.encode_pretty(json2.Any(config)))!
}

// Use podman to pull image and extract rootfs
fn (self ContainerFactory) podman_pull_and_export(docker_url string, image_name string, rootfs_path string) ! {
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
