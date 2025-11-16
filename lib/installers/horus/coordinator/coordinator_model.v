module coordinator

import incubaid.herolib.data.encoderhero
import incubaid.herolib.osal.core as osal
import incubaid.herolib.core.pathlib

const version = '0.1.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct CoordinatorServer {
pub mut:
	name         string = 'default'
	binary_path  string = '/hero/var/bin/coordinator'
	redis_addr   string = '127.0.0.1:6379'
	http_port    int    = 8081
	ws_port      int    = 9653
	log_level    string = 'info'
	repo_path    string = '/root/code/git.ourworld.tf/herocode/horus'
}

// Initialize configuration with defaults if not provided
// Note: Struct defaults are already set, this ensures runtime overrides work correctly
fn obj_init(mycfg_ CoordinatorServer) !CoordinatorServer {
	mut mycfg := mycfg_
	
	// Only override if explicitly empty (struct defaults should handle most cases)
	if mycfg.name == '' {
		mycfg.name = 'default'
	}
	if mycfg.binary_path == '' {
		mycfg.binary_path = '/hero/var/bin/coordinator'
	}
	if mycfg.redis_addr == '' {
		mycfg.redis_addr = '127.0.0.1:6379'
	}
	if mycfg.http_port == 0 {
		mycfg.http_port = 8081
	}
	if mycfg.ws_port == 0 {
		mycfg.ws_port = 9653
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

pub fn heroscript_dumps(obj CoordinatorServer) !string {
	return encoderhero.encode[CoordinatorServer](obj)!
}

pub fn heroscript_loads(heroscript string) !CoordinatorServer {
	mut obj := encoderhero.decode[CoordinatorServer](heroscript)!
	return obj
}
