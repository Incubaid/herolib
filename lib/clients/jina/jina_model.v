module jina

import incubaid.herolib.data.encoderhero
import incubaid.herolib.core.httpconnection
// import net.http
import os

pub const version = '0.0.0'
const singleton = false
const default = true
const api_base_url = 'https://api.jina.ai'
const env_key = 'JINAKEY'

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

@[heap]
pub struct Jina {
pub mut:
	name     string = 'default'
	secret   string
	base_url string = api_base_url
	// http     httpconnection.HTTPConnection @[str: skip]
}

fn (mut self Jina) httpclient() !&httpconnection.HTTPConnection {
	mut http_conn := httpconnection.new(
		name: 'Jina_vclient'
		url:  self.base_url
	)!

	// Add authentication header if API key is provided
	if self.secret.len > 0 {
		http_conn.default_header.add(.authorization, 'Bearer ${self.secret}')
	}
	return http_conn
}

// your checking & initialization code if needed
fn obj_init(mycfg_ Jina) !Jina {
	mut mycfg := mycfg_

	// Get API key from environment variable if not set
	if mycfg.secret == '' {
		if env_key in os.environ() {
			mycfg.secret = os.environ()[env_key]
		} else {
			return error('Jina API key not provided and ${env_key} environment variable not set')
		}
	}

	return mycfg
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj Jina) !string {
	return encoderhero.encode[Jina](obj)!
}

pub fn heroscript_loads(heroscript string) !Jina {
	mut obj := encoderhero.decode[Jina](heroscript)!
	return obj
}
