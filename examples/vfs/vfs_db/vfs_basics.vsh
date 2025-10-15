#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import os
import incubaid.herolib.vfs.vfs_db
import incubaid.herolib.data.ourdb

// This example demonstrates directory operations in the VFS
// - Creating directories with subdirectories
// - Listing directories
// - Reading and writing files in subdirectories
// - Deleting files and verifying they're gone

// Set up the example data directory
example_data_dir := '/tmp/example_dir_ops'
os.mkdir_all(example_data_dir)!

// Create separate databases for data and metadata
mut db_data := ourdb.new(
	path:             os.join_path(example_data_dir, 'data')
	incremental_mode: false
)!

mut db_metadata := ourdb.new(
	path:             os.join_path(example_data_dir, 'metadata')
	incremental_mode: false
)!

// Create VFS with separate databases for data and metadata
mut vfs := vfs_db.new(mut db_data, mut db_metadata) or { panic('Failed to create VFS: ${err}') }

println('\n---------BEGIN DIRECTORY OPERATIONS EXAMPLE')

// Create directories with subdirectories
println('\n---------CREATING DIRECTORIES')
vfs.dir_create('/dir1') or { panic('Failed to create directory: ${err}') }
println('Created directory: /dir1')

vfs.dir_create('/dir1/subdir1') or { panic('Failed to create directory: ${err}') }
println('Created directory: /dir1/subdir1')

vfs.dir_create('/dir1/subdir2') or { panic('Failed to create directory: ${err}') }
println('Created directory: /dir1/subdir2')

vfs.dir_create('/dir2') or { panic('Failed to create directory: ${err}') }
println('Created directory: /dir2')

vfs.dir_create('/dir2/subdir1') or { panic('Failed to create directory: ${err}') }
println('Created directory: /dir2/subdir1')

vfs.dir_create('/dir2/subdir1/subsubdir1') or { panic('Failed to create directory: ${err}') }
println('Created directory: /dir2/subdir1/subsubdir1')

// List directories
println('\n---------LISTING ROOT DIRECTORY')
root_entries := vfs.dir_list('/') or { panic('Failed to list directory: ${err}') }
println('Root directory contains:')
for entry in root_entries {
	entry_type := if entry.get_metadata().file_type == .directory { 'directory' } else { 'file' }
	println('- ${entry.get_metadata().name} (${entry_type})')
}

println('\n---------LISTING /dir1 DIRECTORY')
dir1_entries := vfs.dir_list('/dir1') or { panic('Failed to list directory: ${err}') }
println('/dir1 directory contains:')
for entry in dir1_entries {
	entry_type := if entry.get_metadata().file_type == .directory { 'directory' } else { 'file' }
	println('- ${entry.get_metadata().name} (${entry_type})')
}

// Write a file in a subdirectory
println('\n---------WRITING FILE IN SUBDIRECTORY')
vfs.file_create('/dir1/subdir1/test_file.txt') or { panic('Failed to create file: ${err}') }
println('Created file: /dir1/subdir1/test_file.txt')

test_content := 'This is a test file in a subdirectory'
vfs.file_write('/dir1/subdir1/test_file.txt', test_content.bytes()) or {
	panic('Failed to write file: ${err}')
}
println('Wrote content to file: /dir1/subdir1/test_file.txt')

// Read the file and verify content
println('\n---------READING FILE FROM SUBDIRECTORY')
file_content := vfs.file_read('/dir1/subdir1/test_file.txt') or {
	panic('Failed to read file: ${err}')
}
println('File content: ${file_content.bytestr()}')
println('Content verification: ${if file_content.bytestr() == test_content {
	'SUCCESS'
} else {
	'FAILED'
}}')

// List the subdirectory to see the file
println('\n---------LISTING /dir1/subdir1 DIRECTORY')
subdir1_entries := vfs.dir_list('/dir1/subdir1') or { panic('Failed to list directory: ${err}') }
println('/dir1/subdir1 directory contains:')
for entry in subdir1_entries {
	entry_type := if entry.get_metadata().file_type == .directory { 'directory' } else { 'file' }
	println('- ${entry.get_metadata().name} (${entry_type})')
}

// Delete the file
println('\n---------DELETING FILE')
vfs.file_delete('/dir1/subdir1/test_file.txt') or { panic('Failed to delete file: ${err}') }
println('Deleted file: /dir1/subdir1/test_file.txt')

// List the subdirectory again to verify the file is gone
println('\n---------LISTING /dir1/subdir1 DIRECTORY AFTER DELETION')
subdir1_entries_after := vfs.dir_list('/dir1/subdir1') or {
	panic('Failed to list directory: ${err}')
}
println('/dir1/subdir1 directory contains:')
if subdir1_entries_after.len == 0 {
	println('- (empty directory)')
} else {
	for entry in subdir1_entries_after {
		entry_type := if entry.get_metadata().file_type == .directory { 'directory' } else { 'file' }
		println('- ${entry.get_metadata().name} (${entry_type})')
	}
}

// Create a file in a deep subdirectory
println('\n---------CREATING FILE IN DEEP SUBDIRECTORY')
vfs.file_create('/dir2/subdir1/subsubdir1/deep_file.txt') or {
	panic('Failed to create file: ${err}')
}
println('Created file: /dir2/subdir1/subsubdir1/deep_file.txt')

deep_content := 'This file is in a deep subdirectory'
vfs.file_write('/dir2/subdir1/subsubdir1/deep_file.txt', deep_content.bytes()) or {
	panic('Failed to write file: ${err}')
}
println('Wrote content to file: /dir2/subdir1/subsubdir1/deep_file.txt')

// Read the deep file and verify content
println('\n---------READING FILE FROM DEEP SUBDIRECTORY')
deep_file_content := vfs.file_read('/dir2/subdir1/subsubdir1/deep_file.txt') or {
	panic('Failed to read file: ${err}')
}
println('File content: ${deep_file_content.bytestr()}')
println('Content verification: ${if deep_file_content.bytestr() == deep_content {
	'SUCCESS'
} else {
	'FAILED'
}}')

// Clean up by deleting directories (optional)
println('\n---------CLEANING UP')
vfs.file_delete('/dir2/subdir1/subsubdir1/deep_file.txt') or {
	panic('Failed to delete file: ${err}')
}
println('Deleted file: /dir2/subdir1/subsubdir1/deep_file.txt')

// Try to verify the file is gone by attempting to read it
println('\n---------VERIFYING FILE IS GONE')
deep_file_exists := vfs.file_read('/dir2/subdir1/subsubdir1/deep_file.txt') or {
	println('File is gone as expected: ${err}')
	[]u8{}
}
if deep_file_exists.len > 0 {
	panic('ERROR: File still exists!')
}

println('\n---------END DIRECTORY OPERATIONS EXAMPLE')
