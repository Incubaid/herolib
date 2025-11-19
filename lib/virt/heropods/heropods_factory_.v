module heropods

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import json

// Global state for HeroPods instances
//
// Thread Safety Note:
// heropods_global is not marked as `shared` because it would break compile-time
// reflection in paramsparser. The map operations are generally safe for concurrent
// read access. For write operations, the Redis backend provides the source of truth
// and synchronization. Each HeroPods instance has its own network_mutex for
// protecting network operations.
__global (
	heropods_global  map[string]&HeroPods
	heropods_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name       string = 'default' // name of the heropods
	fromdb     bool // will load from filesystem
	create     bool // default will not create if not exist
	reset      bool // will reset the heropods
	use_podman bool = true // will use podman for image management
	// Network configuration
	bridge_name string   = 'heropods0'
	subnet      string   = '10.10.0.0/24'
	gateway_ip  string   = '10.10.0.1'
	dns_servers []string = ['8.8.8.8', '8.8.4.4']
	// Mycelium IPv6 overlay network configuration
	enable_mycelium     bool     // Enable Mycelium IPv6 overlay network
	mycelium_version    string   // Mycelium version to install (default: 'v0.5.6')
	mycelium_ipv6_range string   // Mycelium IPv6 address range (default: '400::/7')
	mycelium_peers      []string // Mycelium peer addresses (default: use public nodes)
	mycelium_key_path   string = '~/hero/cfg/priv_key.bin' // Path to Mycelium private key
}

pub fn new(args ArgsGet) !&HeroPods {
	mut obj := HeroPods{
		name:                args.name
		reset:               args.reset
		use_podman:          args.use_podman
		network_config:      NetworkConfig{
			bridge_name: args.bridge_name
			subnet:      args.subnet
			gateway_ip:  args.gateway_ip
			dns_servers: args.dns_servers
		}
		mycelium_enabled:    args.enable_mycelium
		mycelium_version:    args.mycelium_version
		mycelium_ipv6_range: args.mycelium_ipv6_range
		mycelium_peers:      args.mycelium_peers
		mycelium_key_path:   args.mycelium_key_path
	}
	set(obj)!
	return get(name: args.name)!
}

// Get a HeroPods instance by name
// If fromdb is true, loads from Redis; otherwise returns from memory cache
pub fn get(args ArgsGet) !&HeroPods {
	mut context := base.context()!
	heropods_default = args.name

	if args.fromdb || args.name !in heropods_global {
		mut r := context.redis()!
		if r.hexists('context:heropods', args.name)! {
			data := r.hget('context:heropods', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('HeroPods with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(HeroPods, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("HeroPods with name '${args.name}' does not exist")
			}
		}
		return get(args)! // Recursive call with fromdb=false
	}

	return heropods_global[args.name] or {
		print_backtrace()
		return error('could not get config for heropods with name:${args.name}')
	}
}

// Register a HeroPods instance (saves to both memory and Redis)
pub fn set(o HeroPods) ! {
	mut o2 := set_in_mem(o)!
	heropods_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:heropods', o2.name, json.encode(o2))!
}

// Check if a HeroPods instance exists in Redis
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:heropods', args.name)!
}

// Delete a HeroPods instance from Redis (does not affect memory cache)
pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:heropods', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// List all HeroPods instances
// If fromdb is true, loads from Redis and resets memory cache
// If fromdb is false, returns from memory cache
pub fn list(args ArgsList) ![]&HeroPods {
	mut res := []&HeroPods{}
	mut context := base.context()!

	if args.fromdb {
		// Reset memory cache and load from Redis
		heropods_global = map[string]&HeroPods{}
		heropods_default = ''

		mut r := context.redis()!
		mut l := r.hkeys('context:heropods')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
	} else {
		// Load from memory cache
		for _, client in heropods_global {
			res << client
		}
	}

	return res
}

// Set a HeroPods instance in memory cache only (does not persist to Redis)
// Performs lightweight validation via obj_init, then heavy initialization
fn set_in_mem(o HeroPods) !HeroPods {
	mut o2 := obj_init(o)!
	o2.initialize()! // Perform heavy initialization after validation
	heropods_global[o2.name] = &o2
	heropods_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'heropods.') {
		return
	}

	// Process heropods.configure actions
	for mut action in plbook.find(filter: 'heropods.configure')! {
		heroscript := action.heroscript()
		mut obj := heroscript_loads(heroscript)!
		set(obj)!
		action.done = true
	}

	// Process heropods.enable_mycelium actions
	for mut action in plbook.find(filter: 'heropods.enable_mycelium')! {
		mut p := action.params
		heropods_name := p.get_default('heropods', heropods_default)!
		mut hp := get(name: heropods_name)!

		// Validate required parameters
		mycelium_version := p.get('version') or {
			return error('heropods.enable_mycelium: "version" is required (e.g., version:\'v0.5.6\')')
		}
		mycelium_ipv6_range := p.get('ipv6_range') or {
			return error('heropods.enable_mycelium: "ipv6_range" is required (e.g., ipv6_range:\'400::/7\')')
		}
		mycelium_key_path := p.get('key_path') or {
			return error('heropods.enable_mycelium: "key_path" is required (e.g., key_path:\'~/hero/cfg/priv_key.bin\')')
		}
		mycelium_peers_str := p.get('peers') or {
			return error('heropods.enable_mycelium: "peers" is required. Provide comma-separated list of peer addresses (e.g., peers:\'tcp://185.69.166.8:9651,quic://[2a02:1802:5e:0:ec4:7aff:fe51:e36b]:9651\')')
		}

		// Parse and validate peers list
		peers_array := mycelium_peers_str.split(',').map(it.trim_space()).filter(it.len > 0)
		if peers_array.len == 0 {
			return error('heropods.enable_mycelium: "peers" cannot be empty. Provide at least one peer address.')
		}

		// Update Mycelium configuration
		hp.mycelium_enabled = true
		hp.mycelium_version = mycelium_version
		hp.mycelium_ipv6_range = mycelium_ipv6_range
		hp.mycelium_key_path = mycelium_key_path
		hp.mycelium_peers = peers_array

		// Initialize Mycelium if not already done
		hp.mycelium_init()!

		// Save updated configuration
		set(hp)!

		action.done = true
	}

	// Process heropods.container_new actions
	for mut action in plbook.find(filter: 'heropods.container_new')! {
		mut p := action.params
		heropods_name := p.get_default('heropods', heropods_default)!
		mut hp := get(name: heropods_name)!

		container_name := p.get('name')!
		image_str := p.get_default('image', 'alpine_3_20')!
		custom_image_name := p.get_default('custom_image_name', '')!
		docker_url := p.get_default('docker_url', '')!
		reset := p.get_default_false('reset')

		image_type := match image_str {
			'alpine_3_20' { ContainerImageType.alpine_3_20 }
			'ubuntu_24_04' { ContainerImageType.ubuntu_24_04 }
			'ubuntu_25_04' { ContainerImageType.ubuntu_25_04 }
			'custom' { ContainerImageType.custom }
			else { ContainerImageType.alpine_3_20 }
		}

		hp.container_new(
			name:              container_name
			image:             image_type
			custom_image_name: custom_image_name
			docker_url:        docker_url
			reset:             reset
		)!

		action.done = true
	}

	// Process heropods.container_start actions
	for mut action in plbook.find(filter: 'heropods.container_start')! {
		mut p := action.params
		heropods_name := p.get_default('heropods', heropods_default)!
		mut hp := get(name: heropods_name)!

		container_name := p.get('name')!
		mut container := hp.get(name: container_name)!
		container.start()!

		action.done = true
	}

	// Process heropods.container_exec actions
	for mut action in plbook.find(filter: 'heropods.container_exec')! {
		mut p := action.params
		heropods_name := p.get_default('heropods', heropods_default)!
		mut hp := get(name: heropods_name)!

		container_name := p.get('name')!
		cmd := p.get('cmd')!
		stdout := p.get_default_true('stdout')

		mut container := hp.get(name: container_name)!
		result := container.exec(cmd: cmd, stdout: stdout)!

		if stdout {
			println(result)
		}

		action.done = true
	}

	// Process heropods.container_stop actions
	for mut action in plbook.find(filter: 'heropods.container_stop')! {
		mut p := action.params
		heropods_name := p.get_default('heropods', heropods_default)!
		mut hp := get(name: heropods_name)!

		container_name := p.get('name')!
		mut container := hp.get(name: container_name)!
		container.stop()!

		action.done = true
	}

	// Process heropods.container_delete actions
	for mut action in plbook.find(filter: 'heropods.container_delete')! {
		mut p := action.params
		heropods_name := p.get_default('heropods', heropods_default)!
		mut hp := get(name: heropods_name)!

		container_name := p.get('name')!
		mut container := hp.get(name: container_name)!
		container.delete()!

		action.done = true
	}
}

// Switch the default HeroPods instance
//
// Thread Safety Note:
// String assignment is atomic on most platforms, so no explicit locking is needed.
// If strict thread safety is required in the future, this could be wrapped in a lock.
pub fn switch(name string) {
	heropods_default = name
}
