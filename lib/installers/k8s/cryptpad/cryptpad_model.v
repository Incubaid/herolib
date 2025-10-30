module cryptpad

import incubaid.herolib.data.encoderhero
import incubaid.herolib.ui.console

pub const version = '1.0.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct CryptpadServer {
pub mut:
	name      string = 'default'
	hostname  string
	namespace string = 'collab'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ CryptpadServer) !CryptpadServer {
	mut mycfg := mycfg_
	if mycfg.hostname == '' {
		return error('hostname cannot be empty')
	}
	if mycfg.namespace == '' {
		mycfg.namespace = 'collab'
	}
	return mycfg
}

// called before start if done
fn configure() ! {
	// We will implement the configuration logic here,
	// like generating the yaml files from templates.
	console.print_debug('configuring cryptpad...')
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj CryptpadServer) !string {
	return encoderhero.encode[CryptpadServer](obj)!
}

pub fn heroscript_loads(heroscript string) !CryptpadServer {
	mut obj := encoderhero.decode[CryptpadServer](heroscript)!
	return obj
}
