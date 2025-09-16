module herofs

import freeflowuniverse.herolib.hero.herofs

fn test_filesystem_crud() ! {
	// Initialize HeroFS factory
	mut fs_factory := herofs.new()!

	// Test filesystem creation
	mut test_fs := fs_factory.fs.new(
		name:        'crud_test'
		description: 'Test filesystem for CRUD operations'
		quota_bytes: 1024 * 1024 * 100 // 100MB quota
	)!

	original_id := test_fs.id
	fs_factory.fs.set(mut test_fs)!

	// Test filesystem retrieval
	retrieved_fs := fs_factory.fs.get(test_fs.id)!
	assert retrieved_fs.name == 'crud_test'
	assert retrieved_fs.description == 'Test filesystem for CRUD operations'
	assert retrieved_fs.quota_bytes == 1024 * 1024 * 100

	// Test filesystem existence
	exists := fs_factory.fs.exist(test_fs.id)!
	assert exists == true

	// Test filesystem update
	test_fs.description = 'Updated description'
	fs_factory.fs.set(mut test_fs)!

	updated_fs := fs_factory.fs.get(test_fs.id)!
	assert updated_fs.description == 'Updated description'

	// Test filesystem deletion
	fs_factory.fs.delete(test_fs.id)!

	exists_after_delete := fs_factory.fs.exist(test_fs.id)!
	assert exists_after_delete == false

	println('✓ Filesystem CRUD tests passed!')
}

fn test_directory_operations() ! {
	// Initialize HeroFS factory
	mut fs_factory := herofs.new()!

	// Create test filesystem
	mut test_fs := fs_factory.fs.new(
		name:        'dir_test'
		description: 'Test filesystem for directory operations'
		quota_bytes: 1024 * 1024 * 50 // 50MB quota
	)!
	fs_factory.fs.set(mut test_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     test_fs.id
		parent_id: 0
	)!
	fs_factory.fs_dir.set(mut root_dir)!
	test_fs.root_dir_id = root_dir.id
	fs_factory.fs.set(mut test_fs)!

	// Test directory creation
	mut sub_dir1 := fs_factory.fs_dir.new(
		name:        'documents'
		fs_id:       test_fs.id
		parent_id:   root_dir.id
		description: 'Documents directory'
	)!
	fs_factory.fs_dir.set(mut sub_dir1)!

	// Add subdirectory to parent
	root_dir.directories << sub_dir1.id
	fs_factory.fs_dir.set(mut root_dir)!

	// Test directory retrieval
	retrieved_dir := fs_factory.fs_dir.get(sub_dir1.id)!
	assert retrieved_dir.name == 'documents'
	assert retrieved_dir.parent_id == root_dir.id

	// Test directory path creation
	projects_dir_id := fs_factory.fs_dir.create_path(test_fs.id, '/projects/web/frontend')!
	projects_dir := fs_factory.fs_dir.get(projects_dir_id)!
	assert projects_dir.name == 'frontend'

	// Test directory hierarchy
	parent_dir := fs_factory.fs_dir.get(projects_dir.parent_id)!
	assert parent_dir.name == 'web'

	grandparent_dir := fs_factory.fs_dir.get(parent_dir.parent_id)!
	assert grandparent_dir.name == 'projects'

	// Test directory listing
	has_children := fs_factory.fs_dir.has_children(root_dir.id)!
	assert has_children == true

	children := fs_factory.fs_dir.list_children(root_dir.id)!
	assert children.len >= 2 // documents and projects

	// Test directory renaming
	fs_factory.fs_dir.rename(sub_dir1.id, 'my_documents')!
	renamed_dir := fs_factory.fs_dir.get(sub_dir1.id)!
	assert renamed_dir.name == 'my_documents'

	println('✓ Directory operations tests passed!')
}

fn test_file_operations() ! {
	// Initialize HeroFS factory
	mut fs_factory := herofs.new()!

	// Create test filesystem with root directory
	mut test_fs := fs_factory.fs.new(
		name:        'file_test'
		description: 'Test filesystem for file operations'
		quota_bytes: 1024 * 1024 * 50 // 50MB quota
	)!
	fs_factory.fs.set(mut test_fs)!

	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     test_fs.id
		parent_id: 0
	)!
	fs_factory.fs_dir.set(mut root_dir)!
	test_fs.root_dir_id = root_dir.id
	fs_factory.fs.set(mut test_fs)!

	// Create test blob
	test_content := 'Hello, HeroFS! This is test content.'.bytes()
	mut test_blob := fs_factory.fs_blob.new(data: test_content)!
	fs_factory.fs_blob.set(mut test_blob)!

	// Test file creation
	mut test_file := fs_factory.fs_file.new(
		name:        'test.txt'
		fs_id:       test_fs.id
		blobs:       [test_blob.id]
		mime_type:   .txt
		description: 'Test file'
		metadata:    {
			'author':  'test_user'
			'version': '1.0'
		}
	)!
	fs_factory.fs_file.set(mut test_file)!

	// Add file to root directory
	fs_factory.fs_file.add_to_directory(test_file.id, root_dir.id)!

	// Test file retrieval
	retrieved_file := fs_factory.fs_file.get(test_file.id)!
	assert retrieved_file.name == 'test.txt'
	assert retrieved_file.blobs.len == 1
	assert retrieved_file.metadata['author'] == 'test_user'

	// Test file content retrieval
	file_blob := fs_factory.fs_blob.get(retrieved_file.blobs[0])!
	assert file_blob.data == test_content

	// Test file metadata update (update individual metadata fields)
	mut updated_file := fs_factory.fs_file.get(test_file.id)!
	updated_file.metadata['author'] = 'updated_user'
	updated_file.metadata['version'] = '2.0'
	fs_factory.fs_file.set(mut updated_file)!

	// Verify metadata was updated
	final_file := fs_factory.fs_file.get(test_file.id)!
	assert final_file.metadata['author'] == 'updated_user'
	assert final_file.metadata['version'] == '2.0'

	// Test file renaming
	fs_factory.fs_file.rename(test_file.id, 'renamed_test.txt')!
	renamed_file := fs_factory.fs_file.get(test_file.id)!
	assert renamed_file.name == 'renamed_test.txt'

	// Test file listing by directory
	files_in_root := fs_factory.fs_file.list_by_directory(root_dir.id)!
	assert files_in_root.len == 1
	assert files_in_root[0].id == test_file.id

	// Test file listing by filesystem
	files_in_fs := fs_factory.fs_file.list_by_filesystem(test_fs.id)!
	assert files_in_fs.len == 1

	// Test file listing by MIME type - create a specific file for this test
	mime_test_content := 'MIME type test content'.bytes()
	mut mime_test_blob := fs_factory.fs_blob.new(data: mime_test_content)!
	fs_factory.fs_blob.set(mut mime_test_blob)!

	mut mime_test_file := fs_factory.fs_file.new(
		name:      'mime_test.txt'
		fs_id:     test_fs.id
		blobs:     [mime_test_blob.id]
		mime_type: .txt
	)!
	fs_factory.fs_file.set(mut mime_test_file)!
	fs_factory.fs_file.add_to_directory(mime_test_file.id, root_dir.id)!

	txt_files := fs_factory.fs_file.list_by_mime_type(.txt)!
	assert txt_files.len >= 1

	// Test blob content appending
	additional_content := '\nAppended content.'.bytes()
	mut additional_blob := fs_factory.fs_blob.new(data: additional_content)!
	fs_factory.fs_blob.set(mut additional_blob)!

	fs_factory.fs_file.append_blob(test_file.id, additional_blob.id)!
	updated_file_with_blob := fs_factory.fs_file.get(test_file.id)!
	assert updated_file_with_blob.blobs.len == 2

	println('✓ File operations tests passed!')
}

fn test_blob_operations() ! {
	// Initialize HeroFS factory
	mut fs_factory := herofs.new()!

	// Test blob creation and deduplication
	test_data1 := 'This is test data for blob operations.'.bytes()
	test_data2 := 'This is different test data.'.bytes()
	test_data3 := 'This is test data for blob operations.'.bytes() // Same as test_data1

	// Create first blob
	mut blob1 := fs_factory.fs_blob.new(data: test_data1)!
	fs_factory.fs_blob.set(mut blob1)!

	// Create second blob with different data
	mut blob2 := fs_factory.fs_blob.new(data: test_data2)!
	fs_factory.fs_blob.set(mut blob2)!

	// Create third blob with same data as first (should have same hash)
	mut blob3 := fs_factory.fs_blob.new(data: test_data3)!
	fs_factory.fs_blob.set(mut blob3)!

	// Test hash-based retrieval
	assert blob1.hash == blob3.hash // Same content should have same hash
	assert blob1.hash != blob2.hash // Different content should have different hash

	// Test blob retrieval by hash
	blob_by_hash := fs_factory.fs_blob.get_by_hash(blob1.hash)!
	assert blob_by_hash.data == test_data1

	// Test blob existence by hash
	exists_by_hash := fs_factory.fs_blob.exists_by_hash(blob1.hash)!
	assert exists_by_hash == true

	// Test blob integrity verification
	assert blob1.verify_integrity() == true
	assert blob2.verify_integrity() == true

	// Test blob verification by hash
	is_valid := fs_factory.fs_blob.verify(blob1.hash)!
	assert is_valid == true

	// Test blob size limits
	large_data := []u8{len: 2 * 1024 * 1024} // 2MB data
	fs_factory.fs_blob.new(data: large_data) or {
		println('✓ Blob size limit correctly enforced')
		// This should fail due to 1MB limit
	}

	println('✓ Blob operations tests passed!')
}

fn test_symlink_operations() ! {
	// Initialize HeroFS factory
	mut fs_factory := herofs.new()!

	// Create test filesystem with root directory
	mut test_fs := fs_factory.fs.new(
		name:        'symlink_test'
		description: 'Test filesystem for symlink operations'
		quota_bytes: 1024 * 1024 * 10 // 10MB quota
	)!
	fs_factory.fs.set(mut test_fs)!

	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     test_fs.id
		parent_id: 0
	)!
	fs_factory.fs_dir.set(mut root_dir)!
	test_fs.root_dir_id = root_dir.id
	fs_factory.fs.set(mut test_fs)!

	// Create a target file
	test_content := 'Target file content'.bytes()
	mut target_blob := fs_factory.fs_blob.new(data: test_content)!
	fs_factory.fs_blob.set(mut target_blob)!

	mut target_file := fs_factory.fs_file.new(
		name:      'target.txt'
		fs_id:     test_fs.id
		blobs:     [target_blob.id]
		mime_type: .txt
	)!
	fs_factory.fs_file.set(mut target_file)!
	fs_factory.fs_file.add_to_directory(target_file.id, root_dir.id)!

	// Create symlink
	mut test_symlink := fs_factory.fs_symlink.new(
		name:        'link_to_target.txt'
		fs_id:       test_fs.id
		parent_id:   root_dir.id
		target_id:   target_file.id
		target_type: .file
		description: 'Symlink to target file'
	)!
	fs_factory.fs_symlink.set(mut test_symlink)!

	// Add symlink to directory
	root_dir.symlinks << test_symlink.id
	fs_factory.fs_dir.set(mut root_dir)!

	// Test symlink retrieval
	retrieved_symlink := fs_factory.fs_symlink.get(test_symlink.id)!
	assert retrieved_symlink.name == 'link_to_target.txt'
	assert retrieved_symlink.target_id == target_file.id

	// Test symlink validation (should not be broken since target exists)
	is_broken := fs_factory.fs_symlink.is_broken(test_symlink.id)!
	assert is_broken == false

	// Test symlink listing by filesystem
	symlinks_in_fs := fs_factory.fs_symlink.list_by_filesystem(test_fs.id)!
	assert symlinks_in_fs.len == 1

	// Delete target file to make symlink broken
	fs_factory.fs_file.delete(target_file.id)!

	// Test broken symlink detection
	is_broken_after_delete := fs_factory.fs_symlink.is_broken(test_symlink.id)!
	assert is_broken_after_delete == true

	println('✓ Symlink operations tests passed!')
}
