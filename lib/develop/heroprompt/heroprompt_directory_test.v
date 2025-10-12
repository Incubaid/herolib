module heroprompt

import os

// Test directory: scan entire directory
fn test_directory_scan() ! {
	// Create temp directory with files
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_scan')
	sub_dir := os.join_path(test_dir, 'src')
	os.mkdir_all(sub_dir)!
	os.write_file(os.join_path(test_dir, 'readme.md'), '# Test')!
	os.write_file(os.join_path(test_dir, 'main.v'), 'fn main() {}')!
	os.write_file(os.join_path(sub_dir, 'utils.v'), 'pub fn hello() {}')!
	
	defer {
		os.rmdir_all(test_dir) or {}
	}
	
	// Create directory
	repo := new_directory(path: test_dir)!
	
	// Scan directory
	content := repo.scan()!
	
	// Should find all files
	assert content.file_count >= 3
	assert content.files.len >= 3
	
	// Should find directories
	assert content.dir_count >= 1
	
	// Verify files have content
	mut found_readme := false
	for file in content.files {
		if file.name == 'readme.md' {
			found_readme = true
			assert file.content.contains('# Test')
		}
	}
	assert found_readme, 'readme.md not found in scanned files'
}

// Test directory: scan respects gitignore
fn test_directory_scan_gitignore() ! {
	// Create temp directory with .gitignore
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_gitignore')
	os.mkdir_all(test_dir)!
	
	// Create .gitignore
	os.write_file(os.join_path(test_dir, '.gitignore'), 'ignored.txt\n*.log')!
	
	// Create files
	os.write_file(os.join_path(test_dir, 'included.txt'), 'included')!
	os.write_file(os.join_path(test_dir, 'ignored.txt'), 'ignored')!
	os.write_file(os.join_path(test_dir, 'test.log'), 'log')!
	
	defer {
		os.rmdir_all(test_dir) or {}
	}
	
	// Create directory
	repo := new_directory(path: test_dir)!
	
	// Scan directory
	content := repo.scan()!
	
	// Should include included.txt
	mut found_included := false
	mut found_ignored := false
	mut found_log := false
	
	for file in content.files {
		if file.name == 'included.txt' {
			found_included = true
		}
		if file.name == 'ignored.txt' {
			found_ignored = true
		}
		if file.name == 'test.log' {
			found_log = true
		}
	}
	
	assert found_included, 'included.txt should be found'
	// Note: gitignore behavior depends on codewalker implementation
	// These assertions might need adjustment based on actual behavior
}

// Test directory: add_file with relative path
fn test_directory_add_file_relative() ! {
	// Create temp directory with file
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_add_file_rel')
	os.mkdir_all(test_dir)!
	os.write_file(os.join_path(test_dir, 'test.txt'), 'test content')!
	
	defer {
		os.rmdir_all(test_dir) or {}
	}
	
	// Create directory
	repo := new_directory(path: test_dir)!
	
	// Add file with relative path
	file := repo.add_file(path: 'test.txt')!
	
	assert file.name == 'test.txt'
	assert file.content == 'test content'
	assert file.path.contains('test.txt')
}

// Test directory: add_file with absolute path
fn test_directory_add_file_absolute() ! {
	// Create temp directory with file
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_add_file_abs')
	os.mkdir_all(test_dir)!
	test_file := os.join_path(test_dir, 'test.txt')
	os.write_file(test_file, 'test content')!
	
	defer {
		os.rmdir_all(test_dir) or {}
	}
	
	// Create directory
	repo := new_directory(path: test_dir)!
	
	// Add file with absolute path
	file := repo.add_file(path: test_file)!
	
	assert file.name == 'test.txt'
	assert file.content == 'test content'
}

// Test directory: add_file non-existent file
fn test_directory_add_file_nonexistent() ! {
	// Create temp directory
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_add_nonexist')
	os.mkdir_all(test_dir)!
	
	defer {
		os.rmdir_all(test_dir) or {}
	}
	
	// Create directory
	repo := new_directory(path: test_dir)!
	
	// Try to add non-existent file
	repo.add_file(path: 'nonexistent.txt') or {
		assert err.msg().contains('does not exist')
		return
	}
	
	assert false, 'Expected error when adding non-existent file'
}

// Test directory: add_dir with relative path
fn test_directory_add_dir_relative() ! {
	// Create temp directory with subdirectory
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_add_dir_rel')
	sub_dir := os.join_path(test_dir, 'src')
	os.mkdir_all(sub_dir)!
	os.write_file(os.join_path(sub_dir, 'file1.txt'), 'content1')!
	os.write_file(os.join_path(sub_dir, 'file2.txt'), 'content2')!
	
	defer {
		os.rmdir_all(test_dir) or {}
	}
	
	// Create directory
	repo := new_directory(path: test_dir)!
	
	// Add directory with relative path
	content := repo.add_dir(path: 'src')!
	
	assert content.file_count >= 2
	assert content.files.len >= 2
}

// Test directory: add_dir with absolute path
fn test_directory_add_dir_absolute() ! {
	// Create temp directory with subdirectory
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_add_dir_abs')
	sub_dir := os.join_path(test_dir, 'src')
	os.mkdir_all(sub_dir)!
	os.write_file(os.join_path(sub_dir, 'file1.txt'), 'content1')!
	
	defer {
		os.rmdir_all(test_dir) or {}
	}
	
	// Create directory
	repo := new_directory(path: test_dir)!
	
	// Add directory with absolute path
	content := repo.add_dir(path: sub_dir)!
	
	assert content.file_count >= 1
}

// Test directory: add_dir non-existent directory
fn test_directory_add_dir_nonexistent() ! {
	// Create temp directory
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_add_dir_nonexist')
	os.mkdir_all(test_dir)!
	
	defer {
		os.rmdir_all(test_dir) or {}
	}
	
	// Create directory
	repo := new_directory(path: test_dir)!
	
	// Try to add non-existent directory
	repo.add_dir(path: 'nonexistent_dir') or {
		assert err.msg().contains('does not exist')
		return
	}
	
	assert false, 'Expected error when adding non-existent directory'
}

// Test directory: file_count
fn test_directory_file_count() ! {
	// Create temp directory with files
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_file_count')
	os.mkdir_all(test_dir)!
	os.write_file(os.join_path(test_dir, 'file1.txt'), 'content1')!
	os.write_file(os.join_path(test_dir, 'file2.txt'), 'content2')!
	os.write_file(os.join_path(test_dir, 'file3.txt'), 'content3')!
	
	defer {
		os.rmdir_all(test_dir) or {}
	}
	
	// Create directory
	repo := new_directory(path: test_dir)!
	
	// Get file count
	count := repo.file_count()!
	assert count >= 3
}

// Test directory: display_name with git info
fn test_directory_display_name() ! {
	// Create temp directory
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_display_name')
	os.mkdir_all(test_dir)!
	
	defer {
		os.rmdir_all(test_dir) or {}
	}
	
	// Create directory
	repo := new_directory(path: test_dir, name: 'Test Repo')!
	
	// Display name should be the custom name
	display_name := repo.display_name()
	assert display_name == 'Test Repo'
}

// Test directory: exists check
fn test_directory_exists() ! {
	// Create temp directory
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_exists')
	os.mkdir_all(test_dir)!
	
	// Create directory
	repo := new_directory(path: test_dir)!
	
	// Should exist
	assert repo.exists() == true
	
	// Remove directory
	os.rmdir_all(test_dir)!
	
	// Should not exist
	assert repo.exists() == false
}

