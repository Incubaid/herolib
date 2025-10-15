module pacman

import incubaid.herolib.data.encoderhero

pub const version = 'v1.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct PacmanInstaller {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ PacmanInstaller) !PacmanInstaller {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj PacmanInstaller) !string {
	return encoderhero.encode[PacmanInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !PacmanInstaller {
	mut obj := encoderhero.decode[PacmanInstaller](heroscript)!
	return obj
}
