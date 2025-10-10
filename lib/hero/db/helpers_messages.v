module db

import crypto.md5

@[params]
pub struct MessageArg {
pub mut:
	message string
	parent  u32
	author  u32
}

pub fn (mut self DB) messages_get(args []MessageArg) ![]u32 {
	return args.map(self.message_get(it.message)!)
}

pub fn (mut self DB) message_get(message string) !u32 {
	message_fixed := message.to_lower_ascii().trim_space()
	return if message_fixed.len > 0 {
		hash := md5.hexhash(message_fixed)
		message_found := self.redis.hget('db:messages', hash)!
		if message_found == '' {
			id := self.new_id()!
			self.redis.hset('db:messages', hash, id.str())!
			self.redis.hset('db:messages', id.str(), message_fixed)!
			id
		} else {
			message_found.u32()
		}
	} else {
		0
	}
}
