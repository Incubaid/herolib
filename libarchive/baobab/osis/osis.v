module osis

import os

pub fn (mut o OSIS) generic_new[T](obj T) !u32 {
	id := o.indexer.generic_new[T](obj)!
	o.storer.generic_new[T](obj)!
	return id
}

pub fn (mut o OSIS) new[T](obj T) !u32 {
	id := o.storer.new_generic[T](obj)!
	o.indexer.new_generic[T](id, obj)!
	return id
}

pub fn (mut o OSIS) generic_get[T](id u32) !T {
	return o.storer.generic_get[T](id)!
}

pub fn (mut o OSIS) get[T](id u32) !T {
	return o.storer.generic_get[T](u32(id))!
}

pub fn (mut o OSIS) generic_set[T](obj T) ! {
	o.indexer.generic_set[T](obj) or { return error('Failed to set new indices:\n${err}') }
	o.storer.generic_set[T](obj)!
}

pub fn (mut o OSIS) generic_delete[T](id u32) ! {
	o.indexer.generic_delete[T](id)!
	o.storer.generic_delete[T](id)!
}

pub fn (mut o OSIS) delete(id u32) ! {
	o.storer.delete(u32(id))!
}

pub fn (mut o OSIS) list[T]() ![]T {
	panic('implement')
	// ids := o.indexer.generic_list[T]()!
	// return o.storer.generic_list[T](ids)!
}

pub fn (mut o OSIS) generic_list[T]() ![]T {
	ids := o.indexer.generic_list[T]()!
	return o.storer.generic_list[T](ids)!
}

pub fn (mut o OSIS) generic_filter[T, D](filter D, params FilterParams) ![]T {
	ids := o.indexer.generic_filter[T, D](filter, params)!
	return o.storer.generic_list[T](ids)!
}

pub fn (mut o OSIS) generic_reset[T]() ! {
	o.indexer.generic_reset[T]()!
	o.storer.generic_reset[T]()!
}
