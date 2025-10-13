module nodejs

import incubaid.herolib.data.encoderhero

pub const version = '9.15.2'
const singleton = true
const default = true

@[heap]
pub struct NodeJS {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ NodeJS) !NodeJS {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

pub fn heroscript_dumps(obj NodeJS) !string {
	return encoderhero.encode[NodeJS](obj)!
}

pub fn heroscript_loads(heroscript string) !NodeJS {
	mut obj := encoderhero.decode[NodeJS](heroscript)!
	return obj
}
