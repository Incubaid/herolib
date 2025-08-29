module hetznermanager

import freeflowuniverse.herolib.core.httpconnection
import freeflowuniverse.herolib.data.encoderhero
import freeflowuniverse.herolib.core.playbook

pub const version = '0.0.0'
const singleton = false
const default = true

@[heap]
pub struct HetznerManager {
pub mut:
	name        string = 'default'
	description string
	baseurl     string = 'https://robot-ws.your-server.de'
	whitelist   []int // comma separated list of servers we whitelist to work on
	user        string
	password    string
	sshkey      string
	nodes       []HetznerNode
}

@[heap]
pub struct HetznerNode {
pub mut:
	id          string
	name        string = 'default'
	description string
}

pub fn (mut h HetznerManager) connection() !&httpconnection.HTTPConnection {
	mut c2 := httpconnection.new(
		name:  'hetzner_${h.name}'
		url:   h.baseurl
		cache: true
		retry: 3
	)!
	c2.basic_auth(h.user, h.password)
	return c2
}

fn obj_init(mycfg_ HetznerManager) !HetznerManager {
	mut mycfg := mycfg_
	return mycfg
}

pub fn heroscript_loads(heroscript string) !HetznerManager {
	mut obj := encoderhero.decode[HetznerManager](heroscript)!
	return obj
}
