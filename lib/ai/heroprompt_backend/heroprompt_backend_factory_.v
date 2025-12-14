//! HeropromptBackend Factory Module
//!
//! Factory functions for creating and managing HeropromptBackend instances
//! with Redis-based persistence.
module heroprompt_backend

import json
import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }

// Global instance cache
__global (
	heroprompt_backend_global  map[string]&HeropromptBackend
	heroprompt_backend_default string
)

const redis_key = 'context:heroprompt_backend'

// GetArgs specifies options for retrieving a backend instance.
@[params]
pub struct GetArgs {
pub mut:
	name   string = 'default'
	fromdb bool   // Force load from Redis
	create bool   // Create if not exists
}

// new creates a new HeropromptBackend instance.
pub fn new(args GetArgs) !&HeropromptBackend {
	obj := HeropromptBackend{name: args.name}
	set(obj)!
	return get(name: args.name)!
}

// get retrieves a HeropromptBackend instance by name.
pub fn get(args GetArgs) !&HeropromptBackend {
	heroprompt_backend_default = args.name

	// Return from cache if available
	if !args.fromdb && args.name in heroprompt_backend_global {
		return heroprompt_backend_global[args.name] or {
			return error('Failed to get cached instance: ${args.name}')
		}
	}

	// Load from Redis
	mut ctx := base.context()!
	mut r := ctx.redis()!

	if r.hexists(redis_key, args.name)! {
		data := r.hget(redis_key, args.name)!
		if data.len == 0 {
			return error('HeropromptBackend "${args.name}" has empty data')
		}
		obj := json.decode(HeropromptBackend, data)!
		set_in_mem(obj)!
		return get(name: args.name)!
	}

	// Create if requested
	if args.create {
		return new(args)!
	}

	return error('HeropromptBackend "${args.name}" does not exist')
}

// set persists a HeropromptBackend instance to Redis.
pub fn set(o HeropromptBackend) ! {
	o2 := set_in_mem(o)!
	heroprompt_backend_default = o2.name

	mut ctx := base.context()!
	mut r := ctx.redis()!
	r.hset(redis_key, o2.name, json.encode(o2))!
}

// exists checks if a HeropromptBackend instance exists in Redis.
pub fn exists(args GetArgs) !bool {
	mut ctx := base.context()!
	mut r := ctx.redis()!
	return r.hexists(redis_key, args.name)!
}

// delete removes a HeropromptBackend instance from Redis.
pub fn delete(args GetArgs) ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!
	r.hdel(redis_key, args.name)!
	heroprompt_backend_global.delete(args.name)
}

// ListArgs specifies options for listing instances.
@[params]
pub struct ListArgs {
pub mut:
	fromdb bool // Force reload from Redis
}

// list returns all HeropromptBackend instances.
pub fn list(args ListArgs) ![]&HeropromptBackend {
	if args.fromdb {
		heroprompt_backend_global.clear()
		heroprompt_backend_default = ''

		mut ctx := base.context()!
		mut r := ctx.redis()!
		names := r.hkeys(redis_key)!

		mut result := []&HeropromptBackend{}
		for name in names {
			result << get(name: name, fromdb: true)!
		}
		return result
	}

	mut result := []&HeropromptBackend{}
	for _, client in heroprompt_backend_global {
		result << client
	}
	return result
}

// set_in_mem stores an instance in the memory cache.
fn set_in_mem(o HeropromptBackend) !HeropromptBackend {
	heroprompt_backend_global[o.name] = &o
	heroprompt_backend_default = o.name
	return o
}

// play executes HeroScript playbook actions.
pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'heroprompt_backend.') {
		return
	}

	for mut action in plbook.find(filter: 'heroprompt_backend.configure')! {
		obj := heroscript_loads(action.heroscript())!
		set(obj)!
		action.done = true
	}
}

// save persists this instance to Redis.
pub fn (self &HeropromptBackend) save() ! {
	set(*self)!
}

// reload refreshes this instance from Redis.
pub fn (mut self HeropromptBackend) reload() ! {
	backend := get(name: self.name, fromdb: true)!
	self = *backend
}
