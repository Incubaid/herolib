module db

import crypto.md5

pub fn (mut self DB) tags_get(tags []string) !u32 {
	return if tags.len > 0 {
		mut tags_fixed := tags.map(it.to_lower_ascii().trim_space()).filter(it != '')
		tags_fixed.sort_ignore_case()
		hash := md5.hexhash(tags_fixed.join(','))
		tags_found := self.redis.hget('db:tags', hash)!
		return if tags_found == '' {
			id := self.new_id()!
			self.redis.hset('db:tags', hash, id.str())!
			self.redis.hset('db:tags', id.str(), tags_fixed.join(','))!
			id
		} else {
			tags_found.u32()
		}
	} else {
		0
	}
}
