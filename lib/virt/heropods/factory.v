module heropods

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.tmux
import freeflowuniverse.herolib.osal.core as osal
import time
import freeflowuniverse.herolib.builder
import freeflowuniverse.herolib.core.pathlib
import os

pub struct ContainerFactory {
pub mut:
	tmux_session string // tmux session name if used
	containers   map[string]&Container
	images       map[string]&ContainerImage // Added images map
}

@[params]
pub struct FactoryInitArgs {
pub:
	reset bool
	use_podman bool = true // Use podman for image management
}

pub fn new(args FactoryInitArgs) !ContainerFactory {
	mut f := ContainerFactory{}
	f.init(args)!
	return f
}

fn (mut self ContainerFactory) init(args FactoryInitArgs) ! {
	// Ensure base directories exist
	osal.exec(cmd: 'mkdir -p /containers/images /containers/configs /containers/runtime', stdout: false)!
	
	if args.use_podman {
		// Check if podman is installed
		if !osal.cmd_exists('podman') {
			console.print_stderr('Warning: podman not found. Installing podman is recommended for better image management.')
			console.print_debug('You can install podman with: apt install podman (Ubuntu) or brew install podman (macOS)')
		} else {
			console.print_debug('Using podman for image management')
		}
	}
	
	// Load existing images into cache
	self.load_existing_images()!
	
	// Setup default images if they don't exist
	if !args.use_podman {
		self.setup_default_images_legacy(args.reset)!
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
					image_name: dir
					rootfs_path: rootfs_path
					factory: &self
				}
				image.update_metadata() or {
					console.print_stderr('Failed to load image metadata for ${dir}')
					continue
				}
				self.images[dir] = image
				console.print_debug('Loaded existing image: ${dir}')
			}
		}
	}
}

// Legacy method for downloading images directly (fallback if no podman)
fn (mut self ContainerFactory) setup_default_images_legacy(reset bool) ! {
	// Setup for all supported images
	images := [ContainerImage.alpine_3_20, .ubuntu_24_04, .ubuntu_25_04]

	for image in images {
		match image {
			.alpine_3_20 {
				alpine_ver := '3.20.3'
				alpine_file := 'alpine-minirootfs-${alpine_ver}-x86_64.tar.gz'
				alpine_url := 'https://dl-cdn.alpinelinux.org/alpine/v${alpine_ver[..4]}/releases/x86_64/${alpine_file}'
				alpine_dest := '/containers/images/alpine/${alpine_file}'
				alpine_rootfs := '/containers/images/alpine/rootfs'
				
				if reset || !os.exists(alpine_rootfs) {
					osal.download(
						url: alpine_url
						dest: alpine_dest
						minsize_kb: 1024
					)!
					
					// Extract alpine rootfs
					osal.exec(cmd: 'mkdir -p ${alpine_rootfs}', stdout: false)!
					osal.exec(cmd: 'tar -xzf ${alpine_dest} -C ${alpine_rootfs}', stdout: false)!
				}
				console.print_green('Alpine ${alpine_ver} rootfs prepared at ${alpine_rootfs}')
			}
			.ubuntu_24_04 {
				ver := '24.04'
				codename := 'noble'
				file := 'ubuntu-${ver}-minimal-cloudimg-amd64-root.tar.xz'
				url := 'https://cloud-images.ubuntu.com/minimal/releases/${codename}/release/${file}'
				dest := '/containers/images/ubuntu/${ver}/${file}'
				rootfs := '/containers/images/ubuntu/${ver}/rootfs'

				if reset || !os.exists(rootfs) {
					osal.download(
						url: url
						dest: dest
						minsize_kb: 10240
					)!
					
					// Extract ubuntu rootfs
					osal.exec(cmd: 'mkdir -p ${rootfs}', stdout: false)!
					osal.exec(cmd: 'tar -xf ${dest} -C ${rootfs}', stdout: false)!
				}
				console.print_green('Ubuntu ${ver} (${codename}) rootfs prepared at ${rootfs}')
			}
			.ubuntu_25_04 {
				ver := '25.04'
				codename := 'plucky'
				file := 'ubuntu-${ver}-minimal-cloudimg-amd64-root.tar.xz'
				url := 'https://cloud-images.ubuntu.com/daily/minimal/releases/${codename}/release/${file}'
				dest := '/containers/images/ubuntu/${ver}/${file}'
				rootfs := '/containers/images/ubuntu/${ver}/rootfs'

				if reset || !os.exists(rootfs) {
					osal.download(
						url: url
						dest: dest
						minsize_kb: 10240
					)!
					
					// Extract ubuntu rootfs
					osal.exec(cmd: 'mkdir -p ${rootfs}', stdout: false)!
					osal.exec(cmd: 'tar -xf ${dest} -C ${rootfs}', stdout: false)!
				}
				console.print_green('Ubuntu ${ver} (${codename}) rootfs prepared at ${rootfs}')
			}
		}
	}
}

pub fn (mut self ContainerFactory) get(args ContainerNewArgs) !&Container {
	if args.name !in self.containers {
		return error('Container ${args.name} does not exist')
	}
	return self.containers[args.name]
}

// Get image by name
pub fn (mut self ContainerFactory) image_get(name string) !&ContainerImage {
	if name !in self.images {
		return error('Image ${name} does not exist')
	}
	return self.images[name]
}

pub fn (self ContainerFactory) list() ![]Container {
	mut containers := []Container{}
	result := osal.exec(cmd: 'crun list --format json', stdout: false) or { '[]' }
	
	// Parse crun list output and populate containers
	// The output format from crun list is typically tab-separated
	lines := result.split_into_lines()
	for line in lines {
		if line.trim_space() == '' || line.starts_with('ID') {
			continue
		}
		parts := line.split('\t')
		if parts.len > 0 {
			containers << Container{
				name: parts[0]
				factory: &self
			}
		}
	}
	return containers
}