module osirisrunner

import os
import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import incubaid.herolib.osal.core as osal
import incubaid.herolib.core.pathlib

const version = '0.1.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct OsirisrunnerServer {
pub mut:
	name         string = 'default'
	binary_path  string = os.join_path(os.home_dir(), 'hero/bin/runner_osiris')
	redis_addr   string = '127.0.0.1:6379'
	log_level    string = 'info'
	repo_path    string = '/root/code/git.ourworld.tf/herocode/horus'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ OsirisrunnerServer) !OsirisrunnerServer {
	mut mycfg := mycfg_
	if mycfg.name == '' {
		mycfg.name = 'default'
	}
	if mycfg.binary_path == '' {
		mycfg.binary_path = os.join_path(os.home_dir(), 'hero/bin/runner_osiris')
	}
	if mycfg.redis_addr == '' {
		mycfg.redis_addr = '127.0.0.1:6379'
	}
	if mycfg.log_level == '' {
		mycfg.log_level = 'info'
	}
	if mycfg.repo_path == '' {
		mycfg.repo_path = '/root/code/git.ourworld.tf/herocode/horus'
	}
	return mycfg
}

// called before start if done
fn configure() ! {
	mut server := get()!
	// Ensure the binary directory exists
	mut binary_path_obj := pathlib.get(server.binary_path)
	osal.dir_ensure(binary_path_obj.path_dir())!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj OsirisrunnerServer) !string {
	return encoderhero.encode[OsirisrunnerServer](obj)!
}

pub fn heroscript_loads(heroscript string) !OsirisrunnerServer {
	mut obj := encoderhero.decode[OsirisrunnerServer](heroscript)!
	return obj
}
