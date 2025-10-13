module actrunner

import incubaid.herolib.data.encoderhero

pub const version = '0.2.11'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct ActRunner {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ ActRunner) !ActRunner {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj ActRunner) !string {
	return encoderhero.encode[ActRunner](obj)!
}

pub fn heroscript_loads(heroscript string) !ActRunner {
	mut obj := encoderhero.decode[ActRunner](heroscript)!
	return obj
}
