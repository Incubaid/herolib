module zola

import incubaid.herolib.data.encoderhero

const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

pub struct ZolaInstaller {
pub mut:
	name string = 'default'
}

fn obj_init(obj_ ZolaInstaller) !ZolaInstaller {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj ZolaInstaller) !string {
	return encoderhero.encode[ZolaInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !ZolaInstaller {
	mut obj := encoderhero.decode[ZolaInstaller](heroscript)!
	return obj
}
