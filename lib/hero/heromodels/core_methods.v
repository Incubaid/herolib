module heromodels

import freeflowuniverse.herolib.core.redisclient

pub fn set[T](obj T) ! {
    mut redis := redisclient.core_get()!
    id := obj.id
    data := obj.dump()!
    redis.hset("db:${name}",id,data)!
}

pub fn get[T](id u32) !T {
    mut redis := redisclient.core_get()!
    data := redis.hget("db:${name}",id)!
    t := T{}
    return t.load(data)!
}

pub fn exists[T](id u32) !bool {
    name := T{}.type_name()
    mut redis := redisclient.core_get()!
    return redis.hexists("db:${name}",id)!
}

pub fn delete[T](id u32) ! {
    name := T{}.type_name()
    mut redis := redisclient.core_get()!
    redis.hdel("db:${name}", id.str())!
}

pub fn list[T]() ![]T {
    mut redis := redisclient.core_get()!
    ids := redis.hkeys("db:${name}")!
    mut result := []T{}
    for id in ids {
        result << get[T](id.u32())!
    }
    return result
}

//make it easy to get a base object
pub fn new_from_base[T](args BaseArgs) !Base {
    return T { Base: new_base(args)! }
}