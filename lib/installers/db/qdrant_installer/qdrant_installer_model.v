module qdrant_installer

import incubaid.herolib.data.encoderhero
import incubaid.herolib.core.pathlib
import os

pub const version = '1.13.4'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct QDrant {
pub mut:
	name       string = 'default'
	homedir    string
	configpath string
	username   string
	password   string @[secret]
	title      string
	host       string
	port       int
}

// your checking & initialization code if needed
fn obj_init(mycfg_ QDrant) !QDrant {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	mut installer := get()!
	storage_path := '${os.home_dir()}/hero/var/qdrant'
	mut mycode := $tmpl('templates/config.yaml')
	mut path := pathlib.get_file(path: '${os.home_dir()}/hero/var/qdrant/config.yaml', create: true)!
	path.write(mycode)!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj QDrant) !string {
	return encoderhero.encode[QDrant](obj)!
}

pub fn heroscript_loads(heroscript string) !QDrant {
	mut obj := encoderhero.decode[QDrant](heroscript)!
	return obj
}
