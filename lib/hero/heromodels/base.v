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
    comments     []u32
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

pub fn comments2id(comments []CommentArg) !u32 {
    mut myid:=0
    if comments.len>0{
        mycomments:=comments.map(it.to_lower_ascii().trim_space()).sort().join(",")
        mymd5:=crypto.hexhash(mycomments)
        comments:=redis.hget("db:comments", mymd5)!
        if comments == ""{            
            myid = u32(redis.incr("db:comments:id")!)
            redis.hset("db:comments", mymd5, myid)!
            redis.hset("db:comments", myid, mycomments)!
        }else{
            myid = comments.int()
        }
    }
    return myid
}


    // Convert CommentArg array to u32 array
    mut comment_ids := []u32{}
    for comment in args.comments {
        comment_ids << comment_set(comment)!
    }
