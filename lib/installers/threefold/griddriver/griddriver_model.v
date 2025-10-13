module griddriver

import incubaid.herolib.data.encoderhero

pub const version = '0.1.2'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct GridDriverInstaller {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ GridDriverInstaller) !GridDriverInstaller {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj GridDriverInstaller) !string {
	return encoderhero.encode[GridDriverInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !GridDriverInstaller {
	mut obj := encoderhero.decode[GridDriverInstaller](heroscript)!
	return obj
}
