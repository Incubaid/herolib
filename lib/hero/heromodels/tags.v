module heromodels

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_true }
import freeflowuniverse.herolib.hero.user { UserRef }
import json

// Tags represents a collection of tag names with a unique ID
// This is the same as db.Tags but in the heromodels context
pub type Tags = db.Tags

pub fn (self Tags) type_name() string {
	return 'tags'
}

// return example rpc call and result for each methodname
pub fn (self Tags) example(methodname string) (string, string) {
	match methodname {
		'get' {
			return '{"id": 1}', '{"id": 1, "names": ["development", "urgent", "team"], "md5": "abc123def456"}'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub struct DBTags {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (mut self DBTags) get(id u32) !Tags {
	if id == 0 {
		return error('Tags ID cannot be 0')
	}

	// Get the full Tags entity to include md5
	tags_json := self.db.redis.hget('db:tags', id.str())!
	if tags_json == '' {
		return error('Tags entity not found for ID: ${id}')
	}

	// Decode Tags entity
	tags_entity := json.decode(Tags, tags_json)!
	return tags_entity
}

pub fn (mut self DBTags) exist(id u32) !bool {
	if id == 0 {
		return false
	}

	tags_json := self.db.redis.hget('db:tags', id.str()) or { '' }
	return tags_json != ''
}

pub fn (mut self DBTags) delete(id u32) !bool {
	if id == 0 {
		return false
	}

	// Get the Tags entity first to get the md5 hash
	tags_json := self.db.redis.hget('db:tags', id.str()) or { '' }
	if tags_json == '' {
		return false // Already doesn't exist
	}

	tags_entity := json.decode(Tags, tags_json)!

	// Delete from both hash tables
	self.db.redis.hdel('db:tags', id.str())!
	self.db.redis.hdel('db:tags_hash', tags_entity.md5)!

	return true
}

pub fn tags_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.tags.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'exist' {
			id := db.decode_u32(params)!
			exists := f.tags.exist(id)!
			if exists {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'delete' {
			id := db.decode_u32(params)!
			deleted := f.tags.delete(id)!
			if deleted {
				return new_response_true(rpcid)
			} else {
				return new_error(rpcid,
					code:    404
					message: 'Tags with ID ${id} not found'
				)
			}
		}
		else {
			return new_error(rpcid,
				code:    -32601
				message: 'Method not found: ${method}'
			)
		}
	}
}
