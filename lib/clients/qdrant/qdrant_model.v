module qdrant

// import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
// import json
// import os

pub const version = '0.0.0'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

@[heap]
pub struct QDrantClient {
pub mut:
	name   string = 'default'
	secret string
	url    string = 'http://localhost:6333/'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ QDrantClient) !QDrantClient {
	mut mycfg := mycfg_
	return mycfg
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj QDrantClient) !string {
	return encoderhero.encode[QDrantClient](obj)!
}

pub fn heroscript_loads(heroscript string) !QDrantClient {
	mut obj := encoderhero.decode[QDrantClient](heroscript)!
	return obj
}
