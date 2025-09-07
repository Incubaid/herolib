module heropods

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.core as osal
import time
import os

@[heap]
pub struct ContainerFactory {
pub mut:
	tmux_session string
	containers   map[string]&Container
	images       map[string]&ContainerImage
}

@[params]
pub struct FactoryInitArgs {
pub:
	reset      bool
	use_podman bool = true
}

pub fn new(args FactoryInitArgs) !ContainerFactory {
	mut f := ContainerFactory{}
	f.init(args)!
	return f
}

fn (mut self ContainerFactory) init(args FactoryInitArgs) ! {
	// Ensure base directories exist
	osal.exec(
		cmd:    'mkdir -p /containers/images /containers/configs /containers/runtime'
		stdout: false
	)!

	if args.use_podman {
		if !osal.cmd_exists('podman') {
			console.print_stderr('Warning: podman not found. Install podman for better image management.')
			console.print_debug('Install with: apt install podman (Ubuntu) or brew install podman (macOS)')
		} else {
			console.print_debug('Using podman for image management')
		}
	}

	// Load existing images into cache
	self.load_existing_images()!

	// Setup default images if not using podman
	if !args.use_podman {
		self.setup_default_images(args.reset)!
	}
}

fn (mut self ContainerFactory) setup_default_images(reset bool) ! {
	console.print_header('Setting up default images...')

	default_images := [ContainerImageType.alpine_3_20, .ubuntu_24_04, .ubuntu_25_04]

	for img in default_images {
		mut args := ContainerImageArgs{
			image_name: img.str()
			reset:      reset
		}
		if img.str() !in self.images || reset {
			console.print_debug('Preparing default image: ${img.str()}')
			_ = self.image_new(args)!
		}
	}
}

// Load existing images from filesystem into cache
fn (mut self ContainerFactory) load_existing_images() ! {
	images_base_dir := '/containers/images'
	if !os.is_dir(images_base_dir) {
		return
	}

	dirs := os.ls(images_base_dir) or { return }
	for dir in dirs {
		full_path := '${images_base_dir}/${dir}'
		if os.is_dir(full_path) {
			rootfs_path := '${full_path}/rootfs'
			if os.is_dir(rootfs_path) {
				mut image := &ContainerImage{
					image_name:  dir
					rootfs_path: rootfs_path
					factory:     &self
				}
				image.update_metadata() or {
					console.print_stderr('⚠️ Failed to update metadata for image ${dir}: ${err}')
					continue
				}
				self.images[dir] = image
				console.print_debug('Loaded existing image: ${dir}')
			}
		}
	}
}

pub fn (mut self ContainerFactory) get(args ContainerNewArgs) !&Container {
	if args.name !in self.containers {
		return error('Container "${args.name}" does not exist. Use factory.new() to create it first.')
	}
	return self.containers[args.name]
}

// Get image by name
pub fn (mut self ContainerFactory) image_get(name string) !&ContainerImage {
	if name !in self.images {
		return error('Image "${name}" not found in cache. Try importing or downloading it.')
	}
	return self.images[name]
}

// List all containers currently managed by crun
pub fn (self ContainerFactory) list() ![]Container {
	mut containers := []Container{}
	result := osal.exec(cmd: 'crun list --format json', stdout: false)!

	// Parse crun list output (tab-separated)
	lines := result.output.split_into_lines()
	for line in lines {
		if line.trim_space() == '' || line.starts_with('ID') {
			continue
		}
		parts := line.split('\t')
		if parts.len > 0 {
			containers << Container{
				name:    parts[0]
				factory: &self
			}
		}
	}
	return containers
}
