module openrouter

import incubaid.herolib.data.encoderhero
import incubaid.herolib.core.httpconnection
import os

pub const version = '0.0.0'
const singleton = false
const default = true

@[heap]
pub struct OpenRouter {
pub mut:
	name          string = 'default'
	api_key       string
	url           string = 'https://openrouter.ai/api/v1'
	model_default string = 'qwen/qwen-2.5-coder-32b-instruct'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ OpenRouter) !OpenRouter {
	mut mycfg := mycfg_
	if mycfg.model_default == '' {
		k := os.getenv('OPENROUTER_AI_MODEL')
		if k != '' {
			mycfg.model_default = k
		}
	}

	if mycfg.url == '' {
		k := os.getenv('OPENROUTER_URL')
		if k != '' {
			mycfg.url = k
		}
	}
	if mycfg.api_key == '' {
		k := os.getenv('OPENROUTER_API_KEY')
		if k != '' {
			mycfg.api_key = k
		} else {
			return error('OPENROUTER_API_KEY environment variable not set')
		}
	}
	return mycfg
}

pub fn (mut client OpenRouter) connection() !&httpconnection.HTTPConnection {
	mut c2 := httpconnection.new(
		name:  'openrouterconnection_${client.name}'
		url:   client.url
		cache: false
		retry: 20
	)!
	c2.default_header.set(.authorization, 'Bearer ${client.api_key}')
	return c2
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj OpenRouter) !string {
	return encoderhero.encode[OpenRouter](obj)!
}

pub fn heroscript_loads(heroscript string) !OpenRouter {
	mut obj := encoderhero.decode[OpenRouter](heroscript)!
	return obj
}
