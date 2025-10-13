module golang

import incubaid.herolib.data.encoderhero

pub const version = '1.23.6'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct GolangInstaller {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ GolangInstaller) !GolangInstaller {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj GolangInstaller) !string {
	return encoderhero.encode[GolangInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !GolangInstaller {
	mut obj := encoderhero.decode[GolangInstaller](heroscript)!
	return obj
}
