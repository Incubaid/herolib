module daguserver

import freeflowuniverse.herolib.data.encoderhero
import freeflowuniverse.herolib.crypt.secrets
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.pathlib
import os

pub const version = '1.14.3'
const singleton = true
const default = true
pub const homedir = os.home_dir()

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct DaguInstaller {
pub mut:
	name       string = 'default'
	dagsdir    string = '${os.home_dir()}/.dagu'
	configpath string = '${os.home_dir()}/.config/dagu'
	username   string
	password   string @[secret]
	secret     string @[secret]
	title      string
	host       string = 'localhost'
	port       int    = 8014
}

// your checking & initialization code if needed
fn obj_init(mycfg_ DaguInstaller) !DaguInstaller {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	mut cfg := get()!

	if cfg.password == '' {
		cfg.password = secrets.hex_secret()!
	}

	// TODO:use DAGU_SECRET from env variables in os if not set then empty string
	if cfg.secret == '' {
		cfg.secret = secrets.openssl_hex_secret(input: cfg.password)!
	}

	if cfg.dagsdir == '' {
		cfg.dagsdir = '${homedir}/.dagu'
	}

	if cfg.configpath == '' {
		cfg.configpath = '${homedir}/.config/dagu'
	}

	if cfg.host == '' {
		cfg.host = 'localhost'
	}

	if cfg.port == 0 {
		cfg.port = 8014
	}

	mut mycode := $tmpl('templates/dagu.yaml')
	mut path := pathlib.get_file(path: '${cfg.configpath}/admin.yaml', create: true)!
	path.write(mycode)!
	console.print_debug(mycode)
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj DaguInstaller) !string {
	return encoderhero.encode[DaguInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !DaguInstaller {
	mut obj := encoderhero.decode[DaguInstaller](heroscript)!
	return obj
}
