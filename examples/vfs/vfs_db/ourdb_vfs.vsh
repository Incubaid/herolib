#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import os
import rand
import incubaid.herolib.vfs.vfs_db
import incubaid.herolib.data.ourdb

example_data_dir := os.join_path(os.temp_dir(), 'ourdb_example_data_${rand.string(3)}')
os.mkdir_all(example_data_dir)!

// Create separate directories for data and metadata
data_dir := os.join_path(example_data_dir, 'data')
metadata_dir := os.join_path(example_data_dir, 'metadata')
os.mkdir_all(data_dir)!
os.mkdir_all(metadata_dir)!

// Create separate databases for data and metadata
mut db_data := ourdb.new(
	path:             data_dir
	incremental_mode: false
)!

mut db_metadata := ourdb.new(
	path:             metadata_dir
	incremental_mode: false
)!

// Create VFS with separate databases for data and metadata
mut vfs := vfs_db.new_with_separate_dbs(mut db_data, mut db_metadata,
	data_dir:     data_dir
	metadata_dir: metadata_dir
)!

// Create a root directory if it doesn't exist
if !vfs.exists('/') {
	vfs.dir_create('/')!
}

// Create some files and directories
vfs.dir_create('/test_dir')!
vfs.file_create('/test_file.txt')!
vfs.file_write('/test_file.txt', 'Hello, world!'.bytes())!

// Create a file in the directory
vfs.file_create('/test_dir/nested_file.txt')!
vfs.file_write('/test_dir/nested_file.txt', 'This is a nested file.'.bytes())!

// Read the files
println('File content: ${vfs.file_read('/test_file.txt')!.bytestr()}')
println('Nested file content: ${vfs.file_read('/test_dir/nested_file.txt')!.bytestr()}')

// List directory contents
println('Root directory contents:')
root_entries := vfs.dir_list('/')!
for entry in root_entries {
	println('- ${entry.get_metadata().name} (${entry.get_metadata().file_type})')
}

println('Test directory contents:')
test_dir_entries := vfs.dir_list('/test_dir')!
for entry in test_dir_entries {
	println('- ${entry.get_metadata().name} (${entry.get_metadata().file_type})')
}

// Create a duplicate file with the same content
vfs.file_create('/duplicate_file.txt')!
vfs.file_write('/duplicate_file.txt', 'Hello, world!'.bytes())!

// Demonstrate that data and metadata are stored separately
println('Data DB Size: ${os.file_size(os.join_path(data_dir, '0.ourdb'))} bytes')
println('Metadata DB Size: ${os.file_size(os.join_path(metadata_dir, '0.ourdb'))} bytes')
