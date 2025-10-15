module prometheus

import incubaid.herolib.data.encoderhero

pub const version = '0.0.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct Prometheus {
pub mut:
	name string = 'default'
}

fn obj_init(obj_ Prometheus) !Prometheus {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	panic('implement')
	return obj
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj Prometheus) !string {
	return encoderhero.encode[Prometheus](obj)!
}

pub fn heroscript_loads(heroscript string) !Prometheus {
	mut obj := encoderhero.decode[Prometheus](heroscript)!
	return obj
}
