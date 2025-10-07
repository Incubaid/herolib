module db

import crypto.md5
import json

pub fn (mut self DB) tags_get(tags []string) !u32 {
	if tags.len == 0 {
		return 0
	}

	mut tags_fixed := tags.map(it.to_lower_ascii().replace(' ', '_')).filter(it != '')
	tags_fixed.sort_ignore_case()

	hash := md5.hexhash(tags_fixed.join(','))
	tags_id_str := self.redis.hget('db:tags_hash', hash) or { '' }

	if tags_id_str != '' {
		// Return existing Tags ID
		return tags_id_str.u32()
	}

	// Generate new ID for Tags entity
	tags_id := self.new_id()!
	tags_entity := Tags{
		id:    tags_id
		names: tags_fixed
		md5:   hash
	}

	// Store Tags entity in Redis as JSON
	tags_json := json.encode(tags_entity)
	self.redis.hset('db:tags', tags_id.str(), tags_json)!
	self.redis.hset('db:tags_hash', hash, tags_id.str())!

	return tags_id
}

// Get tag names from Tags ID
pub fn (mut self DB) tags_from_id(tags_id u32) ![]string {
	if tags_id == 0 {
		return []string{}
	}

	// Get Tags entity from Redis
	tags_json := self.redis.hget('db:tags', tags_id.str())!
	if tags_json == '' {
		return error('Tags entity not found for ID: ${tags_id}')
	}

	// Decode Tags entity
	tags_entity := json.decode(Tags, tags_json)!
	return tags_entity.names
}
