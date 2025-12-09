module heroprompt

import os

// Test file: create new file
fn test_new_file() ! {
	// Create temp file
	temp_base := os.temp_dir()
	test_file := os.join_path(temp_base, 'test_heroprompt_new_file.txt')
	os.write_file(test_file, 'test content')!

	defer {
		os.rm(test_file) or {}
	}

	// Create HeropromptFile
	file := new_file(path: test_file)!

	assert file.name == 'test_heroprompt_new_file.txt'
	assert file.content == 'test content'
	assert file.path == os.real_path(test_file)
	assert file.id.len > 0
}

// Test file: create file with non-existent path
fn test_new_file_nonexistent() ! {
	// Try to create file with non-existent path
	new_file(path: '/nonexistent/path/file.txt') or {
		assert err.msg().contains('not an existing file')
		return
	}

	assert false, 'Expected error when creating file with non-existent path'
}

// Test file: refresh content
fn test_file_refresh() ! {
	// Create temp file
	temp_base := os.temp_dir()
	test_file := os.join_path(temp_base, 'test_heroprompt_refresh.txt')
	os.write_file(test_file, 'initial content')!

	defer {
		os.rm(test_file) or {}
	}

	// Create HeropromptFile
	mut file := new_file(path: test_file)!
	assert file.content == 'initial content'

	// Modify file on disk
	os.write_file(test_file, 'updated content')!

	// Refresh file
	file.refresh()!
	assert file.content == 'updated content'
}

// Test file: exists check
fn test_file_exists() ! {
	// Create temp file
	temp_base := os.temp_dir()
	test_file := os.join_path(temp_base, 'test_heroprompt_file_exists.txt')
	os.write_file(test_file, 'content')!

	// Create HeropromptFile
	file := new_file(path: test_file)!

	// Should exist
	assert file.exists() == true

	// Remove file
	os.rm(test_file)!

	// Should not exist
	assert file.exists() == false
}

// Test file: get extension
fn test_file_extension() ! {
	// Create temp files with different extensions
	temp_base := os.temp_dir()

	test_files := {
		'test.txt':       'txt'
		'test.v':         'v'
		'test.py':        'py'
		'archive.tar.gz': 'gz'
		'.gitignore':     'gitignore'
		'Dockerfile':     'dockerfile'
		'Makefile':       'makefile'
		'README':         'readme'
	}

	for filename, expected_ext in test_files {
		test_file := os.join_path(temp_base, filename)
		os.write_file(test_file, 'content')!

		file := new_file(path: test_file)!
		actual_ext := file.extension()

		assert actual_ext == expected_ext, 'Expected ${expected_ext} for ${filename}, got ${actual_ext}'

		os.rm(test_file)!
	}
}

// Test get_file_extension utility function
fn test_get_file_extension() ! {
	// Regular files
	assert get_file_extension('test.txt') == 'txt'
	assert get_file_extension('main.v') == 'v'
	assert get_file_extension('script.py') == 'py'

	// Files with multiple dots
	assert get_file_extension('archive.tar.gz') == 'gz'
	assert get_file_extension('config.test.js') == 'js'

	// Dotfiles
	assert get_file_extension('.gitignore') == 'gitignore'
	assert get_file_extension('.env') == 'env'

	// Special files
	assert get_file_extension('Dockerfile') == 'dockerfile'
	assert get_file_extension('Makefile') == 'makefile'
	assert get_file_extension('README') == 'readme'
	assert get_file_extension('LICENSE') == 'license'

	// Files without extension
	assert get_file_extension('noextension') == ''
}

// Test file: generate UUIDs
fn test_file_unique_ids() ! {
	// Create temp file
	temp_base := os.temp_dir()
	test_file := os.join_path(temp_base, 'test_heroprompt_unique_id.txt')
	os.write_file(test_file, 'content')!

	defer {
		os.rm(test_file) or {}
	}

	// Create HeropromptFile instance
	file1 := new_file(path: test_file)!

	// ID should be a UUID (36 characters with dashes)
	assert file1.id.len == 36
	assert file1.id.contains('-')
}
