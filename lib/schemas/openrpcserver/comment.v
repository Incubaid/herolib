module openrpcserver

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime


@[heap]
pub struct Comment {
pub mut:
    id           u32
    comment         string
    parent u32 //id of parent comment if any, 0 means none
    updated_at   i64
    author      u32 //links to user
}

pub fn (self Comment) type_name() string {
    return 'comments'
}

pub fn (self Comment) load(data []u8) !Comment {
    return comment_load(data)!
}

pub fn (self Comment) dump() ![]u8{
    // Create a new encoder
    mut e := encoder.new()
    e.add_u8(1)
    e.add_u32(self.id)
    e.add_string(self.comment)
    e.add_u32(self.parent)
    e.add_i64(self.updated_at)
    e.add_u32(self.author)
    return e.data
}


pub fn comment_load(data []u8) !Comment{
    // Create a new decoder
    mut e := encoder.decoder_new(data)
    version := e.get_u8()!
    if version != 1 {
        panic("wrong version in comment load")
    }
    mut comment := Comment{}
    comment.id = e.get_u32()!
    comment.comment = e.get_string()!
    comment.parent = e.get_u32()!
    comment.updated_at = e.get_i64()!
    comment.author = e.get_u32()!
    return comment
}


pub struct CommentArg {
pub mut:
    comment string
    parent u32
    author u32
}

pub fn comment_multiset(args []CommentArg) ![]u32 {
    return comments2ids(args)!
}

pub fn comments2ids(args []CommentArg) ![]u32 {
    return args.map(comment2id(it.comment)!)
}

pub fn comment2id(comment string) !u32 {
    comment_fixed := comment.to_lower_ascii().trim_space()
    mut redis := redisclient.core_get()!
    return if comment_fixed.len > 0{
        hash := md5.hexhash(comment_fixed)
        comment_found := redis.hget("db:comments", hash)!
        if comment_found == ""{            
            id := u32(redis.incr("db:comments:id")!)
            redis.hset("db:comments", hash, id.str())!
            redis.hset("db:comments", id.str(), comment_fixed)!
            id
        }else{
            comment_found.u32()
        }
    } else { 0 }
}


//get new comment, not from the DB
pub fn comment_new(args CommentArg) !Comment{
    mut o := Comment {
        comment: args.comment
        parent: args.parent
        updated_at: ourtime.now().unix()
        author: args.author
    }
    return o
}

pub fn comment_multiset(args []CommentArg) ![]u32{
    mut ids := []u32{}
    for comment in args {
        ids << comment_set(comment)!
    }
    return ids
}

pub fn comment_set(args CommentArg) !u32{
    mut o := comment_new(args)!
    // Use openrpcserver set function which now returns the ID
    return openrpcserver.set[Comment](mut o)!
}

pub fn comment_exist(id u32) !bool{
    return openrpcserver.exists[Comment](id)!
}

pub fn comment_get(id u32) !Comment{
    return openrpcserver.get[Comment](id)!
}
