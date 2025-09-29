module herofs

fn test_symlink_operations() ! {
	// Initialize HeroFS factory
	mut fs_factory := new()!

	// Create test filesystem
	mut test_fs := fs_factory.fs.new(
		name:        'symlink_test'
		description: 'Test filesystem for symlink operations'
		quota_bytes: 1024 * 1024 * 10
	)!
	test_fs = fs_factory.fs.set(test_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     test_fs.id
		parent_id: 0
	)!
	root_dir = fs_factory.fs_dir.set(root_dir)!

	// Create a subdirectory
	mut sub_dir := fs_factory.fs_dir.new(
		name:      'subdir'
		fs_id:     test_fs.id
		parent_id: root_dir.id
	)!
	sub_dir = fs_factory.fs_dir.set(sub_dir)!

	// Create a test file
	test_content := 'Hello, symlink test!'.bytes()
	mut test_blob := fs_factory.fs_blob.new(data: test_content)!
	test_blob = fs_factory.fs_blob.set(test_blob)!

	mut test_file := fs_factory.fs_file.new(
		name:      'target.txt'
		fs_id:     test_fs.id
		blobs:     [test_blob.id]
		mime_type: .txt
	)!
	test_file = fs_factory.fs_file.set(test_file)!
	fs_factory.fs_file.add_to_directory(test_file.id, sub_dir.id)!

	// Test creating symlink to file
	mut file_symlink := fs_factory.fs_symlink.new(
		name:        'file_link'
		fs_id:       test_fs.id
		parent_id:   root_dir.id
		target_id:   test_file.id
		target_type: .file
	)!
	file_symlink = fs_factory.fs_symlink.set(file_symlink)!

	// Test creating symlink to directory
	mut dir_symlink := fs_factory.fs_symlink.new(
		name:        'dir_link'
		fs_id:       test_fs.id
		parent_id:   root_dir.id
		target_id:   sub_dir.id
		target_type: .directory
	)!
	dir_symlink = fs_factory.fs_symlink.set(dir_symlink)!

	// Test symlink retrieval
	retrieved_file_link := fs_factory.fs_symlink.get(file_symlink.id)!
	assert retrieved_file_link.name == 'file_link'
	assert retrieved_file_link.target_id == test_file.id
	assert retrieved_file_link.target_type == .file

	retrieved_dir_link := fs_factory.fs_symlink.get(dir_symlink.id)!
	assert retrieved_dir_link.name == 'dir_link'
	assert retrieved_dir_link.target_id == sub_dir.id
	assert retrieved_dir_link.target_type == .directory

	// Test symlink existence
	file_link_exists := fs_factory.fs_symlink.exist(file_symlink.id)!
	assert file_link_exists == true

	// Test listing symlinks
	all_symlinks := fs_factory.fs_symlink.list()!
	assert all_symlinks.len >= 2

	fs_symlinks := fs_factory.fs_symlink.list_by_filesystem(test_fs.id)!
	assert fs_symlinks.len == 2

	// Test broken symlink detection
	is_file_link_broken := fs_factory.fs_symlink.is_broken(file_symlink.id)!
	assert is_file_link_broken == false

	is_dir_link_broken := fs_factory.fs_symlink.is_broken(dir_symlink.id)!
	assert is_dir_link_broken == false

	// Test symlink deletion
	fs_factory.fs_symlink.delete(file_symlink.id)!
	
	file_link_exists_after_delete := fs_factory.fs_symlink.exist(file_symlink.id)!
	assert file_link_exists_after_delete == false

	println('✓ Symlink operations tests passed!')
}

fn test_broken_symlink_detection() ! {
	// Initialize HeroFS factory
	mut fs_factory := new()!

	// Create test filesystem
	mut test_fs := fs_factory.fs.new(
		name:        'broken_symlink_test'
		description: 'Test filesystem for broken symlink detection'
		quota_bytes: 1024 * 1024 * 10
	)!
	test_fs = fs_factory.fs.set(test_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     test_fs.id
		parent_id: 0
	)!
	root_dir = fs_factory.fs_dir.set(root_dir)!

	// Create a test file
	test_content := 'Temporary file'.bytes()
	mut test_blob := fs_factory.fs_blob.new(data: test_content)!
	test_blob = fs_factory.fs_blob.set(test_blob)!

	mut temp_file := fs_factory.fs_file.new(
		name:      'temp.txt'
		fs_id:     test_fs.id
		blobs:     [test_blob.id]
		mime_type: .txt
	)!
	temp_file = fs_factory.fs_file.set(temp_file)!

	// Create symlink to the file
	mut symlink := fs_factory.fs_symlink.new(
		name:        'temp_link'
		fs_id:       test_fs.id
		parent_id:   root_dir.id
		target_id:   temp_file.id
		target_type: .file
	)!
	symlink = fs_factory.fs_symlink.set(symlink)!

	// Verify symlink is not broken initially
	is_broken_before := fs_factory.fs_symlink.is_broken(symlink.id)!
	assert is_broken_before == false

	// Delete the target file
	fs_factory.fs_file.delete(temp_file.id)!

	// Now the symlink should be broken
	is_broken_after := fs_factory.fs_symlink.is_broken(symlink.id)!
	assert is_broken_after == true

	println('✓ Broken symlink detection works correctly!')
}
