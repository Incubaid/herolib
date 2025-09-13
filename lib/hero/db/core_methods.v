module db

import freeflowuniverse.herolib.data.ourtime

pub fn (mut self DB) set[T](obj_ T) !u32 {
	// Get the next ID	
	mut obj := obj_
	if obj.id == 0 {
		obj.id = self.new_id()!
	}
	mut t := ourtime.now().unix()
	if obj.created_at == 0 {
		obj.created_at = t
	}
	obj.updated_at = t

	data := obj.dump()!
	self.redis.hset(self.db_name[T](), obj.id.str(), data.bytestr())!
	return obj.id
}

// return the data, cannot return the object as we do not know the type
pub fn (mut self DB) get_data[T](id u32) ![]u8 {
	data := self.redis.hget(self.db_name[T](), id.str())!
	return data.bytes()
}

pub fn (mut self DB) exists[T](id u32) !bool {
	return self.redis.hexists(self.db_name[T](), id.str())!
}

pub fn (mut self DB) delete[T](id u32) ! {
	self.redis.hdel(self.db_name[T](), id.str())!
}

pub fn (mut self DB) list[T]() ![]u32 {
	ids := self.redis.hkeys(self.db_name[T]())!
	return ids.map(it.u32())
}

// make it easy to get a base object
pub fn (mut self DB) new_from_base[T](args BaseArgs) !Base {
	return T{
		Base: new_base(args)!
	}
}

fn (mut self DB) db_name[T]() string {
	return 'db:${T.name}'
}

pub fn (mut self DB) new_id() !u32 {
	return u32(self.redis.incr('db:id')!)
}
