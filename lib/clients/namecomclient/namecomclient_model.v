// File: lib/clients/namecomclient/namecomclient_model.v
module namecomclient

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import incubaid.herolib.core.httpconnection
import encoding.base64
import os

pub const version = '0.0.0'

@[heap]
pub struct NamecomClient {
pub mut:
	name     string = 'default'
	username string
	token    string
	url      string = 'https://api.name.com'
}

fn (mut self NamecomClient) httpclient() !&httpconnection.HTTPConnection {
	mut http_conn := httpconnection.new(
		name: 'namecomclient_${self.name}'
		url:  self.url
	)!

	// Add Basic Auth header (username:token base64 encoded)
	if self.username.len > 0 && self.token.len > 0 {
		credentials := '${self.username}:${self.token}'
		encoded := base64.encode_str(credentials)
		http_conn.default_header.add(.authorization, 'Basic ${encoded}')
	}
	return http_conn
}

// your checking & initialization code if needed
fn obj_init(mycfg_ NamecomClient) !NamecomClient {
	mut mycfg := mycfg_
	if mycfg.url == '' {
		mycfg.url = 'https://api.name.com'
	}
	if mycfg.url.starts_with('https://') {
		mycfg.url = mycfg.url.replace('https://', '')
	}
	if mycfg.url.starts_with('http://') {
		mycfg.url = mycfg.url.replace('http://', '')
	}
	mycfg.url = mycfg.url.trim_right('/')
	if mycfg.url.ends_with('/v4') {
		mycfg.url = mycfg.url.replace('/v4', '')
	}
	mycfg.url = 'https://${mycfg.url}/v4'

	if mycfg.username.len == 0 {
		return error('username needs to be filled in for ${mycfg.name}')
	}
	if mycfg.token.len == 0 {
		return error('token needs to be filled in for ${mycfg.name}')
	}
	return mycfg
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !NamecomClient {
	mut obj := encoderhero.decode[NamecomClient](heroscript)!
	return obj
}
