module kubernetes

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import os

pub const version = '0.0.0'
const singleton = false
const default = true

@[heap]
pub struct KubeClient {
pub mut:
	name              string = 'default'
	kubeconfig_path   string
	config            KubeConfig
	connected         bool
	api_version       string = 'v1'
	cache_enabled     bool   = true
	cache_ttl_seconds int    = 300
}

// your checking & initialization code if needed
fn obj_init(mycfg_ KubeClient) !KubeClient {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
	// mut mycode := $tmpl('templates/atemplate.yaml')
	// mut path := pathlib.get_file(path: cfg.configpath, create: true)!
	// path.write(mycode)!
	// console.print_debug(mycode)
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !KubeClient {
	// TODO: will have to be implemented manual
	mut obj := encoderhero.decode[KubeClient](heroscript)!
	return obj
}
