module crun_installer

import incubaid.herolib.data.encoderhero

pub const version = '0.0.0'
const singleton = false
const default = true

// CrunInstaller manages the installation of the crun container runtime
@[heap]
pub struct CrunInstaller {
pub mut:
	name string = 'default'
}

// Initialize the installer object
fn obj_init(mycfg_ CrunInstaller) !CrunInstaller {
	mut mycfg := mycfg_
	return mycfg
}

// Configure is called before installation if needed
fn configure() ! {
	// No configuration needed for crun installer
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !CrunInstaller {
	mut obj := encoderhero.decode[CrunInstaller](heroscript)!
	return obj
}
