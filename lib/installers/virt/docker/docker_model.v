module docker

import incubaid.herolib.data.encoderhero

pub const version = '1.14.3'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct DockerInstaller {
pub mut:
	name string = 'default'
}

fn obj_init(obj_ DockerInstaller) !DockerInstaller {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj DockerInstaller) !string {
	return encoderhero.encode[DockerInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !DockerInstaller {
	mut obj := encoderhero.decode[DockerInstaller](heroscript)!
	return obj
}
