module herofs

import incubaid.herolib.core.pathlib
import os

fn test_find() {
	mut f := new_fs_test()!
	// defer {
	// 	delete_fs_test()!
	// }

	// Create a test directory structure
	f.factory.fs_dir.create_path(f.id, '/test_dir/subdir')!

	mut blob1 := f.factory.fs_blob.new(data: 'hello'.bytes())!
	blob1 = f.factory.fs_blob.set(blob1)!
	mut file1 := f.factory.fs_file.new(
		name:  'file1.txt'
		fs_id: f.id
		blobs: [blob1.id]
	)!
	file1 = f.factory.fs_file.set(file1)!
	dir1 := f.get_dir_by_absolute_path('/test_dir')!
	f.factory.fs_file.add_to_directory(file1.id, dir1.id)!

	mut blob2 := f.factory.fs_blob.new(data: 'world'.bytes())!
	blob2 = f.factory.fs_blob.set(blob2)!
	mut file2 := f.factory.fs_file.new(
		name:  'file2.log'
		fs_id: f.id
		blobs: [blob2.id]
	)!
	file2 = f.factory.fs_file.set(file2)!
	f.factory.fs_file.add_to_directory(file2.id, dir1.id)!

	mut blob3 := f.factory.fs_blob.new(data: 'sub'.bytes())!
	blob3 = f.factory.fs_blob.set(blob3)!
	mut file3 := f.factory.fs_file.new(
		name:  'file3.txt'
		fs_id: f.id
		blobs: [blob3.id]
	)!
	file3 = f.factory.fs_file.set(file3)!
	dir2 := f.get_dir_by_absolute_path('/test_dir/subdir')!
	f.factory.fs_file.add_to_directory(file3.id, dir2.id)!

	mut symlink1 := f.factory.fs_symlink.new(
		name:        'link1.txt'
		fs_id:       f.id
		parent_id:   dir1.id
		target_id:   file1.id
		target_type: .file
	)!
	symlink1 = f.factory.fs_symlink.set(symlink1)!
	mut dir1_mut := f.factory.fs_dir.get(dir1.id)!
	dir1_mut.symlinks << symlink1.id
	f.factory.fs_dir.set(dir1_mut)!
	// Test 1: Find all files recursively (default)
	mut results_all := f.find('/', FindOptions{})!
	// root, test_dir, file1.txt, file2.log, link1.txt, subdir, file3.txt
	assert results_all.len == 7

	// Test 2: Find text files
	mut results_txt := f.find('/', FindOptions{
		include_patterns: ['*.txt']
	})!
	assert results_txt.filter(it.result_type == .file).len == 2
	for result in results_txt {
		if result.result_type == .file {
			assert result.path.ends_with('.txt')
		}
	}

	// Test 3: Find files non-recursively
	mut results_non_recursive := f.find('/test_dir', FindOptions{
		recursive: false
	})!
	// test_dir, file1.txt, file2.log, subdir, link1.txt
	assert results_non_recursive.len == 5

	// Test 4: Exclude log files
	mut results_no_log := f.find('/', FindOptions{
		exclude_patterns: ['*.log']
	})!
	for result in results_no_log {
		assert !result.path.ends_with('.log')
	}

	// Test 5: Find with max depth
	mut results_depth_1 := f.find('/', FindOptions{
		max_depth: 1
	})!
	// root, test_dir
	assert results_depth_1.len == 2

	// Test 6: Find a specific file
	mut results_specific_file := f.find('/test_dir/file1.txt', FindOptions{})!
	assert results_specific_file.len == 1
	assert results_specific_file[0].path == '/test_dir/file1.txt'

	// Test 7: Find with symlinks not followed
	mut results_symlinks := f.find('/', FindOptions{
		follow_symlinks: false
	})!
	mut found_symlink := false
	for result in results_symlinks {
		if result.result_type == .symlink {
			found_symlink = true
			break
		}
	}
	assert found_symlink

	// Test 8: Find a specific directory
	mut results_specific_dir := f.find('/test_dir/subdir', FindOptions{})!
	// should contain subdir and file3.txt
	assert results_specific_dir.len == 2
}
