module db

import crypto.md5

// @[params]
// pub struct BaseArgs {
// pub mut:
// 	id             ?u32
// 	name           string
// 	description    string
// 	securitypolicy ?u32
// 	tags           []string
// 	comments       []u32
// }

// // make it easy to get a base object
// pub fn (mut self DB) new_base(args BaseArgs) !Base {
// 	mut redis := redisclient.core_get()!

// 	tags := tags2id(args.tags)!

// 	return Base{
// 		id:             args.id or { 0 }
// 		name:           args.name
// 		description:    args.description
// 		created_at:     ourtime.now().unix()
// 		updated_at:     ourtime.now().unix()
// 		securitypolicy: args.securitypolicy or { 0 }
// 		tags:           tags
// 		comments:       args.comments
// 	}
// }

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
