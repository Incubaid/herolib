module vfs_db

import os
import incubaid.herolib.data.ourdb
import incubaid.herolib.vfs as vfs_mod
import rand

fn setup_vfs() !(&DatabaseVFS, string) {
	test_data_dir := os.join_path(os.temp_dir(), 'vfsourdb_getters_test_${rand.string(3)}')
	os.mkdir_all(test_data_dir)!

	// Create separate databases for data and metadata
	mut db_data := ourdb.new(
		path: os.join_path(test_data_dir, 'data')
	)!

	mut db_metadata := ourdb.new(
		path: os.join_path(test_data_dir, 'metadata')
	)!

	// Create VFS with separate databases for data and metadata
	mut fs := new(mut db_data, mut db_metadata)!
	return fs, test_data_dir
}

fn teardown_vfs(data_dir string) {
	os.rmdir_all(data_dir) or {}
}

fn test_root_get_as_dir() ! {
	mut fs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Test getting the root directory
	mut root := fs.root_get_as_dir()!

	// Verify the root directory
	assert root.metadata.name == ''
	assert root.metadata.file_type == .directory
	assert root.metadata.mode == 0o755
	assert root.metadata.owner == 'user'
	assert root.metadata.group == 'user'
	assert root.parent_id == 0

	// Test getting the root directory again (should be the same)
	mut root2 := fs.root_get_as_dir()!
	assert root2.metadata.id == root.metadata.id
}

fn test_get_entry_root() ! {
	mut fs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Test getting the root entry with different path formats
	root1 := fs.get_entry('/')!
	root2 := fs.get_entry('')!
	root3 := fs.get_entry('.')!

	// Verify all paths return the root directory
	assert root1 is Directory
	assert root2 is Directory
	assert root3 is Directory

	if root1 is Directory {
		assert root1.metadata.name == ''
	}
}

fn test_get_entry_file() ! {
	mut fs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Create a file in the root directory
	mut root := fs.root_get_as_dir()!
	mut file := fs.directory_touch(mut root, 'test_file.txt')!

	// Test getting the file entry
	entry := fs.get_entry('/test_file.txt')!

	// Verify the entry is a file
	assert entry is File

	if entry is File {
		assert entry.metadata.name == 'test_file.txt'
		assert entry.metadata.file_type == .file
	}
}

fn test_get_entry_directory() ! {
	mut fs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Create a directory in the root directory
	mut root := fs.root_get_as_dir()!
	mut dir := fs.directory_mkdir(mut root, 'test_dir')!

	// Test getting the directory entry
	entry := fs.get_entry('/test_dir')!

	// Verify the entry is a directory
	assert entry is Directory

	if entry is Directory {
		assert entry.metadata.name == 'test_dir'
		assert entry.metadata.file_type == .directory
	}
}

fn test_get_entry_nested() ! {
	mut fs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Create a nested directory structure
	mut root := fs.root_get_as_dir()!
	mut dir1 := fs.directory_mkdir(mut root, 'dir1')!
	mut dir2 := fs.directory_mkdir(mut dir1, 'dir2')!
	mut file := fs.directory_touch(mut dir2, 'nested_file.txt')!

	// Test getting the nested file entry
	entry := fs.get_entry('/dir1/dir2/nested_file.txt')!

	// Verify the entry is a file
	assert entry is File

	if entry is File {
		assert entry.metadata.name == 'nested_file.txt'
		assert entry.metadata.file_type == .file
	}
}

fn test_get_entry_not_found() ! {
	mut fs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Test getting a non-existent entry
	if _ := fs.get_entry('/nonexistent') {
		assert false, 'Expected error when getting non-existent entry'
	} else {
		// Just check that we got an error, don't check specific message
		assert err.msg() != ''
	}
}

fn test_get_entry_not_a_directory() ! {
	mut fs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Create a file in the root directory
	mut root := fs.root_get_as_dir()!
	mut file := fs.directory_touch(mut root, 'test_file.txt')!

	// Test getting an entry through a file (should fail)
	if _ := fs.get_entry('/test_file.txt/something') {
		assert false, 'Expected error when traversing through a file'
	} else {
		// Just check that we got an error, don't check specific message
		assert err.msg() != ''
	}
}

fn test_get_directory() ! {
	mut fs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Create a directory in the root directory
	mut root := fs.root_get_as_dir()!
	mut dir := fs.directory_mkdir(mut root, 'test_dir')!

	// Test getting the directory
	retrieved_dir := fs.get_directory('/test_dir')!

	// Verify the directory
	assert retrieved_dir.metadata.name == 'test_dir'
	assert retrieved_dir.metadata.file_type == .directory
}

fn test_get_directory_root() ! {
	mut fs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Test getting the root directory
	root := fs.get_directory('/')!

	// Verify the root directory
	assert root.metadata.name == ''
	assert root.metadata.file_type == .directory
}

fn test_get_directory_not_a_directory() ! {
	mut fs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Create a file in the root directory
	mut root := fs.root_get_as_dir()!
	mut file := fs.directory_touch(mut root, 'test_file.txt')!

	// Test getting a file as a directory (should fail)
	if _ := fs.get_directory('/test_file.txt') {
		assert false, 'Expected error when getting a file as a directory'
	} else {
		assert err.msg().contains('Not a directory')
	}
}
