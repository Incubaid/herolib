module heroprompt

import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.core.playbook { PlayBook }
import json

__global (
	heroprompt_global  shared map[string]&HeroPrompt
	heroprompt_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default' // HeroPrompt instance name
	fromdb bool // Load from Redis (default: false, uses in-memory cache)
	create bool // Create if doesn't exist (default: false, returns error if not found)
	reset  bool // Delete and recreate if exists (default: false)
}

// get retrieves or creates a HeroPrompt instance
// This is the main entry point for accessing HeroPrompt instances
pub fn get(args ArgsGet) !&HeroPrompt {
	mut context := base.context()!
	mut r := context.redis()!

	// Handle reset: delete existing instance and create fresh
	if args.reset {
		// Delete from Redis and memory
		r.hdel('context:heroprompt', args.name) or {}
		lock heroprompt_global {
			heroprompt_global.delete(args.name)
		}

		// Create new instance
		mut obj := HeroPrompt{
			name: args.name
		}
		set(obj)!
		return get(name: args.name)! // Recursive call to load the new instance
	}

	// Check if we need to load from DB
	needs_load := rlock heroprompt_global {
		args.fromdb || args.name !in heroprompt_global
	}

	if needs_load {
		heroprompt_default = args.name

		if r.hexists('context:heroprompt', args.name)! {
			// Load existing instance from Redis
			data := r.hget('context:heroprompt', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('HeroPrompt with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(HeroPrompt, data)!
			set_in_mem(obj)!
		} else {
			// Instance doesn't exist in Redis
			if args.create {
				// Create new instance
				mut obj := HeroPrompt{
					name: args.name
				}
				set(obj)!
			} else {
				print_backtrace()
				return error("HeroPrompt with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // Recursive call to return the instance
	}

	// Return from in-memory cache
	return rlock heroprompt_global {
		heroprompt_global[args.name] or {
			print_backtrace()
			return error('could not get config for heroprompt with name: ${args.name}')
		}
	}
}

// register the config for the future
pub fn set(o HeroPrompt) ! {
	mut o2 := set_in_mem(o)!
	heroprompt_default = o2.name

	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:heroprompt', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:heroprompt', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:heroprompt', args.name)!

	// Also remove from memory
	lock heroprompt_global {
		heroprompt_global.delete(args.name)
	}
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&HeroPrompt {
	mut res := []&HeroPrompt{}
	mut context := base.context()!

	if args.fromdb {
		// reset what is in mem
		lock heroprompt_global {
			heroprompt_global = map[string]&HeroPrompt{}
		}
		heroprompt_default = ''

		mut r := context.redis()!
		mut l := r.hkeys('context:heroprompt')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		rlock heroprompt_global {
			for _, client in heroprompt_global {
				res << client
			}
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o HeroPrompt) !HeroPrompt {
	mut o2 := obj_init(o)!

	// Restore parent references for all workspaces AFTER storing in global
	// This ensures the parent pointer points to the actual instance in memory
	lock heroprompt_global {
		heroprompt_global[o2.name] = &o2

		// Now restore parent references using the stored instance
		mut stored := heroprompt_global[o2.name] or {
			return error('failed to store heroprompt instance in memory')
		}
		for _, mut ws in stored.workspaces {
			ws.parent = stored
		}
	}
	heroprompt_default = o2.name

	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'heroprompt.') {
		return
	}
	mut install_actions := plbook.find(filter: 'heroprompt.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}
}

// switch instance to be used for heroprompt
pub fn switch(name string) {
}
