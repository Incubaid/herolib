module vfs_db

import os
import incubaid.herolib.data.ourdb
import rand

fn setup_vfs() !(&DatabaseVFS, string) {
	test_data_dir := os.join_path(os.temp_dir(), 'vfsourdb_test_data_${rand.string(3)}')

	os.mkdir_all(test_data_dir)!

	mut db_data := ourdb.new(
		path: os.join_path(test_data_dir, 'data')
	)!

	mut db_metadata := ourdb.new(
		path: os.join_path(test_data_dir, 'metadata')
	)!

	mut vfs := new(mut db_data, mut db_metadata)!
	return vfs, test_data_dir
}

fn teardown_vfs(data_dir string) {
	os.rmdir_all(data_dir) or {}
}

fn test_root_directory() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	mut root := vfs.root_get()!
	assert root.get_metadata().file_type == .directory
	assert root.get_metadata().name == ''
}

fn test_directory_operations() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Test creation
	mut test_dir := vfs.dir_create('/test_dir')!
	assert test_dir.get_metadata().name == 'test_dir'
	assert test_dir.get_metadata().file_type == .directory

	// Test listing
	mut entries := vfs.dir_list('/')!
	assert entries.any(it.get_metadata().name == 'test_dir')

	// Test listing entries in the created directory
	entries = vfs.dir_list('/test_dir')!
	assert entries.len == 0
}

fn test_file_operations() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	vfs.dir_create('/test_dir')!

	// Test file creation
	mut test_file := vfs.file_create('/test_dir/test.txt')!
	assert test_file.get_metadata().name == 'test.txt'
	assert test_file.get_metadata().file_type == .file

	// Test writing/reading
	test_content := 'Hello, World!'.bytes()
	vfs.file_write('/test_dir/test.txt', test_content)!
	assert vfs.file_read('/test_dir/test.txt')! == test_content

	// Test listing entries in the created directory
	entries := vfs.dir_list('/test_dir')!
	assert entries.len == 1
}

fn test_directory_move() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	vfs.dir_create('/test_dir')!
	vfs.file_create('/test_dir/test.txt')!

	// Test listing entries in the created directory
	mut entries := vfs.dir_list('/test_dir')!
	assert entries.len == 1

	// Perform move
	moved_dir := vfs.move('/test_dir', '/test_dir2')!
	assert moved_dir.get_metadata().name == 'test_dir2'
	assert vfs.exists('/test_dir') == false
	assert vfs.exists('/test_dir2/test.txt') == true

	// Test listing entries in the created directory
	entries = vfs.dir_list('/test_dir2')!
	assert entries.len == 1
}

fn test_directory_copy() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	vfs.dir_create('/test_dir')!
	vfs.file_create('/test_dir/test.txt')!

	// Perform copy
	copied_dir := vfs.copy('/test_dir', '/test_dir2')!
	assert copied_dir.get_metadata().name == 'test_dir2'
	assert vfs.exists('/test_dir') == true
	assert vfs.exists('/test_dir/test.txt') == true
	assert vfs.exists('/test_dir2/test.txt') == true
}

fn test_nested_directory_move() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	vfs.dir_create('/test_dir2')!
	vfs.dir_create('/test_dir2/folder1')!
	vfs.file_create('/test_dir2/folder1/file1.txt')!
	vfs.dir_create('/test_dir2/folder2')!

	// Move folder1 into folder2
	moved_dir := vfs.move('/test_dir2/folder1', '/test_dir2/folder2/folder1')!
	assert moved_dir.get_metadata().name == 'folder1'
	assert vfs.exists('/test_dir2/folder2/folder1/file1.txt') == true
}

fn test_deletion_operations() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	vfs.dir_create('/test_dir')!
	vfs.file_create('/test_dir/test.txt')!

	// Test file deletion
	vfs.file_delete('/test_dir/test.txt')!
	assert vfs.exists('/test_dir/test.txt') == false

	// Test directory deletion
	vfs.dir_delete('/test_dir')!
	assert vfs.exists('/test_dir') == false
}

fn test_symlink_operations() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	vfs.dir_create('/test_dir')!
	vfs.file_create('/test_dir/target.txt')!

	// Test symlink creation
	mut symlink := vfs.link_create('/test_dir/target.txt', '/test_link')!
	assert symlink.get_metadata().name == 'test_link'
	assert symlink.get_metadata().file_type == .symlink
	assert vfs.exists('/test_link') == true

	// Test symlink reading
	target := vfs.link_read('/test_link')!
	assert target == '/test_dir/target.txt'

	// Test symlink deletion
	vfs.link_delete('/test_link')!
	assert vfs.exists('/test_link') == false
}

fn test_rename_operations() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Test file rename
	vfs.file_create('/test_file.txt')!
	renamed_file := vfs.rename('/test_file.txt', '/renamed_file.txt')!
	assert renamed_file.get_metadata().name == 'renamed_file.txt'
	assert vfs.exists('/test_file.txt') == false
	assert vfs.exists('/renamed_file.txt') == true

	// Test directory rename
	vfs.dir_create('/test_dir')!
	renamed_dir := vfs.rename('/test_dir', '/renamed_dir')!
	assert renamed_dir.get_metadata().name == 'renamed_dir'
	assert vfs.exists('/test_dir') == false
	assert vfs.exists('/renamed_dir') == true
}

fn test_exists_function() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Test root exists
	assert vfs.exists('/') == true

	// Test non-existent path
	assert vfs.exists('/nonexistent') == false

	// Create and test file exists
	vfs.file_create('/test_file.txt')!
	assert vfs.exists('/test_file.txt') == true

	// Create and test directory exists
	vfs.dir_create('/test_dir')!
	assert vfs.exists('/test_dir') == true

	// Test with and without leading slash
	assert vfs.exists('test_dir') == true
}

fn test_get_function() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Test getting root
	root := vfs.get('/')!
	assert root.get_metadata().name == ''
	assert root.get_metadata().file_type == .directory

	// Test getting file
	vfs.file_create('/test_file.txt')!
	file := vfs.get('/test_file.txt')!
	assert file.get_metadata().name == 'test_file.txt'
	assert file.get_metadata().file_type == .file

	// Test getting directory
	vfs.dir_create('/test_dir')!
	dir := vfs.get('/test_dir')!
	assert dir.get_metadata().name == 'test_dir'
	assert dir.get_metadata().file_type == .directory
}
