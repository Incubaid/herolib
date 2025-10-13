module vfs_db

import os
import incubaid.herolib.data.ourdb
import incubaid.herolib.vfs as vfs_mod
import rand

fn setup_fs() !(&DatabaseVFS, string) {
	test_data_dir := os.join_path(os.temp_dir(), 'vfsourdb_print_test_${rand.string(3)}')
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

fn test_directory_print_empty() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create an empty directory
	mut dir := fs.new_directory(
		name: 'test_dir'
	)!

	// Test printing the empty directory
	output := fs.directory_print(dir)

	// Verify the output
	assert output == 'test_dir/\n'
}

fn test_directory_print_with_contents() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create a directory with various contents
	mut dir := fs.new_directory(
		name: 'test_dir'
	)!

	// Add a subdirectory
	mut subdir := fs.directory_mkdir(mut dir, 'subdir')!

	// Add a file
	mut file := fs.directory_touch(mut dir, 'test_file.txt')!

	// Add a symlink
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
		parent_id: dir.metadata.id
	}
	fs.directory_add_symlink(mut dir, mut symlink)!

	// Test printing the directory
	output := fs.directory_print(dir)

	// Verify the output contains all entries
	assert output.contains('test_dir/')
	assert output.contains('📁 subdir/')
	assert output.contains('📄 test_file.txt')
	assert output.contains('🔗 test_link -> /path/to/target')
}

fn test_directory_printall_simple() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create a simple directory structure
	mut dir := fs.new_directory(
		name: 'root_dir'
	)!

	// Add a file
	mut file := fs.directory_touch(mut dir, 'test_file.txt')!

	// Test printing the directory recursively
	output := fs.directory_printall(dir, '')!

	// Verify the output
	assert output.contains('📁 root_dir/')
	assert output.contains('📄 test_file.txt')
}

fn test_directory_printall_nested() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create a nested directory structure
	mut root := fs.new_directory(
		name: 'root'
	)!

	// Add a subdirectory
	mut subdir1 := fs.directory_mkdir(mut root, 'subdir1')!

	// Add a file to the root
	mut root_file := fs.directory_touch(mut root, 'root_file.txt')!

	// Add a file to the subdirectory
	mut subdir_file := fs.directory_touch(mut subdir1, 'subdir_file.txt')!

	// Add a nested subdirectory
	mut subdir2 := fs.directory_mkdir(mut subdir1, 'subdir2')!

	// Add a file to the nested subdirectory
	mut nested_file := fs.directory_touch(mut subdir2, 'nested_file.txt')!

	// Add a symlink to the nested subdirectory
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
		parent_id: subdir2.metadata.id
	}
	fs.directory_add_symlink(mut subdir2, mut symlink)!

	// Test printing the directory recursively
	output := fs.directory_printall(root, '')!

	// Verify the output contains all entries with proper indentation
	assert output.contains('📁 root/')
	assert output.contains('  📄 root_file.txt')
	assert output.contains('  📁 subdir1/')
	assert output.contains('    📄 subdir_file.txt')
	assert output.contains('    📁 subdir2/')
	assert output.contains('      📄 nested_file.txt')
	assert output.contains('      🔗 test_link -> /path/to/target')
}

fn test_directory_printall_empty() ! {
	mut fs, data_dir := setup_fs()!
	defer {
		teardown_fs(data_dir)
	}

	// Create an empty directory
	mut dir := fs.new_directory(
		name: 'empty_dir'
	)!

	// Test printing the empty directory recursively
	output := fs.directory_printall(dir, '')!

	// Verify the output
	assert output == '📁 empty_dir/\n'
}
