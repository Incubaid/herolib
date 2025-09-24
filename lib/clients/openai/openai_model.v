module openai

import freeflowuniverse.herolib.data.encoderhero
import freeflowuniverse.herolib.core.httpconnection
import os

pub const version = '0.0.0'
const singleton = false
const default = true

@[heap]
pub struct OpenAI {
pub mut:
	name          string = 'default'
	api_key       string
	url           string = 'https://openrouter.ai/api/v1'
	model_default string = 'gpt-oss-120b'
	// conn          ?&httpconnection.HTTPConnection @[skip; str: skip]
}

// your checking & initialization code if needed
fn obj_init(mycfg_ OpenAI) !OpenAI {
	mut mycfg := mycfg_
	if mycfg.model_default == '' {
		k := os.getenv('AIMODEL')
		if k != '' {
			mycfg.model_default = k
		}
	}

	if mycfg.url == '' {
		k := os.getenv('AIURL')
		if k != '' {
			mycfg.url = k
		}
	}
	if mycfg.api_key == '' {
		k := os.getenv('AIKEY')
		if k != '' {
			mycfg.api_key = k
		}
		if mycfg.url.contains('openrouter') {
			k2 := os.getenv('OPENROUTER_API_KEY')
			if k2 != '' {
				mycfg.api_key = k2
			}
		}
	}
	return mycfg
}

pub fn (mut client OpenAI) connection() !&httpconnection.HTTPConnection {
	mut c2 := httpconnection.new(
		name:  'openaiconnection_${client.name}'
		url:   client.url
		cache: false
		retry: 20
	)!
	// Authorization: 'Bearer <OPENROUTER_API_KEY>',
	c2.default_header.set(.authorization, 'Bearer ${client.api_key}')
	return c2
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj OpenAI) !string {
	return encoderhero.encode[OpenAI](obj)!
}

pub fn heroscript_loads(heroscript string) !OpenAI {
	mut obj := encoderhero.decode[OpenAI](heroscript)!
	return obj
}
