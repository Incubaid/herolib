module heromodels

import crypto.md5
import json

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.data.encoder


pub fn [T] set(obj T) !Base {
    //todo: get the dump() from the obj , save the 
    mut redis := redisclient.core_get()!

    data := obj.dump()

    redis.hset("db:${name}",id,data)!

}

pub fn [T] get(id u32) !T {
    //todo: get the dump() from the obj , save the 
    mut redis := redisclient.core_get()!

    data := redis.hget("db:${name}",id)!

    obj:=$name_load(data) or { 
        return error("could not load ${name} from data")
    }

    return obj
}

pub fn [T] exists(id u32) !T {
    //todo: get the dump() from the obj , save the 
    mut redis := redisclient.core_get()!

    return redis.hexists("db:${name}",id)!

    return obj
}

pub fn [T] delete(id u32) !T {
    //todo: get the dump() from the obj , save the 
    mut redis := redisclient.core_get()!

    return redis.hdel("db:${name}",id)!

    return obj
}



//make it easy to get a base object
pub fn [T] new_from_base(args BaseArgs) !T {

    mut redis := redisclient.core_get()!

    commentids:=comment_multiset(args.comments)!
    tags:=tags2id(args.tags)!

    return T{
        id: args.id or { 0 }
        name: args.name
        description: args.description
        created_at: ourtime.now().unix()
        updated_at: ourtime.now().unix()
        securitypolicy: args.securitypolicy or { 0 }
        tags: tags
        comments: commentids)
    }
}