module heropods

import incubaid.herolib.data.encoderhero
import incubaid.herolib.osal.core as osal
import incubaid.herolib.virt.crun
import incubaid.herolib.core.logger
import incubaid.herolib.core
import os
import sync

pub const version = '0.0.0'
const singleton = false
const default = true

// MyceliumConfig holds Mycelium IPv6 overlay network configuration (flattened into HeroPods struct)
// Note: These fields are flattened to avoid nested struct serialization issues with encoderhero

// HeroPods factory for managing containers
//
// Thread Safety:
// The network_config field is protected by network_mutex for thread-safe concurrent access.
// We use a separate mutex instead of marking network_config as `shared` because V's
// compile-time reflection (used by paramsparser) cannot handle shared fields.
@[heap]
pub struct HeroPods {
pub mut:
	tmux_session   string                      // tmux session name
	containers     map[string]&Container       // name -> container mapping
	images         map[string]&ContainerImage  // name -> image mapping
	crun_configs   map[string]&crun.CrunConfig // name -> crun config mapping
	base_dir       string                      // base directory for all container data
	reset          bool                        // will reset the heropods
	use_podman     bool = true // will use podman for image management
	name           string // name of the heropods
	network_config NetworkConfig @[skip; str: skip] // network configuration (automatically initialized, not serialized)
	network_mutex  sync.Mutex    @[skip; str: skip] // protects network_config for thread-safe concurrent access
	// Mycelium IPv6 overlay network configuration (flattened fields)
	mycelium_enabled        bool     // Whether Mycelium is enabled
	mycelium_version        string   // Mycelium version to install (e.g., 'v0.5.6')
	mycelium_ipv6_range     string   // Mycelium IPv6 address range (e.g., '400::/7')
	mycelium_peers          []string // Mycelium peer addresses
	mycelium_key_path       string   // Path to Mycelium private key
	mycelium_ip6            string   // Host's Mycelium IPv6 address (cached)
	mycelium_interface_name string   // Mycelium TUN interface name (e.g., "mycelium0")
	logger                  logger.Logger @[skip; str: skip] // logger instance for debugging (not serialized)
}

// obj_init performs lightweight validation and field normalization only
// Heavy initialization is done in the initialize() method
fn obj_init(mycfg_ HeroPods) !HeroPods {
	mut mycfg := mycfg_

	// Normalize base_dir from environment variable if not set
	if mycfg.base_dir == '' {
		mycfg.base_dir = os.getenv_opt('CONTAINERS_DIR') or { os.home_dir() + '/.containers' }
	}

	// Validate: warn if podman is requested but not available
	if mycfg.use_podman && !osal.cmd_exists('podman') {
		eprintln('Warning: podman not found. Install podman for better image management.')
		eprintln('Install with: apt install podman (Ubuntu) or brew install podman (macOS)')
	}

	// Preserve network_config from input, set defaults only if empty
	if mycfg.network_config.bridge_name == '' {
		mycfg.network_config.bridge_name = 'heropods0'
	}
	if mycfg.network_config.subnet == '' {
		mycfg.network_config.subnet = '10.10.0.0/24'
	}
	if mycfg.network_config.gateway_ip == '' {
		mycfg.network_config.gateway_ip = '10.10.0.1'
	}
	if mycfg.network_config.dns_servers.len == 0 {
		mycfg.network_config.dns_servers = ['8.8.8.8', '8.8.4.4']
	}

	// Ensure allocated_ips map is initialized
	if mycfg.network_config.allocated_ips.len == 0 {
		mycfg.network_config.allocated_ips = map[string]string{}
	}

	// Initialize Mycelium configuration defaults (only for non-required fields)
	if mycfg.mycelium_interface_name == '' {
		mycfg.mycelium_interface_name = 'mycelium0'
	}

	return mycfg
}

// initialize performs heavy initialization operations
// This should be called after obj_init in the factory pattern
fn (mut self HeroPods) initialize() ! {
	// Check platform - HeroPods requires Linux
	if core.is_osx()! {
		return error('HeroPods requires Linux. It uses Linux-specific tools (ip, iptables, nsenter, crun) that are not available on macOS. Please run HeroPods on a Linux system or use Docker/Podman directly on macOS.')
	}

	// Create base directories
	osal.exec(
		cmd:    'mkdir -p ${self.base_dir}/images ${self.base_dir}/configs ${self.base_dir}/runtime'
		stdout: false
	)!

	// Initialize logger
	self.logger = logger.new(
		path:           '${self.base_dir}/logs'
		console_output: true
	) or {
		eprintln('Warning: Failed to create logger: ${err}')
		logger.Logger{} // Use empty logger as fallback
	}

	// Clean up any leftover crun state if reset is requested
	if self.reset {
		self.cleanup_crun_state()!
		self.network_cleanup_all(false)! // Keep bridge for reuse
	}

	// Initialize network layer
	self.network_init()!

	// Initialize Mycelium IPv6 overlay network if enabled
	if self.mycelium_enabled {
		self.mycelium_init()!
	}

	// Load existing images into cache
	self.load_existing_images()!

	// Setup default images if not using podman
	if !self.use_podman {
		self.setup_default_images(self.reset)!
	}
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !HeroPods {
	mut obj := encoderhero.decode[HeroPods](heroscript)!
	return obj
}

fn (mut self HeroPods) setup_default_images(reset bool) ! {
	self.logger.log(
		cat:     'images'
		log:     'Setting up default images...'
		logtype: .stdout
	) or {}

	default_images := [ContainerImageType.alpine_3_20, .ubuntu_24_04, .ubuntu_25_04]

	for img in default_images {
		mut args := ContainerImageArgs{
			image_name: img.str()
			reset:      reset
		}
		if img.str() !in self.images || reset {
			self.logger.log(
				cat:     'images'
				log:     'Preparing default image: ${img.str()}'
				logtype: .stdout
			) or {}
			self.image_new(args)!
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
					self.logger.log(
						cat:     'images'
						log:     'Failed to update metadata for image ${dir}: ${err}'
						logtype: .error
					) or {}
					continue
				}
				self.images[dir] = image
				self.logger.log(
					cat:     'images'
					log:     'Loaded existing image: ${dir}'
					logtype: .stdout
				) or {}
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
	self.logger.log(
		cat:     'cleanup'
		log:     'Cleaning up leftover crun state...'
		logtype: .stdout
	) or {}
	crun_root := '${self.base_dir}/runtime'

	// Stop and delete all containers in our custom root
	result := osal.exec(cmd: 'crun --root ${crun_root} list -q', stdout: false) or { return }

	for container_name in result.output.split_into_lines() {
		if container_name.trim_space() != '' {
			self.logger.log(
				cat:     'cleanup'
				log:     'Cleaning up container: ${container_name}'
				logtype: .stdout
			) or {}
			osal.exec(cmd: 'crun --root ${crun_root} kill ${container_name} SIGKILL', stdout: false) or {}
			osal.exec(cmd: 'crun --root ${crun_root} delete ${container_name}', stdout: false) or {}
		}
	}

	// Also clean up any containers in the default root that might be ours
	result2 := osal.exec(cmd: 'crun list -q', stdout: false) or { return }
	for container_name in result2.output.split_into_lines() {
		if container_name.trim_space() != '' && container_name in self.containers {
			self.logger.log(
				cat:     'cleanup'
				log:     'Cleaning up container from default root: ${container_name}'
				logtype: .stdout
			) or {}
			osal.exec(cmd: 'crun kill ${container_name} SIGKILL', stdout: false) or {}
			osal.exec(cmd: 'crun delete ${container_name}', stdout: false) or {}
		}
	}

	// Clean up runtime directories
	osal.exec(cmd: 'rm -rf ${crun_root}/*', stdout: false) or {}
	osal.exec(cmd: 'find /run/crun -name "*" -type d -exec rm -rf {} + 2>/dev/null', stdout: false) or {}
}
