module heromodels

import crypto.md5
import json

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.data.encoder



// Group represents a collection of users with roles and permissions
@[heap]
pub struct Base {
pub mut:
    id           u32
    name         string
    description  string
    created_at   i64
    updated_at   i64
    securitypolicy u32
    tags         u32 //when we set/get we always do as []string but this can then be sorted and md5ed this gies the unique id of tags
    comments []u32
}


 
@[heap]
pub struct SecurityPolicy {å
pub mut:
    id           u32
    read      []u32 //links to users & groups
    write     []u32 //links to users & groups
    delete    []u32 //links to users & groups
    public bool
    md5 string //this sorts read, write and delete u32 + hash, then do md5 hash, this allows to go from a random read/write/delete/public config to a hash
}


@[heap]
pub struct Tags {
pub mut:
    id           u32
    names       []string //unique per id
    md5         string //of sorted names, to make easy to find unique id, each name lowercased and made ascii
}
    

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


/////////////////

@[params]
pub struct BaseArgs {
pub mut:
    id           ?u32
    name         string
    description  string
    securitypolicy ?u32
    tags         []string
    comments []CommentArg
}

pub struct CommentArg {
pub mut:
    comment         string
    parent u32 //id of parent comment if any, 0 means none
    author      u32 //links to user
}

pub fn tags2id(tags []string) !u32 {
    mut myid:=0
    if tags.len>0{
        mytags:=tags.map(it.to_lower_ascii().trim_space()).sort().join(",")
        mymd5:=crypto.hexhash(mytags)
        tags:=redis.hget("db:tags", mymd5)!
        if tags == ""{            
            myid = u32(redis.incr("db:tags:id")!)
            redis.hset("db:tags", mymd5, myid)!
            redis.hset("db:tags", myid, mytags)!
        }else{
            myid = tags.int()
        }
    }
    return myid
}

pub fn comment2id(args CommentArg) !u32{
    myid := redis.incr("db:comments:id")!
    mut o:=Comment {
        id: 
        comment: args.comment
        parent:args.parent
        updated_at: ourtime.now().unix()
        author: args.author
    }
    data:=o.dump()!
    redis.hset("db:comments:data", myid, data)!
    return myid
}


pub fn [T] new(args BaseArgs) Base {

    mut redis := redisclient.core_get()!

    redis.hget("db:comments")

    return T{
        id: args.id or { 0 }
        name: args.name
        description: args.description
        created_at: ourtime.now().unix()
        updated_at: ourtime.now().unix()
        securitypolicy: args.securitypolicy or { 0 }
        tags: args.tags
        comments: args.comments.map(it.to_base())
    }
}