module wireguard

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero

pub const version = '1.14.3'
const singleton = false
const default = true

// TODO: THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED IN LINE TO STRUCT BELOW, IS STRUCTURED AS HEROSCRIPT
pub fn heroscript_default() !string {
	heroscript := "
    !!wireguard.configure 
        name:'wireguard'
        "
	return heroscript
}

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

@[heap]
pub struct WireGuard {
pub mut:
	name string = 'wireguard'
}

fn cfg_play(p paramsparser.Params) ! {
	// THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED IN LINE WITH struct above
	mut mycfg := WireGuard{
		name: p.get_default('name', 'wireguard')!
	}
	set(mycfg)!
}

fn obj_init(obj_ WireGuard) !WireGuard {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj WireGuard) !string {
	return encoderhero.encode[WireGuard](obj)!
}

pub fn heroscript_loads(heroscript string) !WireGuard {
	mut obj := encoderhero.decode[WireGuard](heroscript)!
	return obj
}
