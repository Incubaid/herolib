module osis

import json

// new creates a new root object entry in the root_objects table,
// and the table belonging to the type of root object with columns for index fields
pub fn (mut storer Storer) new_generic[T](obj T) !u32 {
	data := json.encode(obj).bytes()
	return storer.db.set(data: data)
}

pub fn (mut storer Storer) generic_get[T](id u32) !T {
	return json.decode(T, storer.db.get(id)!.bytestr())
}

pub fn (mut storer Storer) generic_set[T](obj T) ! {
	data := json.encode(obj).bytes()
	return storer.db.set(data: data)
}

pub fn (mut storer Storer) delete(id u32) ! {
	storer.db.delete(id)!
}
