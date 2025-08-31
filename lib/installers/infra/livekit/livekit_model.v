module livekit

import freeflowuniverse.herolib.data.encoderhero
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console
import os

pub const version = '1.9.0'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct LivekitServer {
pub mut:
	name       string = 'default'
	apikey     string
	apisecret  string @[secret]
	configpath string
	nr         int = 0 // each specific instance onto this server needs to have a unique nr
}

fn obj_init(obj_ LivekitServer) !LivekitServer {
	mut obj := obj_
	if obj.configpath == '' {
		obj.configpath = '${os.home_dir()}/hero/cfg/config.yaml'
	}
	return obj
}

// called before start if done
fn configure() ! {
	mut installer := get()!

	mut mycode := $tmpl('templates/config.yaml')
	mut path := pathlib.get_file(path: installer.configpath, create: true)!
	path.write(mycode)!
	console.print_debug(mycode)
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj LivekitServer) !string {
	return encoderhero.encode[LivekitServer](obj)!
}

pub fn heroscript_loads(heroscript string) !LivekitServer {
	mut obj := encoderhero.decode[LivekitServer](heroscript)!
	return obj
}
