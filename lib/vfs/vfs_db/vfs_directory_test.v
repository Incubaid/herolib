module vfs_db

import os
import incubaid.herolib.data.ourdb
import incubaid.herolib.vfs as vfs_mod
import rand

fn setup_fs() !(&DatabaseVFS, string) {
	test_data_dir := os.join_path(os.temp_dir(), 'vfsourdb_directory_test_${rand.string(3)}')
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

fn teardown_fs(data_dir string) {
	os.rmdir_all(data_dir) or {}
}

fn test_new_directory() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Test creating a new directory
	mut dir := fs.new_directory(
		name: 'test_dir'
	)!

	// Verify the directory
	assert dir.metadata.name == 'test_dir'
	assert dir.metadata.file_type == .directory
	assert dir.metadata.size == 0
	assert dir.metadata.mode == 0o755 // Default mode for directories
	assert dir.metadata.owner == 'user'
	assert dir.metadata.group == 'user'
	assert dir.children.len == 0
}

fn test_new_directory_with_custom_permissions() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Test creating a directory with custom permissions
	mut dir := fs.new_directory(
		name:  'custom_dir'
		mode:  0o700
		owner: 'admin'
		group: 'staff'
	)!

	// Verify the directory
	assert dir.metadata.name == 'custom_dir'
	assert dir.metadata.file_type == .directory
	assert dir.metadata.size == 0
	assert dir.metadata.mode == 0o700
	assert dir.metadata.owner == 'admin'
	assert dir.metadata.group == 'staff'
}

fn test_copy_directory() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create a directory to copy
	original_dir := Directory{
		metadata:  vfs_mod.Metadata{
			id:          1
			name:        'original_dir'
			file_type:   .directory
			size:        0
			mode:        0o755
			owner:       'admin'
			group:       'staff'
			created_at:  0
			modified_at: 0
			accessed_at: 0
		}
		children:  []
		parent_id: 0
	}

	// Test copying the directory
	copied_dir := fs.copy_directory(original_dir)!

	// Verify the copied directory
	assert copied_dir.metadata.name == 'original_dir'
	assert copied_dir.metadata.file_type == .directory
	assert copied_dir.metadata.size == 0
	assert copied_dir.metadata.mode == 0o755
	assert copied_dir.metadata.owner == 'admin'
	assert copied_dir.metadata.group == 'staff'
	assert copied_dir.children.len == 0
	assert copied_dir.metadata.id != original_dir.metadata.id // Should have a new ID
}

fn test_directory_mkdir() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create a parent directory
	mut parent_dir := fs.new_directory(
		name: 'parent_dir'
	)!

	// Test creating a subdirectory
	mut subdir := fs.directory_mkdir(mut parent_dir, 'subdir')!

	// Verify the subdirectory
	assert subdir.metadata.name == 'subdir'
	assert subdir.metadata.file_type == .directory
	assert subdir.parent_id == parent_dir.metadata.id

	// Verify the parent directory's children
	assert parent_dir.children.len == 1
	assert parent_dir.children[0] == subdir.metadata.id

	// Test creating a duplicate directory (should fail)
	if _ := fs.directory_mkdir(mut parent_dir, 'subdir') {
		assert false, 'Expected error when creating duplicate directory'
	} else {
		assert err.msg().contains('already exists')
	}
}

fn test_directory_touch() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create a parent directory
	mut parent_dir := fs.new_directory(
		name: 'parent_dir'
	)!

	// Test creating a file
	mut file := fs.directory_touch(mut parent_dir, 'test_file.txt')!

	// Reload the parent directory to get the latest version
	if updated_dir := fs.load_entry(parent_dir.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			parent_dir.children = dir.children
		}
	}

	// Verify the file
	assert file.metadata.name == 'test_file.txt'
	assert file.metadata.file_type == .file
	assert file.parent_id == parent_dir.metadata.id
	// File data is stored in chunks, not directly in the file struct

	// Verify the parent directory's children
	assert parent_dir.children.len == 1
	assert parent_dir.children[0] == file.metadata.id

	// Test creating a duplicate file (should fail)
	if _ := fs.directory_touch(mut parent_dir, 'test_file.txt') {
		assert false, 'Expected error when creating duplicate file'
	} else {
		assert err.msg().contains('already exists')
	}
}

fn test_directory_rm() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create a parent directory
	mut parent_dir := fs.new_directory(
		name: 'parent_dir'
	)!

	// Create a file to remove
	mut file := fs.directory_touch(mut parent_dir, 'test_file.txt')!

	// Reload the parent directory to get the latest version
	if updated_dir := fs.load_entry(parent_dir.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			parent_dir.children = dir.children
		}
	}

	// Verify the parent directory's children
	assert parent_dir.children.len == 1

	// Test removing the file
	fs.directory_rm(mut parent_dir, 'test_file.txt')!

	// Reload the parent directory to get the latest version
	if updated_dir := fs.load_entry(parent_dir.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			parent_dir.children = dir.children
		}
	}

	// Verify the parent directory's children
	assert parent_dir.children.len == 0

	// Test removing a non-existent file (should fail)
	if _ := fs.directory_rm(mut parent_dir, 'nonexistent.txt') {
		assert false, 'Expected error when removing non-existent file'
	} else {
		assert err.msg().contains('not found')
	}
}

fn test_directory_rename() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create a parent directory
	mut parent_dir := fs.new_directory(
		name: 'parent_dir'
	)!

	// Create a subdirectory to rename
	mut subdir := fs.directory_mkdir(mut parent_dir, 'old_name')!

	// Test renaming the subdirectory
	renamed_dir := fs.directory_rename(parent_dir, 'old_name', 'new_name')!

	// Verify the renamed directory
	assert renamed_dir.metadata.name == 'new_name'

	// Test renaming a non-existent directory (should fail)
	if _ := fs.directory_rename(parent_dir, 'nonexistent', 'new_name') {
		assert false, 'Expected error when renaming non-existent directory'
	} else {
		assert err.msg().contains('not found')
	}
}

fn test_directory_children() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create a parent directory
	mut parent_dir := fs.new_directory(
		name: 'parent_dir'
	)!

	// Initially, the directory should be empty
	ch := fs.directory_children(mut parent_dir, false)!
	assert ch.len == 0

	// Create subdirectories and files
	mut subdir1 := fs.directory_mkdir(mut parent_dir, 'subdir1')!
	mut subdir2 := fs.directory_mkdir(mut parent_dir, 'subdir2')!
	mut file1 := fs.directory_touch(mut parent_dir, 'file1.txt')!

	// Create a nested file
	mut nested_file := fs.directory_touch(mut subdir1, 'nested.txt')!

	// Test getting non-recursive children
	children := fs.directory_children(mut parent_dir, false)!
	assert children.len == 3

	// Verify children types
	mut dir_count := 0
	mut file_count := 0
	for child in children {
		if child is Directory {
			dir_count++
		} else if child is File {
			file_count++
		}
	}
	assert dir_count == 2
	assert file_count == 1

	// Test getting recursive children
	recursive_children := fs.directory_children(mut parent_dir, true)!
	assert recursive_children.len == 4 // parent_dir's 3 children + nested_file
}

fn test_directory_move() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create source and destination parent directories
	mut src_parent := fs.new_directory(name: 'src_parent')!
	mut dst_parent := fs.new_directory(name: 'dst_parent')!

	// Create a directory to move with nested structure
	mut dir_to_move := fs.directory_mkdir(mut src_parent, 'dir_to_move')!
	mut nested_dir := fs.directory_mkdir(mut dir_to_move, 'nested_dir')!
	mut nested_file := fs.directory_touch(mut dir_to_move, 'nested_file.txt')!

	// Reload the directories to get the latest versions
	if updated_dir := fs.load_entry(src_parent.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			src_parent.children = dir.children
		}
	}

	if updated_dir := fs.load_entry(dst_parent.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			dst_parent.children = dir.children
		}
	}

	if updated_dir := fs.load_entry(dir_to_move.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			dir_to_move.children = dir.children
		}
	}

	// Test moving the directory
	moved_dir := fs.directory_move(src_parent, MoveDirArgs{
		src_entry_name: 'dir_to_move'
		dst_entry_name: 'moved_dir'
		dst_parent_dir: dst_parent
	})!

	// Reload the directories to get the latest versions
	if updated_dir := fs.load_entry(src_parent.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			src_parent.children = dir.children
		}
	}

	if updated_dir := fs.load_entry(dst_parent.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			dst_parent.children = dir.children
		}
	}

	// Verify the moved directory
	assert moved_dir.metadata.name == 'moved_dir'
	assert moved_dir.parent_id == dst_parent.metadata.id
	assert moved_dir.children.len == 2

	// Verify source parent no longer has the directory
	assert src_parent.children.len == 0

	// Verify destination parent has the moved directory
	assert dst_parent.children.len == 1
	assert dst_parent.children[0] == moved_dir.metadata.id

	// Test moving non-existent directory (should fail)
	if _ := fs.directory_move(src_parent, MoveDirArgs{
		src_entry_name: 'nonexistent'
		dst_entry_name: 'new_name'
		dst_parent_dir: dst_parent
	})
	{
		assert false, 'Expected error when moving non-existent directory'
	} else {
		assert err.msg().contains('not found')
	}
}

fn test_directory_copy() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create source and destination parent directories
	mut src_parent := fs.new_directory(name: 'src_parent')!
	mut dst_parent := fs.new_directory(name: 'dst_parent')!

	// Create a directory to copy with nested structure
	mut dir_to_copy := fs.directory_mkdir(mut src_parent, 'dir_to_copy')!
	mut nested_dir := fs.directory_mkdir(mut dir_to_copy, 'nested_dir')!
	mut nested_file := fs.directory_touch(mut dir_to_copy, 'nested_file.txt')!

	// Reload the directories to get the latest versions
	if updated_dir := fs.load_entry(src_parent.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			src_parent.children = dir.children
		}
	}

	if updated_dir := fs.load_entry(dst_parent.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			dst_parent.children = dir.children
		}
	}

	if updated_dir := fs.load_entry(dir_to_copy.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			dir_to_copy.children = dir.children
		}
	}

	// Test copying the directory
	copied_dir := fs.directory_copy(mut src_parent, CopyDirArgs{
		src_entry_name: 'dir_to_copy'
		dst_entry_name: 'copied_dir'
		dst_parent_dir: dst_parent
	})!

	// Reload the directories to get the latest versions
	if updated_dir := fs.load_entry(src_parent.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			src_parent.children = dir.children
		}
	}

	if updated_dir := fs.load_entry(dst_parent.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			dst_parent.children = dir.children
		}
	}

	if updated_dir := fs.load_entry(dir_to_copy.metadata.id) {
		if updated_dir is Directory {
			mut dir := updated_dir as Directory
			dir_to_copy.children = dir.children
		}
	}

	// Verify the copied directory
	assert copied_dir.metadata.name == 'copied_dir'
	assert copied_dir.parent_id == dst_parent.metadata.id
	assert copied_dir.children.len == 2

	// Verify source directory still exists with its children
	assert src_parent.children.len == 1
	assert dir_to_copy.children.len == 2

	// Verify destination parent has the copied directory
	assert dst_parent.children.len == 1
	assert dst_parent.children[0] == copied_dir.metadata.id

	// Test copying non-existent directory (should fail)
	if _ := fs.directory_copy(mut src_parent, CopyDirArgs{
		src_entry_name: 'nonexistent'
		dst_entry_name: 'new_copy'
		dst_parent_dir: dst_parent
	})
	{
		assert false, 'Expected error when copying non-existent directory'
	} else {
		assert err.msg().contains('not found')
	}
}

fn test_directory_add_symlink() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create a parent directory
	mut parent_dir := fs.new_directory(
		name: 'parent_dir'
	)!

	// Create a symlink
	mut symlink := Symlink{
		metadata:  vfs_mod.Metadata{
			id:          fs.get_next_id()
			name:        'test_link'
			file_type:   .symlink
			size:        0
			mode:        0o777
			owner:       'user'
			group:       'user'
			created_at:  0
			modified_at: 0
			accessed_at: 0
		}
		target:    '/path/to/target'
		parent_id: parent_dir.metadata.id
	}

	// Test adding the symlink to the directory
	fs.directory_add_symlink(mut parent_dir, mut symlink)!

	// Verify the parent directory's children
	assert parent_dir.children.len == 1
	assert parent_dir.children[0] == symlink.metadata.id

	// Test adding a duplicate symlink (should fail)
	if _ := fs.directory_add_symlink(mut parent_dir, mut symlink) {
		assert false, 'Expected error when adding duplicate symlink'
	} else {
		assert err.msg().contains('already exists')
	}
}
