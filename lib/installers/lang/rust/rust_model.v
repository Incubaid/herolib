module rust

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import os

pub const version = '1.83.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct RustInstaller {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ RustInstaller) !RustInstaller {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj RustInstaller) !string {
	return encoderhero.encode[RustInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !RustInstaller {
	mut obj := encoderhero.decode[RustInstaller](heroscript)!
	return obj
}
