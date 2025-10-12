module herofs

fn test_basic_operations() ! {
	mut fs := new_fs_test() or { panic(err) }
	defer {
		delete_fs_test() or {}
	}

	// Test basic file creation and retrieval
	mut test_blob := fs.factory.fs_blob.new(data: 'Hello, HeroFS!'.bytes())!
	test_blob = fs.factory.fs_blob.set(test_blob)!

	mut test_file := fs.factory.fs_file.new(
		name:      'test.txt'
		fs_id:     fs.id
		blobs:     [test_blob.id]
		mime_type: .txt
	)!
	test_file = fs.factory.fs_file.set(test_file)!
	fs.factory.fs_file.add_to_directory(test_file.id, fs.root_dir_id)!

	// Verify file was created
	retrieved_file := fs.factory.fs_file.get(test_file.id)!
	assert retrieved_file.name == 'test.txt'
	assert retrieved_file.blobs.len == 1

	// Test directory creation using create_path
	src_dir_id := fs.factory.fs_dir.create_path(fs.id, '/src')!
	docs_dir_id := fs.factory.fs_dir.create_path(fs.id, '/docs')!
	tests_dir_id := fs.factory.fs_dir.create_path(fs.id, '/tests')!

	// Verify directories were created
	src_dir := fs.factory.fs_dir.get(src_dir_id)!
	assert src_dir.name == 'src'

	docs_dir := fs.factory.fs_dir.get(docs_dir_id)!
	assert docs_dir.name == 'docs'

	tests_dir := fs.factory.fs_dir.get(tests_dir_id)!
	assert tests_dir.name == 'tests'

	// Test blob creation and hash-based retrieval
	test_data := 'Test blob content'.bytes()
	mut test_blob2 := fs.factory.fs_blob.new(data: test_data)!
	test_blob2 = fs.factory.fs_blob.set(test_blob2)!

	// Test hash-based retrieval
	retrieved_blob := fs.factory.fs_blob.get_by_hash(test_blob2.hash)!
	assert retrieved_blob.data == test_data

	// Test blob existence by hash
	exists := fs.factory.fs_blob.exists_by_hash(test_blob2.hash)!
	assert exists == true

	// Test blob integrity verification
	assert test_blob2.verify_integrity() == true

	println('✓ Basic operations test passed!')
}

fn test_rm_file() ! {
	mut fs := new_fs_test() or { panic(err) }
	defer {
		delete_fs_test() or {}
	}

	// Create a file to remove
	mut test_blob := fs.factory.fs_blob.new(data: 'File to remove'.bytes())!
	test_blob = fs.factory.fs_blob.set(test_blob)!

	mut test_file := fs.factory.fs_file.new(
		name:      'to_remove.txt'
		fs_id:     fs.id
		blobs:     [test_blob.id]
		mime_type: .txt
	)!
	test_file = fs.factory.fs_file.set(test_file)!
	fs.factory.fs_file.add_to_directory(test_file.id, fs.root_dir_id)!

	// Verify file exists before removal
	assert fs.factory.fs_file.exist(test_file.id)! == true

	// Test rm with file path
	fs.rm('/to_remove.txt', FindOptions{}, RemoveOptions{})!

	// Verify file no longer exists
	assert fs.factory.fs_file.exist(test_file.id)! == false

	// Verify blob still exists (default behavior)
	assert fs.factory.fs_blob.exist(test_blob.id)! == true

	println('✓ Remove file test passed!')
}

fn test_rm_file_with_blobs() ! {
	mut fs := new_fs_test() or { panic(err) }
	defer {
		delete_fs_test() or {}
	}

	// Create a file to remove with delete_blobs option
	mut test_blob := fs.factory.fs_blob.new(data: 'File to remove with blobs'.bytes())!
	test_blob = fs.factory.fs_blob.set(test_blob)!

	mut test_file := fs.factory.fs_file.new(
		name:      'to_remove_with_blobs.txt'
		fs_id:     fs.id
		blobs:     [test_blob.id]
		mime_type: .txt
	)!
	test_file = fs.factory.fs_file.set(test_file)!
	fs.factory.fs_file.add_to_directory(test_file.id, fs.root_dir_id)!

	// Verify file and blob exist before removal
	assert fs.factory.fs_file.exist(test_file.id)! == true
	assert fs.factory.fs_blob.exist(test_blob.id)! == true

	// Test rm with delete_blobs option
	fs.rm('/to_remove_with_blobs.txt', FindOptions{}, RemoveOptions{ delete_blobs: true })!

	// Verify file no longer exists
	assert fs.factory.fs_file.exist(test_file.id)! == false

	// Verify blob is also deleted
	assert fs.factory.fs_blob.exist(test_blob.id)! == false

	println('✓ Remove file with blobs test passed!')
}

fn test_rm_directory() ! {
	mut fs_factory := new()!
	mut test_fs := fs_factory.fs.new(
		name:        'rm_dir_test'
		description: 'Test filesystem for remove directory operations'
		quota_bytes: 1024 * 1024 * 50 // 50MB quota
	)!
	test_fs = fs_factory.fs.set(test_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     test_fs.id
		parent_id: 0 // Root has no parent
	)!
	root_dir = fs_factory.fs_dir.set(root_dir)!
	test_fs.root_dir_id = root_dir.id
	test_fs = fs_factory.fs.set(test_fs)!

	// Create a directory to remove
	test_dir_id := fs_factory.fs_dir.create_path(test_fs.id, '/test_dir')!
	test_dir := fs_factory.fs_dir.get(test_dir_id)!
	assert test_dir.name == 'test_dir'

	// Test rm with directory path
	test_fs.rm('/test_dir', FindOptions{}, RemoveOptions{})!

	// Verify directory no longer exists
	assert fs_factory.fs_dir.exist(test_dir_id)! == false

	println('✓ Remove directory test passed!')
}

fn test_rm_directory_recursive() ! {
	mut fs_factory := new()!
	mut test_fs := fs_factory.fs.new(
		name:        'rm_dir_recursive_test'
		description: 'Test filesystem for recursive remove directory operations'
		quota_bytes: 1024 * 1024 * 50 // 50MB quota
	)!
	test_fs = fs_factory.fs.set(test_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     test_fs.id
		parent_id: 0 // Root has no parent
	)!
	root_dir = fs_factory.fs_dir.set(root_dir)!
	test_fs.root_dir_id = root_dir.id
	test_fs = fs_factory.fs.set(test_fs)!

	// Create directory structure
	test_dir_id := fs_factory.fs_dir.create_path(test_fs.id, '/test_dir')!
	sub_dir_id := fs_factory.fs_dir.create_path(test_fs.id, '/test_dir/sub_dir')!

	// Create a file in the directory
	mut test_blob := fs_factory.fs_blob.new(data: 'File in directory'.bytes())!
	test_blob = fs_factory.fs_blob.set(test_blob)!
	mut test_file := fs_factory.fs_file.new(
		name:      'file_in_dir.txt'
		fs_id:     test_fs.id
		blobs:     [test_blob.id]
		mime_type: .txt
	)!
	test_file = fs_factory.fs_file.set(test_file)!
	fs_factory.fs_file.add_to_directory(test_file.id, test_dir_id)!

	// Verify directory and file exist before removal
	assert fs_factory.fs_dir.exist(test_dir_id)! == true
	assert fs_factory.fs_dir.exist(sub_dir_id)! == true
	assert fs_factory.fs_file.exist(test_file.id)! == true

	// Test rm with recursive option
	test_fs.rm('/test_dir', FindOptions{}, RemoveOptions{ recursive: true })!

	// Verify directory and its contents are removed
	assert fs_factory.fs_dir.exist(test_dir_id)! == false
	assert fs_factory.fs_dir.exist(sub_dir_id)! == false
	assert fs_factory.fs_file.exist(test_file.id)! == false

	println('✓ Remove directory recursively test passed!')
}

fn test_mv_file() ! {
	mut fs_factory := new()!
	mut test_fs := fs_factory.fs.new(
		name:        'mv_file_test'
		description: 'Test filesystem for move file operations'
		quota_bytes: 1024 * 1024 * 50 // 50MB quota
	)!
	test_fs = fs_factory.fs.set(test_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     test_fs.id
		parent_id: 0 // Root has no parent
	)!
	root_dir = fs_factory.fs_dir.set(root_dir)!
	test_fs.root_dir_id = root_dir.id
	test_fs = fs_factory.fs.set(test_fs)!

	// Create source directory
	src_dir_id := fs_factory.fs_dir.create_path(test_fs.id, '/src')!

	// Create destination directory
	dest_dir_id := fs_factory.fs_dir.create_path(test_fs.id, '/dest')!

	// Create a file to move
	mut test_blob := fs_factory.fs_blob.new(data: 'File to move'.bytes())!
	test_blob = fs_factory.fs_blob.set(test_blob)!
	mut test_file := fs_factory.fs_file.new(
		name:      'to_move.txt'
		fs_id:     test_fs.id
		blobs:     [test_blob.id]
		mime_type: .txt
	)!
	test_file = fs_factory.fs_file.set(test_file)!
	fs_factory.fs_file.add_to_directory(test_file.id, src_dir_id)!

	// Verify file exists in source directory before move
	src_dir := fs_factory.fs_dir.get(src_dir_id)!
	assert test_file.id in src_dir.files

	// Test mv file operation
	test_fs.mv('/src/to_move.txt', '/dest/', MoveOptions{})!

	// Verify file no longer exists in source directory
	src_dir = fs_factory.fs_dir.get(src_dir_id)!
	assert test_file.id !in src_dir.files

	// Verify file exists in destination directory
	dest_dir := fs_factory.fs_dir.get(dest_dir_id)!
	assert dest_dir.files.len == 1
	moved_file := fs_factory.fs_file.get(dest_dir.files[0])!
	assert moved_file.name == 'to_move.txt'

	println('✓ Move file test passed!')
}

fn test_mv_file_rename() ! {
	mut fs_factory := new()!
	mut test_fs := fs_factory.fs.new(
		name:        'mv_file_rename_test'
		description: 'Test filesystem for move and rename file operations'
		quota_bytes: 1024 * 1024 * 50 // 50MB quota
	)!
	test_fs = fs_factory.fs.set(test_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     test_fs.id
		parent_id: 0 // Root has no parent
	)!
	root_dir = fs_factory.fs_dir.set(root_dir)!
	test_fs.root_dir_id = root_dir.id
	test_fs = fs_factory.fs.set(test_fs)!

	// Create source directory
	src_dir_id := fs_factory.fs_dir.create_path(test_fs.id, '/src')!

	// Create a file to move and rename
	mut test_blob := fs_factory.fs_blob.new(data: 'File to move and rename'.bytes())!
	test_blob = fs_factory.fs_blob.set(test_blob)!
	mut test_file := fs_factory.fs_file.new(
		name:      'original_name.txt'
		fs_id:     test_fs.id
		blobs:     [test_blob.id]
		mime_type: .txt
	)!
	test_file = fs_factory.fs_file.set(test_file)!
	fs_factory.fs_file.add_to_directory(test_file.id, src_dir_id)!

	// Test mv with rename
	test_fs.mv('/src/original_name.txt', '/src/renamed_file.txt', MoveOptions{})!

	// Verify file was renamed
	renamed_file := fs_factory.fs_file.get(test_file.id)!
	assert renamed_file.name == 'renamed_file.txt'

	println('✓ Move file with rename test passed!')
}

fn test_mv_directory() ! {
	mut fs_factory := new()!
	mut test_fs := fs_factory.fs.new(
		name:        'mv_dir_test'
		description: 'Test filesystem for move directory operations'
		quota_bytes: 1024 * 1024 * 50 // 50MB quota
	)!
	test_fs = fs_factory.fs.set(test_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     test_fs.id
		parent_id: 0 // Root has no parent
	)!
	root_dir = fs_factory.fs_dir.set(root_dir)!
	test_fs.root_dir_id = root_dir.id
	test_fs = fs_factory.fs.set(test_fs)!

	// Create source directory
	src_dir_id := fs_factory.fs_dir.create_path(test_fs.id, '/src')!

	// Create destination directory
	dest_dir_id := fs_factory.fs_dir.create_path(test_fs.id, '/dest')!

	// Create a subdirectory to move
	sub_dir_id := fs_factory.fs_dir.create_path(test_fs.id, '/src/sub_dir')!
	sub_dir := fs_factory.fs_dir.get(sub_dir_id)!
	assert sub_dir.name == 'sub_dir'

	// Test mv directory operation
	test_fs.mv('/src/sub_dir', '/dest/', MoveOptions{})!

	// Verify directory no longer exists in source
	src_dir := fs_factory.fs_dir.get(src_dir_id)!
	assert sub_dir_id !in src_dir.directories

	// Verify directory exists in destination
	dest_dir := fs_factory.fs_dir.get(dest_dir_id)!
	assert dest_dir.directories.len == 1
	moved_dir := fs_factory.fs_dir.get(dest_dir.directories[0])!
	assert moved_dir.name == 'sub_dir'
	assert moved_dir.parent_id == dest_dir_id

	println('✓ Move directory test passed!')
}
