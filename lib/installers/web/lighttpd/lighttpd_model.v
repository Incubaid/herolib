module lighttpd

import incubaid.herolib.data.encoderhero

pub const version = '0.0.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct LightHttpdInstaller {
pub mut:
	name string = 'default'
}

fn obj_init(obj_ LightHttpdInstaller) !LightHttpdInstaller {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	panic('implement')
	return obj
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj LightHttpdInstaller) !string {
	return encoderhero.encode[LightHttpdInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !LightHttpdInstaller {
	mut obj := encoderhero.decode[LightHttpdInstaller](heroscript)!
	return obj
}
