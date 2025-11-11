module heropods

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import json

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
}

pub fn new(args ArgsGet) !&HeroPods {
	mut obj := HeroPods{
		name:       args.name
		reset:      args.reset
		use_podman: args.use_podman
	}
	set(obj)!
	return get(name: args.name)!
}

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
		return get(args)! // no longer from db nor create
	}
	return heropods_global[args.name] or {
		print_backtrace()
		return error('could not get config for heropods with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o HeroPods) ! {
	mut o2 := set_in_mem(o)!
	heropods_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:heropods', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:heropods', args.name)!
}

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

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&HeroPods {
	mut res := []&HeroPods{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		heropods_global = map[string]&HeroPods{}
		heropods_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:heropods')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in heropods_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o HeroPods) !HeroPods {
	mut o2 := obj_init(o)!
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

// switch instance to be used for heropods
pub fn switch(name string) {
	heropods_default = name
}
