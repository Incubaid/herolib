module zerodb

import incubaid.herolib.data.encoderhero
import os
import rand
import crypto.md5
import incubaid.herolib.crypt.secrets

pub const version = '2.0.7'
const singleton = true
const default = true

@[heap]
pub struct ZeroDB {
pub mut:
	name         string = 'default'
	secret       string @[secret]
	sequential   bool // if sequential then we autoincrement the keys
	datadir      string = '${os.home_dir()}/var/zdb/data'
	indexdir     string = '${os.home_dir()}/var/zdb/index'
	rotateperiod int    = 1200 // 20 min
	port         int    = 3355
}

// your checking & initialization code if needed
fn obj_init(mycfg_ ZeroDB) !ZeroDB {
	mut mycfg := mycfg_
	if mycfg.name == '' {
		mycfg.name = 'default'
	}

	if mycfg.secret == '' {
		secret := md5.hexhash(rand.string(16))
		mut box := secrets.get(secret: secret)!
		mycfg.secret = box.encrypt(secret)!
	}

	if mycfg.datadir == '' {
		mycfg.datadir = '${os.home_dir()}/var/zdb/data'
	}

	if mycfg.indexdir == '' {
		mycfg.indexdir = '${os.home_dir()}/var/zdb/index'
	}

	if mycfg.rotateperiod == 0 {
		mycfg.rotateperiod = 1200
	}

	if mycfg.port == 0 {
		mycfg.port = 3355
	}

	return mycfg
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj ZeroDB) !string {
	return encoderhero.encode[ZeroDB](obj)!
}

pub fn heroscript_loads(heroscript string) !ZeroDB {
	mut obj := encoderhero.decode[ZeroDB](heroscript)!
	return obj
}
