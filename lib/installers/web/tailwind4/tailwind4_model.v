module tailwind4

import freeflowuniverse.herolib.data.encoderhero

pub const version = '4.0.8'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct Tailwind {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ Tailwind) !Tailwind {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj Tailwind) !string {
	return encoderhero.encode[Tailwind](obj)!
}

pub fn heroscript_loads(heroscript string) !Tailwind {
	mut obj := encoderhero.decode[Tailwind](heroscript)!
	return obj
}
