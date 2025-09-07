module heropods

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.installers.virt.herorunner as herorunner_installer
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

			// Check if image exists, if not and docker_url provided, create it
			if !os.is_dir(rootfs_path) && args.docker_url != '' {
				console.print_debug('Creating new image ${image_name} from ${args.docker_url}')
				_ = self.image_new(
					image_name: image_name
					docker_url: args.docker_url
					reset:      args.reset
				)!
			}
		}
	}

	// Verify rootfs exists
	if !os.is_dir(rootfs_path) {
		return error('Image rootfs not found: ${rootfs_path}. Please ensure the image is available.')
	}

	// Create container config
	self.create_container_config(args.name, rootfs_path)!

	// Install crun if not installed
	if !osal.cmd_exists('crun') {
		mut herorunner := herorunner_installer.new()!
		herorunner.install()!
	}

	// Create container using crun
	osal.exec(
		cmd:    'crun create --bundle ${self.base_dir}/configs/${args.name} ${args.name}'
		stdout: true
	)!

	mut container := &Container{
		name:    args.name
		factory: &self
	}

	self.containers[args.name] = container
	return container
}

fn (self ContainerFactory) create_container_config(container_name string, rootfs_path string) ! {
	config_dir := '${self.base_dir}/configs/${container_name}'
	osal.exec(cmd: 'mkdir -p ${config_dir}', stdout: false)!

	// Generate OCI config.json using template
	config_content := $tmpl('config_template.json')
	config_path := '${config_dir}/config.json'

	mut p := pathlib.get_file(path: config_path, create: true)!
	p.write(config_content)!
}
