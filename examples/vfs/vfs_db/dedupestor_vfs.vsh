#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import os
import rand
import incubaid.herolib.vfs.vfs_db
import incubaid.herolib.data.dedupestor
import incubaid.herolib.data.ourdb

pub struct VFSDedupeDB {
	dedupestor.DedupeStore
}

pub fn (mut db VFSDedupeDB) set(args ourdb.OurDBSetArgs) !u32 {
	return db.store(args.data, dedupestor.Reference{
		owner: u16(1)
		id:    args.id or { panic('VFS Must provide id') }
	})!
}

pub fn (mut db VFSDedupeDB) delete(id u32) ! {
	db.DedupeStore.delete(id, dedupestor.Reference{ owner: u16(1), id: id })!
}

example_data_dir := os.join_path(os.dir(@FILE), 'example_db')
os.mkdir_all(example_data_dir)!

data_path := os.join_path(example_data_dir, 'data')

// Create separate databases for data and metadata
mut db_data := VFSDedupeDB{
	DedupeStore: dedupestor.new(
		path: os.join_path(example_data_dir, 'data')
	)!
}

mut db_metadata := ourdb.new(
	path:             os.join_path(example_data_dir, 'metadata')
	incremental_mode: false
)!

// Create VFS with separate databases for data and metadata
mut vfs := vfs_db.new(mut db_data, mut db_metadata) or { panic('Failed to create VFS: ${err}') }

println('\n---------BEGIN EXAMPLE')
println('---------WRITING FILES')
vfs.file_create('/some_file.txt') or { panic('Failed to create file: ${err}') }
vfs.file_create('/another_file.txt') or { panic('Failed to create file: ${err}') }

vfs.file_write('/some_file.txt', 'gibberish'.bytes()) or { panic('Failed to write file: ${err}') }
vfs.file_write('/another_file.txt', 'abcdefg'.bytes()) or { panic('Failed to write file: ${err}') }

println('\n---------READING FILES')
some_file_content := vfs.file_read('/some_file.txt') or { panic('Failed to read file: ${err}') }
println(some_file_content.bytestr())

another_file_content := vfs.file_read('/another_file.txt') or {
	panic('Failed to read file: ${err}')
}
println(another_file_content.bytestr())

println('\n---------WRITING DUPLICATE FILE (DB SIZE: ${os.file_size(os.join_path(example_data_dir,
	'data/0.db'))})')
vfs.file_create('/duplicate.txt') or { panic('Failed to create file: ${err}') }
vfs.file_write('/duplicate.txt', 'gibberish'.bytes()) or { panic('Failed to write file: ${err}') }

println('\n---------WROTE DUPLICATE FILE (DB SIZE: ${os.file_size(os.join_path(example_data_dir,
	'data/0.db'))})')
println('---------READING FILES')
some_file_content3 := vfs.file_read('/some_file.txt') or { panic('Failed to read file: ${err}') }
println(some_file_content3.bytestr())

another_file_content3 := vfs.file_read('/another_file.txt') or {
	panic('Failed to read file: ${err}')
}
println(another_file_content3.bytestr())

duplicate_content := vfs.file_read('/duplicate.txt') or { panic('Failed to read file: ${err}') }
println(duplicate_content.bytestr())

println('\n---------DELETING DUPLICATE FILE (DB SIZE: ${os.file_size(os.join_path(example_data_dir,
	'data/0.db'))})')
vfs.file_delete('/duplicate.txt') or { panic('Failed to delete file: ${err}') }

data_path2 := os.join_path(example_data_dir, 'data/0.db')
db_file_path := os.join_path(data_path2, '0.db')
println('---------READING FILES (DB SIZE: ${if os.exists(db_file_path) {
	os.file_size(db_file_path)
} else {
	0
}})')
some_file_content2 := vfs.file_read('/some_file.txt') or { panic('Failed to read file: ${err}') }
println(some_file_content2.bytestr())

another_file_content2 := vfs.file_read('/another_file.txt') or {
	panic('Failed to read file: ${err}')
}
println(another_file_content2.bytestr())

// FAILS SUCCESSFULLY
// duplicate_content := vfs.file_read('duplicate.txt') or {
//     println('Expected error: ${err}')
//     []u8{}
// }
// if duplicate_content.len > 0 {
//     println(duplicate_content.bytestr())
// }
