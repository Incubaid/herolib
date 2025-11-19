module herorunner

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import incubaid.herolib.osal.core as osal
import incubaid.herolib.core.pathlib
import os

const version = '0.1.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct Herorunner {
pub mut:
	name         string = 'default'
	binary_path  string = os.join_path(os.home_dir(), 'hero/bin/herorunner')
	redis_addr   string = '127.0.0.1:6379'
	log_level    string = 'info'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ Herorunner) !Herorunner {
	mut mycfg := mycfg_
	if mycfg.name == '' {
		mycfg.name = 'default'
	}
	if mycfg.binary_path == '' {
		mycfg.binary_path = os.join_path(os.home_dir(), 'hero/bin/herorunner')
	}
	if mycfg.redis_addr == '' {
		mycfg.redis_addr = '127.0.0.1:6379'
	}
	if mycfg.log_level == '' {
		mycfg.log_level = 'info'
	}
	return mycfg
}

// called before start if done
fn configure() ! {
	mut server := get()!
	// Ensure the binary directory exists
	mut binary_path_obj := pathlib.get(server.binary_path)
	osal.dir_ensure(binary_path_obj.path_dir())!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj Herorunner) !string {
	return encoderhero.encode[Herorunner](obj)!
}

pub fn heroscript_loads(heroscript string) !Herorunner {
	mut obj := encoderhero.decode[Herorunner](heroscript)!
	return obj
}
