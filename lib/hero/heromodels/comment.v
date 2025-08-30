module heromodels

import crypto.md5
import json

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.data.encoder


@[heap]
pub struct Comment {
pub mut:
    id           u32
    comment         string
    parent u32 //id of parent comment if any, 0 means none
    updated_at   i64
    author      u32 //links to user
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


pub fn comment_load(self []u8) !Comment{
    // Create a new encoder
    mut e := decoder.new()
    version:=e.get_u8(1)
    if version != 1 {
        panic("wrong version in comment load")
    }
    self.id = e.get_u32()
    self.comment = e.get_string()
    self.parent = e.get_u32()
    self.updated_at = e.get_i64()
    self.author = e.get_u32()
    return e.data
}


pub struct CommentArg {
pub mut:
    comment         string
    parent u32 //id of parent comment if any, 0 means none
    author      u32 //links to user
}

//get new comment, not our of db
pub fn comment_new(args CommentArg) !Comment{
    mut o:=Comment {
        comment: args.comment
        parent:args.parent
        updated_at: ourtime.now().unix()
        author: args.author
    }
    return o
}    

pub fn comment_set(o Comment) !u32{
    mut redis := redisclient.core_get()!
    myid := redis.incr("db:comments:id")!
    i.id = myid
    data:=o.dump()!
    redis.hset("db:comments:data", myid, data)!
    return myid
}

pub fn comment_exist(id u32) !bool{
    mut redis := redisclient.core_get()!
    return redis.hexist("db:comments",id)!
}

pub fn comment_get(id u32) !Comment{
    mut redis := redisclient.core_get()!
    mut data:= redis.hget("db:comments",id)!
    if data.len>0{
        return comment_load(data)!
    }else{
        return error("Can't find comment with id: ${id}")
    }
    
}
