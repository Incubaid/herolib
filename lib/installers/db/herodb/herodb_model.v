module herodb

import incubaid.herolib.data.encoderhero
import incubaid.herolib.core.pathlib

pub const version = '0.0.0'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct HeroDBInstaller {
pub mut:
	name       string = 'default'
	adminsecret string 
	host       []string //e.g. localhost, ... 
	port       int = 5555 
	rpc_socket  string = '/var/run/herodb/admin.sock' // unix socket for admin purposes only, no password or secret needed
	path string = '/var/lib/herodb' // e.g. /var/lib/herodb
}

// your checking & initialization code if needed
fn obj_init(mycfg_ HeroDBInstaller) !HeroDBInstaller {
	mut mycfg := mycfg_
	if mycfg.adminsecret == '' {
	   return error('adminsecret needs to be filled in for ${mycfg.name}')
	}
	if mycfg.path == '' {
	   mycfg.path = '/var/lib/herodb'
	}
	// ensure the data directory exists
	pathlib.get_dir(path: mycfg.path, create: true) or {
	   return error('could not create data directory ${mycfg.path} for ${mycfg.name}: ${err}')
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

pub fn heroscript_loads(heroscript string) !HeroDBInstaller {
	mut obj := encoderhero.decode[HeroDBInstaller](heroscript)!
	return obj
}
