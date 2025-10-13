module caddy

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import os

pub const xcaddy_version = '0.4.2'
pub const caddy_version = '2.8.4'
const singleton = true
const default = true

@[heap]
pub struct CaddyServer {
pub mut:
	name string = 'default'
	// path is the path to the server's root directory.
	path string = '/var/www'
	// domain is the default domain for the server.
	domain string // sort of default domain
	// plugins is a list of plugins to be used by the server.
	plugins []string
}

// your checking & initialization code if needed
fn obj_init(mycfg_ CaddyServer) !CaddyServer {
	mut mycfg := mycfg_
	return mycfg
}

// user needs to us switch to make sure we get the right object
fn configure() ! {
	mut cfg := get()!
	if !os.exists('/etc/caddy/Caddyfile') {
		// set the default caddyfile
		configure_examples(path: cfg.path)!
	}
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj CaddyServer) !string {
	return encoderhero.encode[CaddyServer](obj)!
}

pub fn heroscript_loads(heroscript string) !CaddyServer {
	mut obj := encoderhero.decode[CaddyServer](heroscript)!
	return obj
}
