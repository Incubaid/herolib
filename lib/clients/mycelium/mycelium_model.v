module mycelium

import incubaid.herolib.core.httpconnection
import incubaid.herolib.data.encoderhero

pub const version = '0.0.0'
const singleton = true
const default = true

@[heap]
pub struct Mycelium {
pub mut:
	name       string = 'default'
	server_url string = 'http://localhost:8989'
	conn       ?&httpconnection.HTTPConnection @[skip; str: skip]
}

// your checking & initialization code if needed
fn obj_init(mycfg_ Mycelium) !Mycelium {
	mut mycfg := mycfg_
	return mycfg
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj Mycelium) !string {
	return encoderhero.encode[Mycelium](obj)!
}

pub fn heroscript_loads(heroscript string) !Mycelium {
	mut obj := encoderhero.decode[Mycelium](heroscript)!
	return obj
}
