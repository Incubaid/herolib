module openrpcserver

import incubaid.herolib.core.redisclient

pub fn set[T](mut obj T) !u32 {
	name := T{}.type_name()
	mut redis := redisclient.core_get()!

	// Generate ID if not set
	if obj.id == 0 {
		myid := redis.incr('db:${name}:id')!
		obj.id = u32(myid)
	}

	data := obj.dump()!
	redis.hset('db:${name}', obj.id.str(), data.bytestr())!
	return obj.id
}

pub fn get[T](id u32) !T {
	name := T{}.type_name()
	mut redis := redisclient.core_get()!
	data := redis.hget('db:${name}', id.str())!
	if data.len > 0 {
		return T{}.load(data.bytes())!
	} else {
		return error("Can't find ${name} with id: ${id}")
	}
}

pub fn exists[T](id u32) !bool {
	name := T{}.type_name()
	mut redis := redisclient.core_get()!
	return redis.hexists('db:${name}', id.str())!
}

pub fn delete[T](id u32) ! {
	name := T{}.type_name()
	mut redis := redisclient.core_get()!
	redis.hdel('db:${name}', id.str())!
}

pub fn list[T]() ![]T {
	name := T{}.type_name()
	mut redis := redisclient.core_get()!
	all_data := redis.hgetall('db:${name}')!
	mut result := []T{}
	for _, data in all_data {
		result << T{}.load(data.bytes())!
	}
	return result
}

// make it easy to get a base object
pub fn new_from_base[T](args BaseArgs) !Base {
	return T{
		Base: new_base(args)!
	}
}
