module tailwind

import incubaid.herolib.data.encoderhero

pub const version = '3.4.12'
const singleton = false
const default = true

@[heap]
pub struct Tailwind {
pub mut:
	name string = 'default'
}

fn obj_init(mycfg_ Tailwind) !Tailwind {
	mut mycfg := mycfg_
	return mycfg
}

fn configure() ! {
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj Tailwind) !string {
	return encoderhero.encode[Tailwind](obj)!
}

pub fn heroscript_loads(heroscript string) !Tailwind {
	mut obj := encoderhero.decode[Tailwind](heroscript)!
	return obj
}
