module openrpcserver

import crypto.md5
import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.data.ourtime

// Group represents a collection of users with roles and permissions
@[heap]
pub struct Base {
pub mut:
	id             u32
	name           string
	description    string
	created_at     i64
	updated_at     i64
	securitypolicy u32
	tags           u32 // when we set/get we always do as []string but this can then be sorted and md5ed this gies the unique id of tags
	comments       []u32
}

@[heap]
pub struct SecurityPolicy {
pub mut:
	id     u32
	read   []u32 // links to users & groups
	write  []u32 // links to users & groups
	delete []u32 // links to users & groups
	public bool
	md5    string // this sorts read, write and delete u32 + hash, then do md5 hash, this allows to go from a random read/write/delete/public config to a hash
}

@[heap]
pub struct Tags {
pub mut:
	id    u32
	names []string // unique per id
	md5   string   // of sorted names, to make easy to find unique id, each name lowercased and made ascii
}

/////////////////

@[params]
pub struct BaseArgs {
pub mut:
	id             ?u32
	name           string
	description    string
	securitypolicy ?u32
	tags           []string
	comments       []CommentArg
}

// make it easy to get a base object
pub fn new_base(args BaseArgs) !Base {
	mut redis := redisclient.core_get()!

	commentids := comment_multiset(args.comments)!
	tags := tags2id(args.tags)!

	return Base{
		id:             args.id or { 0 }
		name:           args.name
		description:    args.description
		created_at:     ourtime.now().unix()
		updated_at:     ourtime.now().unix()
		securitypolicy: args.securitypolicy or { 0 }
		tags:           tags
		comments:       commentids
	}
}

pub fn tags2id(tags []string) !u32 {
	mut redis := redisclient.core_get()!
	return if tags.len > 0 {
		mut tags_fixed := tags.map(it.to_lower_ascii().trim_space()).filter(it != '')
		tags_fixed.sort_ignore_case()
		hash := md5.hexhash(tags_fixed.join(','))
		tags_found := redis.hget('db:tags', hash)!
		return if tags_found == '' {
			id := u32(redis.incr('db:tags:id')!)
			redis.hset('db:tags', hash, id.str())!
			redis.hset('db:tags', id.str(), tags_fixed.join(','))!
			id
		} else {
			tags_found.u32()
		}
	} else {
		0
	}
}
