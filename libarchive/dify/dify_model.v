module dify

import freeflowuniverse.herolib.data.paramsparser
import freeflowuniverse.herolib.data.encoderhero
import os
import rand

pub const version = '0.0.0'
const singleton = true
const default = false

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct DifyInstaller {
pub mut:
	name          string = 'default'
	path          string = '/opt/dify'
	init_password string
	secret_key    string
	project_name  string = 'dify'
	compose_file  string = '/opt/dify/docker/docker-compose.yaml'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ DifyInstaller) !DifyInstaller {
	mut mycfg := mycfg_
	if mycfg.path == '' {
		mycfg.path = '/opt/dify'
	}

	if mycfg.secret_key == '' {
		mycfg.secret_key = rand.hex(42)
	}

	if mycfg.init_password == '' {
		mycfg.init_password = 'slfjbv9NaflKsgjv'
	}

	if mycfg.project_name == '' {
		mycfg.project_name = 'dify'
	}

	if mycfg.compose_file == '' {
		mycfg.compose_file = '/opt/dify/docker/docker-compose.yaml'
	}

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

pub fn heroscript_dumps(obj DifyInstaller) !string {
	return encoderhero.encode[DifyInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !DifyInstaller {
	mut obj := encoderhero.decode[DifyInstaller](heroscript)!
	return obj
}
