module db

import crypto.md5

@[params]
pub struct CommentArg {
pub mut:
	comment string
	parent  u32
	author  u32
}

pub fn (mut self DB) comments_get(args []CommentArg) ![]u32 {
	return args.map(self.comment_get(it.comment)!)
}

pub fn (mut self DB) comment_get(comment string) !u32 {
	comment_fixed := comment.to_lower_ascii().trim_space()
	return if comment_fixed.len > 0 {
		hash := md5.hexhash(comment_fixed)
		comment_found := self.redis.hget('db:comments', hash)!
		if comment_found == '' {
			id := self.new_id()!
			self.redis.hset('db:comments', hash, id.str())!
			self.redis.hset('db:comments', id.str(), comment_fixed)!
			id
		} else {
			comment_found.u32()
		}
	} else {
		0
	}
}
