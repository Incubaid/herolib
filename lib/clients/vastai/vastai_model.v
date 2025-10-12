module vastai

import incubaid.herolib.data.paramsparser
import incubaid.herolib.core.httpconnection
import os

pub const version = '1.14.3'
const singleton = true
const default = true

// TODO: THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED IN LINE TO STRUCT BELOW, IS STRUCTURED AS HEROSCRIPT
pub fn heroscript_default() !string {
	heroscript := "
    !!vastai.configure
        name:'default'
        api_key:'${os.getenv('VASTAI_API_KEY')}'
        base_url:'https://console.vast.ai/api/v0/'
    "
	return heroscript
}

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

@[heap]
pub struct VastAI {
pub mut:
	name     string = 'default'
	api_key  string
	base_url string
}

fn cfg_play(p paramsparser.Params) ! {
	// THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED IN LINE WITH struct above
	mut mycfg := VastAI{
		name:     p.get_default('name', 'default')!
		api_key:  p.get_default('api_key', '${os.getenv('VASTAI_API_KEY')}')!
		base_url: p.get_default('base_url', 'https://console.vast.ai/api/v0/')!
	}
	set(mycfg)!
}

fn obj_init(obj_ VastAI) !VastAI {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}

fn (mut v VastAI) httpclient() !&httpconnection.HTTPConnection {
	mut http_conn := httpconnection.new(
		name:  'vastai_client_${v.name}'
		url:   v.base_url
		cache: true
		retry: 3
	)!
	http_conn.default_header.add(.authorization, 'Bearer ${v.api_key}')
	http_conn.default_header.add(.accept, 'application/json')

	return http_conn
}
