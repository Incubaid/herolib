module cryptpad

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import os

pub const version = '0.0.0'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct CryptPad {
pub mut:
	name       string = 'default'
	domain    string
	domain_sandbox string
	configpath string //can be left empty, will be set to default path (is kubernetes config file)
	cryptpad_configpath string //can be left empty, will be set to default path
	masters []string //list of master servers for kubernetes
	domainname string //can be 1 name e.g. mycryptpad or it can be a fully qualified domain name e.g. mycryptpad.mycompany.com
}

// your checking & initialization code if needed
fn obj_init(mycfg_ CryptPad) !CryptPad {
	mut mycfg := mycfg_
	if mycfg.domain == '' {
		return error('CryptPad client "${mycfg.name}" missing domain')
	}
	if mycfg.configpath == '' {
		mycfg.configpath = '${os.home_dir()}/.apps/cryptpad/${mycfg.name}/config.yaml'
	}
	//call kubernetes client to get master nodes and put them in 
	mycfg.masters = []string{} //TODO get from kubernetes
	return mycfg
}

// called before start if done
fn configure() ! {
	mut installer := get()!
	mut mycode := $tmpl('templates/main.yaml')
	mut path := pathlib.get_file(path: cfg.configpath, create: true)!
	path.write(mycode)!
	console.print_debug(mycode)
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !CryptPad {
	mut obj := encoderhero.decode[CryptPad](heroscript)!
	return obj
}
