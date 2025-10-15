module coredns

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import os

pub const version = '1.12.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct CoreDNS {
pub mut:
	name          string = 'default'
	config_path   string
	config_url    string // path to Corefile through e.g. git url, will pull it if it is not local yet
	dnszones_path string // path to where all the dns zones are
	dnszones_url  string // path on git url pull if needed (is comma or \n separated list)
	plugins       string // list of plugins to build CoreDNS with (is comma or \n separated list)
	example       bool = true // if true we will install examples
}

// your checking & initialization code if needed
fn obj_init(mycfg_ CoreDNS) !CoreDNS {
	mut mycfg := mycfg_
	return mycfg
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj CoreDNS) !string {
	return encoderhero.encode[CoreDNS](obj)!
}

pub fn heroscript_loads(heroscript string) !CoreDNS {
	mut obj := encoderhero.decode[CoreDNS](heroscript)!
	return obj
}
