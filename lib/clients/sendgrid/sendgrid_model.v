module sendgrid

import incubaid.herolib.data.encoderhero

pub const version = '0.0.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

@[heap]
pub struct SendGrid {
pub mut:
	name          string = 'default'
	mail_from     string
	mail_password string @[secret]
	mail_port     int
	mail_server   string
	mail_username string
}

fn obj_init(obj_ SendGrid) !SendGrid {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	panic('implement')
	return obj
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj SendGrid) !string {
	return encoderhero.encode[SendGrid](obj)!
}

pub fn heroscript_loads(heroscript string) !SendGrid {
	mut obj := encoderhero.decode[SendGrid](heroscript)!
	return obj
}
