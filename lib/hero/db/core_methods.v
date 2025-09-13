module db

import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.data.encoder

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

	// id             u32
	// name           string
	// description    string
	// created_at     i64
	// updated_at     i64
	// securitypolicy u32
	// tags           u32 // when we set/get we always do as []string but this can then be sorted and md5ed this gies the unique id of tags
	// comments       []u32
	mut e := encoder.new()
	e.add_u8(1)
	e.add_u32(obj.id)
	e.add_string(obj.name)
	e.add_string(obj.description)
	e.add_i64(obj.created_at)
	e.add_i64(obj.updated_at)
	e.add_u32(obj.securitypolicy)
	e.add_u32(obj.tags)
	e.add_u16(u16(obj.comments.len))
	for comment in obj.comments {
		e.add_u32(comment)
	}
	println('aaaa: ${e.data.len} - ${obj.dump()!.len}')
	e.data << obj.dump()!
	println('bbbb: ${e.data.len} - ${obj.dump()!.len}')
	self.redis.hset(self.db_name[T](), obj.id.str(), e.data.bytestr())!
	return obj.id
}

// return the data, cannot return the object as we do not know the type
pub fn (mut self DB) get_data[T](id u32) !(T, []u8) {
	data := self.redis.hget(self.db_name[T](), id.str())!

	if data.len == 0 {
		return error('herodb:${self.db_name[T]()} not found for ${id}')
	}

	mut e := encoder.decoder_new(data.bytes())
	version := e.get_u8()!
	if version != 1 {
		panic('wrong version in base load')
	}
	mut base := T{}
	base.id = e.get_u32()!
	base.name = e.get_string()!
	base.description = e.get_string()!
	base.created_at = e.get_i64()!
	base.updated_at = e.get_i64()!
	base.securitypolicy = e.get_u32()!
	base.tags = e.get_u32()!
	for _ in 0 .. e.get_u16()! {
		base.comments << e.get_u32()!
	}
	return base, e.data
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
