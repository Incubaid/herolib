module traefik

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import os
import incubaid.herolib.ui.console
import incubaid.herolib.core.pathlib

pub const version = '3.3.3'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct TraefikServer {
pub mut:
	name string = 'default'
	// homedir    string
	// configpath string
	// username   string
	password string @[secret]
	// title      string
	// host       string
	// port       int
}

// your checking & initialization code if needed
fn obj_init(mycfg_ TraefikServer) !TraefikServer {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	mut installer := get()!
	htaccesscode := generate_htpasswd('admin', installer.password)!
	mut mycode := $tmpl('templates/traefik.toml')
	mut path := pathlib.get_file(path: '/etc/traefik/traefik.toml', create: true)!
	path.write(mycode)!
	console.print_debug(mycode)
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj TraefikServer) !string {
	return encoderhero.encode[TraefikServer](obj)!
}

pub fn heroscript_loads(heroscript string) !TraefikServer {
	mut obj := encoderhero.decode[TraefikServer](heroscript)!
	return obj
}
