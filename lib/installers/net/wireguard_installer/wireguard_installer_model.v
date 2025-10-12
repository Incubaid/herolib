module wireguard_installer

import incubaid.herolib.data.encoderhero

pub const version = '1.14.3'
const singleton = false
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct WireGuard {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ WireGuard) !WireGuard {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj WireGuard) !string {
	return encoderhero.encode[WireGuard](obj)!
}

pub fn heroscript_loads(heroscript string) !WireGuard {
	mut obj := encoderhero.decode[WireGuard](heroscript)!
	return obj
}
