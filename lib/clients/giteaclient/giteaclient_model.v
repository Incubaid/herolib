// File: lib/clients/giteaclient/giteaclient_model.v
module giteaclient

import freeflowuniverse.herolib.data.paramsparser
import freeflowuniverse.herolib.data.encoderhero
import freeflowuniverse.herolib.core.httpconnection
import os

pub const version = '0.0.0'

@[heap]
pub struct GiteaClient {
pub mut:
	name   string = 'default'
	user   string
	url    string = 'https://git.ourworld.tf'
	secret string
}

fn (mut self GiteaClient) httpclient() !&httpconnection.HTTPConnection {
	mut http_conn := httpconnection.new(
		name: 'giteaclient_${self.name}'
		url:  self.url
	)!

	// Add authentication header if API key is provided
	if self.secret.len > 0 {
		http_conn.default_header.add(.authorization, 'token ${self.secret}')
	}
	return http_conn
}

// your checking & initialization code if needed
fn obj_init(mycfg_ GiteaClient) !GiteaClient {
	mut mycfg := mycfg_
	if mycfg.url == '' {
		return error('url needs to be filled in for ${mycfg.name}')
	}
	if mycfg.url.starts_with('https://') {
		mycfg.url = mycfg.url.replace('https://', '')
	}
	if mycfg.url.starts_with('http://') {
		mycfg.url = mycfg.url.replace('http://', '')
	}
	mycfg.url = mycfg.url.trim_right('/')
	if mycfg.url.ends_with('/api/v1') {
		mycfg.url = mycfg.url.replace('/api/v1', '')
	}
	if mycfg.url.ends_with('/api') {
		mycfg.url = mycfg.url.replace('/api', '')
	}
	mycfg.url = 'https://${mycfg.url}/api/v1'

	if mycfg.secret.len == 0 {
		return error('secret needs to be filled in for ${mycfg.name}')
	}
	return mycfg
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !GiteaClient {
	mut obj := encoderhero.decode[GiteaClient](heroscript)!
	return obj
}
