module lima

import freeflowuniverse.herolib.data.paramsparser
import freeflowuniverse.herolib.data.encoderhero
import os

pub const version = '1.2.1'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct LimaInstaller {
pub mut:
	name    string = 'default'
	homedir string
	extra   bool   // do we want to extra's
	sshkey  string // name of the key to use
}

// your checking & initialization code if needed
fn obj_init(mycfg_ LimaInstaller) !LimaInstaller {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
	// mut mycode := $tmpl('templates/atemplate.yaml')
	// mut path := pathlib.get_file(path: cfg.configpath, create: true)!
	// path.write(mycode)!
	// console.print_debug(mycode)
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !LimaInstaller {
	mut obj := encoderhero.decode[LimaInstaller](heroscript)!
	return obj
}
