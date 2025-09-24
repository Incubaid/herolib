module gittools

import json

@[params]
pub struct GitStructureConfig {
pub mut:
	light        bool = true // If true, clones only the last history for all branches (clone with only 1 level deep)
	ssh_key_name string
	ssh_key_path string
}

// Load config from redis
pub fn (mut self GitStructure) config() !GitStructureConfig {
	mut config := self.config_ or {
		mut redis := redis_get()
		data := redis.get('${self.cache_key()}:config')!
		mut c := GitStructureConfig{}
		if data.len > 0 {
			c = json.decode(GitStructureConfig, data)!
		}
		c
	}

	return config
}

pub fn (mut self GitStructure) config_set(args GitStructureConfig) ! {
	mut redis := redis_get()
	redis.set('${self.cache_key()}:config', json.encode(args))!
}

// Reset the configuration cache for Git structures.
fn (mut self GitStructure) config_reset() ! {
	mut redis := redis_get()
	redis.del('${self.cache_key()}:config')!
}

// save to the cache
fn (mut self GitStructure) config_save() ! {
	// Retrieve the configuration from Redis.
	mut redis := redis_get()
	datajson := json.encode(self.config()!)
	redis.set('${self.cache_key()}:config', datajson)!
}
