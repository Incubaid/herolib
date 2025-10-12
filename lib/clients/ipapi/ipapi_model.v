module ipapi

import incubaid.herolib.data.paramsparser
import incubaid.herolib.core.httpconnection
import os

pub const version = '1.14.3'
const singleton = false
const default = true

// TODO: THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED IN LINE TO STRUCT BELOW, IS STRUCTURED AS HEROSCRIPT
pub fn heroscript_default() !string {
	heroscript := "
    !!ipapi.configure 
        name:'default'
        "

	return heroscript
}

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

@[heap]
pub struct IPApi {
pub mut:
	name string = 'default'

	conn ?&httpconnection.HTTPConnection @[str: skip]
}

fn cfg_play(p paramsparser.Params) ! {
	// THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED IN LINE WITH struct above
	mut mycfg := IPApi{
		name: p.get_default('name', 'default')!
	}
	set(mycfg)!
}

fn obj_init(obj_ IPApi) !IPApi {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}

pub fn (mut client IPApi) connection() !&httpconnection.HTTPConnection {
	mut c := client.conn or {
		mut c2 := httpconnection.new(
			name:  'ipapi_${client.name}'
			url:   'http://ip-api.com'
			cache: false
			retry: 20
		)!
		c2
	}

	client.conn = c
	return c
}
