module heropods

import incubaid.herolib.data.encoderhero
import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.virt.crun
import os

pub const version = '0.0.0'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

@[heap]
pub struct HeroPods {
pub mut:
	tmux_session string                      // tmux session name
	containers   map[string]&Container       // name -> container mapping
	images       map[string]&ContainerImage  // name -> image mapping
	crun_configs map[string]&crun.CrunConfig // name -> crun config mapping
	base_dir     string                      // base directory for all container data
	reset        bool                        // will reset the heropods
	use_podman   bool = true // will use podman for image management
	name         string // name of the heropods
}

// your checking & initialization code if needed
fn obj_init(mycfg_ HeroPods) !HeroPods {
	mut args := mycfg_

	// Ensure base directories exist
	args.base_dir = os.getenv_opt('CONTAINERS_DIR') or { os.home_dir() + '/.containers' }

	osal.exec(
		cmd:    'mkdir -p ${args.base_dir}/images ${args.base_dir}/configs ${args.base_dir}/runtime'
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

	mut heropods := HeroPods{
		tmux_session: args.name
		containers:   map[string]&Container{}
		images:       map[string]&ContainerImage{}
		crun_configs: map[string]&crun.CrunConfig{}
		base_dir:     args.base_dir
		reset:        args.reset
		use_podman:   args.use_podman
		name:         args.name
	}

	// Clean up any leftover crun state if reset is requested
	if args.reset {
		heropods.cleanup_crun_state()!
	}

	// Load existing images into cache
	heropods.load_existing_images()!

	// Setup default images if not using podman
	if !args.use_podman {
		heropods.setup_default_images(args.reset)!
	}

	return args
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !HeroPods {
	mut obj := encoderhero.decode[HeroPods](heroscript)!
	return obj
}

fn (mut self HeroPods) setup_default_images(reset bool) ! {
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
fn (mut self HeroPods) load_existing_images() ! {
	images_base_dir := '${self.base_dir}/containers/images'
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

pub fn (mut self HeroPods) get(args ContainerNewArgs) !&Container {
	if args.name !in self.containers {
		return error('Container "${args.name}" does not exist. Use factory.new() to create it first.')
	}
	return self.containers[args.name] or { panic('bug: container should exist') }
}

// Get image by name
pub fn (mut self HeroPods) image_get(name string) !&ContainerImage {
	if name !in self.images {
		return error('Image "${name}" not found in cache. Try importing or downloading it.')
	}
	return self.images[name] or { panic('bug: image should exist') }
}

// List all containers currently managed by crun
pub fn (self HeroPods) list() ![]Container {
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

// Clean up any leftover crun state
fn (mut self HeroPods) cleanup_crun_state() ! {
	console.print_debug('Cleaning up leftover crun state...')
	crun_root := '${self.base_dir}/runtime'

	// Stop and delete all containers in our custom root
	result := osal.exec(cmd: 'crun --root ${crun_root} list -q', stdout: false) or { return }

	for container_name in result.output.split_into_lines() {
		if container_name.trim_space() != '' {
			console.print_debug('Cleaning up container: ${container_name}')
			osal.exec(cmd: 'crun --root ${crun_root} kill ${container_name} SIGKILL', stdout: false) or {}
			osal.exec(cmd: 'crun --root ${crun_root} delete ${container_name}', stdout: false) or {}
		}
	}

	// Also clean up any containers in the default root that might be ours
	result2 := osal.exec(cmd: 'crun list -q', stdout: false) or { return }
	for container_name in result2.output.split_into_lines() {
		if container_name.trim_space() != '' && container_name in self.containers {
			console.print_debug('Cleaning up container from default root: ${container_name}')
			osal.exec(cmd: 'crun kill ${container_name} SIGKILL', stdout: false) or {}
			osal.exec(cmd: 'crun delete ${container_name}', stdout: false) or {}
		}
	}

	// Clean up runtime directories
	osal.exec(cmd: 'rm -rf ${crun_root}/*', stdout: false) or {}
	osal.exec(cmd: 'find /run/crun -name "*" -type d -exec rm -rf {} + 2>/dev/null', stdout: false) or {}
}
