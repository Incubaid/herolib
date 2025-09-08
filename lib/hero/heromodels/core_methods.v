module heromodels

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.data.encoder

pub fn set[T](mut obj_ T) !u32 {
    // mut obj_ := T{...obj}
    mut redis := redisclient.core_get()!
    id := u32(redis.llen(db_name[T]())!)
    obj_.id = id
    // data := encoder.encode(obj_)!
    redis.hset(db_name[T](),id.str(),'data.bytestr()')!
    return id
}

pub fn get[T](id u32) !T {
    mut redis := redisclient.core_get()!
    data := redis.hget(db_name[T](),id.str())!
    t := T{}
    return encoder.decode[T](data.bytes())!
}

pub fn exists[T](id u32) !bool {
    mut redis := redisclient.core_get()!
    return redis.hexists(db_name[T](),id.str())!
}

pub fn delete[T](id u32) ! {
    mut redis := redisclient.core_get()!
    redis.hdel(db_name[T](), id.str())!
}

pub fn list[T]() ![]T {
    mut redis := redisclient.core_get()!
    ids := redis.hkeys(db_name[T]())!
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

fn db_name[T]() string {
    return "db:${T.name}"
}