module b2

import incubaid.herolib.data.encoderhero

pub const version = '4.3.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct BackBase {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ BackBase) !BackBase {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj BackBase) !string {
	return encoderhero.encode[BackBase](obj)!
}

pub fn heroscript_loads(heroscript string) !BackBase {
	mut obj := encoderhero.decode[BackBase](heroscript)!
	return obj
}
