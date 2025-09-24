module base

import freeflowuniverse.herolib.data.ourtime
// import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.data.paramsparser
import freeflowuniverse.herolib.core.logger
import json
import freeflowuniverse.herolib.core.pathlib
// import freeflowuniverse.herolib.develop.gittools
// import freeflowuniverse.herolib.ui.console

@[heap]
pub struct Session {
mut:
	path_   ?pathlib.Path
	logger_ ?logger.Logger
pub mut:
	name        string // unique id for session (session id), can be more than one per context
	interactive bool = true
	params      paramsparser.Params
	start       ourtime.OurTime
	end         ourtime.OurTime
	context     &Context @[skip; str: skip]
	config      SessionConfig
	env         map[string]string
}

///////// LOAD & SAVE

// fn (mut self Session) key() string {
// 	return 'hero:sessions:${self.guid()}'
// }

// load the params from redis
pub fn (mut self Session) load() ! {
	mut r := self.context.redis()!
	rkey := 'sessions:config:${self.name}'
	mut datajson := r.get(rkey)!
	if datajson == '' {
		return error("can't find session with name ${self.name}")
	}
	self.config = json.decode(SessionConfig, datajson)!
	self.params = paramsparser.new(self.config.params)!
}

// save the params to redis
pub fn (mut self Session) save() ! {
	self.check()!
	rkey := 'sessions:config:${self.name}'
	mut r := self.context.redis()!
	self.config.params = self.params.str()
	config_json := json.encode(self.config)
	r.set(rkey, config_json)!
}

// Set an environment variable
pub fn (mut self Session) env_set(key string, value string) ! {
	self.env[key] = value
	self.save()!
}

pub fn (mut self Session) env_set_once(key string, value string) ! {
	if key in self.env {
		return error("env variable '${key}' already exists in session '${self.name}'")
	}
	self.env_set(key, value)!
}

// Get an environment variable
pub fn (mut self Session) env_get(key string) !string {
	return self.env[key] or { return error("can't find env in session ${self.name}") }
}

// Delete an environment variable
pub fn (mut self Session) env_delete(key string) {
	self.env.delete(key)
}

////////// REPRESENTATION

pub fn (self Session) check() ! {
	if self.name.len < 3 {
		return error('name should be at least 3 char')
	}
}

pub fn (self Session) guid() string {
	return '${self.context.guid()}:${self.name}'
}

pub fn (mut self Session) path() !pathlib.Path {
	return self.path_ or {
		path2 := '${self.context.path()!.path}/${self.name}'
		mut path := pathlib.get_dir(path: path2, create: true)!
		path
	}
}

fn (self Session) str2() string {
	mut out := 'session:${self.guid()}'
	out += ' start:\'${self.start}\''
	if !self.end.empty() {
		out += ' end:\'${self.end}\''
	}
	return out
}
