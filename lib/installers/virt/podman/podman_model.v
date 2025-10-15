module podman

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import os

pub const version = '4.9.3'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct PodmanInstaller {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ PodmanInstaller) !PodmanInstaller {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj PodmanInstaller) !string {
	return encoderhero.encode[PodmanInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !PodmanInstaller {
	mut obj := encoderhero.decode[PodmanInstaller](heroscript)!
	return obj
}
