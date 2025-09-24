module python

import freeflowuniverse.herolib.data.encoderhero

pub const version = '0.8.11'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct PythonInstaller {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ PythonInstaller) !PythonInstaller {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj PythonInstaller) !string {
	return encoderhero.encode[PythonInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !PythonInstaller {
	mut obj := encoderhero.decode[PythonInstaller](heroscript)!
	return obj
}
