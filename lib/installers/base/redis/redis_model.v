module redis

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import incubaid.herolib.osal.core as osal
import incubaid.herolib.core.pathlib
import incubaid.herolib.core
import os

pub const version = '7.0.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
@[heap]
pub struct RedisInstall {
pub mut:
	name    string = 'default'
	port    int    = 6379
	datadir string = '${os.home_dir()}/hero/var/redis'
	ipaddr  string = 'localhost' // can be more than 1, space separated
}

// your checking & initialization code if needed
fn obj_init(mycfg_ RedisInstall) !RedisInstall {
	mut mycfg := mycfg_
	if mycfg.name == '' {
		mycfg.name = 'default'
	}
	if mycfg.port == 0 {
		mycfg.port = 6379
	}
	if mycfg.datadir == '' {
		mycfg.datadir = '${os.home_dir()}/hero/var/redis'
	}
	if mycfg.ipaddr == '' {
		mycfg.ipaddr = 'localhost'
	}
	return mycfg
}

fn configfilepath(args RedisInstall) string {
	if core.is_linux() or { panic(err) } {
		return '/etc/redis/redis.conf'
	} else {
		return '${args.datadir}/redis.conf'
	}
}

// called before start if done
fn configure() ! {
	mut args := get()!
	c := $tmpl('../templates/redis_config.conf')
	pathlib.template_write(c, configfilepath(args), true)!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !RedisInstall {
	mut obj := encoderhero.decode[RedisInstall](heroscript)!
	return obj
}
