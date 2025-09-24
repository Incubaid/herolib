module livekit

import freeflowuniverse.herolib.data.paramsparser
import freeflowuniverse.herolib.data.encoderhero
import os

pub const version = '0.0.0'
const singleton = false
const default = true

@[heap]
pub struct LivekitClient {
pub mut:
	name       string = 'default'
	url        string @[required]
	api_key    string @[required]
	api_secret string @[required; secret]
}

// your checking & initialization code if needed
fn obj_init(mycfg_ LivekitClient) !LivekitClient {
	mut mycfg := mycfg_
	if mycfg.url == '' {
		return error('url needs to be filled in for ${mycfg.name}')
	}
	if mycfg.api_key == '' {
		return error('api_key needs to be filled in for ${mycfg.name}')
	}
	if mycfg.api_secret == '' {
		return error('api_secret needs to be filled in for ${mycfg.name}')
	}
	return mycfg
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj LivekitClient) !string {
	return encoderhero.encode[LivekitClient](obj)!
}

pub fn heroscript_loads(heroscript string) !LivekitClient {
	mut obj := encoderhero.decode[LivekitClient](heroscript)!
	return obj
}
