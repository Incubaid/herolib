module base

import freeflowuniverse.herolib.data.paramsparser
import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.core.pathlib
import json
import os

@[heap]
pub struct Context {
mut:
	params_ ?&paramsparser.Params
	redis_  ?&redisclient.Redis @[skip; str: skip]
	path_   ?pathlib.Path
pub mut:
	// snippets     map[string]string
	config ContextConfig
}

@[params]
pub struct ContextConfig {
pub mut:
	id          u32 @[required]
	name        string = 'default'
	params      string
	coderoot    string
	interactive bool
	// secret      string // is hashed secret
	// priv_key    string // encrypted version
	// db_path     string // path to dbcollection
	// encrypt     bool
}

// return the gistructure as is being used in context
pub fn (mut self Context) params() !&paramsparser.Params {
	mut p := self.params_ or {
		mut p := paramsparser.new(self.config.params)!
		self.params_ = &p
		&p
	}

	return p
}

pub fn (self Context) id() string {
	return self.config.id.str()
}

pub fn (self Context) name() string {
	return self.config.name
}

pub fn (self Context) guid() string {
	return '${self.id()}:${self.name()}'
}

pub fn (mut self Context) redis() !&redisclient.Redis {
	mut r2 := self.redis_ or {
		mut r := redisclient.core_get()!
		if self.config.id > 0 {
			// make sure we are on the right db
			r.selectdb(int(self.config.id))!
		}
		self.redis_ = r
		r
	}

	return r2
}

pub fn (mut self Context) save() ! {
	jsonargs := json.encode_pretty(self.config)
	mut r := self.redis()!
	r.set('context:config', jsonargs)!
}

// get context from out of redis
pub fn (mut self Context) load() ! {
	mut r := self.redis()!
	d := r.get('context:config')!
	if d.len > 0 {
		self.config = json.decode(ContextConfig, d)!
	}
}

fn (mut self Context) cfg_redis_exists() !bool {
	mut r := self.redis()!
	return r.exists('context:config')!
}

// pub fn (mut self Context) secret_encrypt(txt string) !string {
// 	return aes_symmetric.encrypt_str(txt, self.secret_get()!)
// }

// pub fn (mut self Context) secret_decrypt(txt string) !string {
// 	return aes_symmetric.decrypt_str(txt, self.secret_get()!)
// }

// pub fn (mut self Context) secret_get() !string {
// 	mut secret := self.config.secret
// 	if secret == '' {
// 		self.secret_configure()!
// 		secret = self.config.secret
// 		self.save()!
// 	}
// 	if secret == '' {
// 		return error("can't get secret")
// 	}
// 	return secret
// }

// // show a UI in console to configure the secret
// pub fn (mut self Context) secret_configure() ! {
// 	mut myui := ui.new()!
// 	console.clear()
// 	secret_ := myui.ask_question(question: 'Please enter your hero secret string:')!
// 	self.secret_set(secret_)!
// }

// // unhashed secret
// pub fn (mut self Context) secret_set(secret_ string) ! {
// 	secret := secret_.trim_space()
// 	secret2 := md5.hexhash(secret)
// 	self.config.secret = secret2
// 	self.save()!
// }

pub fn (mut self Context) path() !pathlib.Path {
	return self.path_ or {
		path2 := '${os.home_dir()}/hero/context/${self.config.name}'
		mut path := pathlib.get_dir(path: path2, create: false)!
		path
	}
}
