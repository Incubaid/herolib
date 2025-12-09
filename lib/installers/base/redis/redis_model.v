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
	datadir string // platform-specific default set in obj_init
	ipaddr  string = 'localhost' // can be more than 1, space separated
}

// Returns platform-specific default data directory
fn default_datadir() !string {
	platform := core.platform()!
	return match platform {
		.osx { os.home_dir() + '/.redis' }
		else { '/var/lib/redis' }
	}
}

// Returns platform-specific package name for redis
fn package_name() !string {
	platform := core.platform()!
	return match platform {
		.ubuntu { 'redis-server' }
		else { 'redis' }
	}
}

// Returns platform-specific systemd service name
fn service_name() !string {
	platform := core.platform()!
	return match platform {
		.ubuntu { 'redis-server' }
		else { 'redis' }
	}
}

// Check if systemd is actually available (not just systemctl command exists)
fn systemd_available() bool {
	return os.exists('/run/systemd/system')
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
		mycfg.datadir = default_datadir()!
	}
	if mycfg.ipaddr == '' {
		mycfg.ipaddr = 'localhost'
	}
	return mycfg
}

fn configfilepath(args RedisInstall) !string {
	platform := core.platform()!
	return match platform {
		.osx { '${args.datadir}/redis.conf' }
		.alpine { '/etc/redis.conf' }
		else { '/etc/redis/redis.conf' }
	}
}

// Configure with args passed directly (like old installer)
fn configure_with_args(args RedisInstall) ! {
	// Use V's template macro like the old installer
	c := $tmpl('templates/redis_config.conf')
	pathlib.template_write(c, configfilepath(args)!, true)!
}

// called before start if done (uses factory)
fn configure() ! {
	mut args := get()!
	configure_with_args(args)!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !RedisInstall {
	mut obj := encoderhero.decode[RedisInstall](heroscript)!
	return obj
}
