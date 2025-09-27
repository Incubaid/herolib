module herofs

fn test_filesystem_crud() ! {
	// Initialize HeroFS factory
	mut fs_factory := new()!

	// Test filesystem creation
	mut test_fs := fs_factory.fs.new(
		name:        'crud_test'
		description: 'Test filesystem for CRUD operations'
		quota_bytes: 1024 * 1024 * 100 // 100MB quota
	)!

	test_fs = fs_factory.fs.set(test_fs)!

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
	test_fs = fs_factory.fs.set(test_fs)!

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
	mut fs_factory := new()!

	// Create test filesystem
	mut test_fs := fs_factory.fs.new_get_set(
		name:        'dir_test'
		description: 'Test filesystem for directory operations'
		quota_bytes: 1024 * 1024 * 50 // 50MB quota
	)!

	// Test directory creation
	mut sub_dir1 := fs_factory.fs_dir.new(
		name:        'documents'
		fs_id:       test_fs.id
		parent_id:   test_fs.root_dir_id
		description: 'Documents directory'
	)!
	sub_dir1 = fs_factory.fs_dir.set(sub_dir1)!

	// Add subdirectory to parent
	mut root_dir := fs_factory.fs_dir.get(test_fs.root_dir_id)!
	root_dir.directories << sub_dir1.id
	root_dir = fs_factory.fs_dir.set(root_dir)!

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
	mut fs_factory := new()!

	// Create test filesystem with root directory
	mut test_fs := fs_factory.fs.new_get_set(
		name:        'file_test'
		description: 'Test filesystem for file operations'
		quota_bytes: 1024 * 1024 * 50 // 50MB quota
	)!

	// Create test blob
	test_content := 'Hello, HeroFS! This is test content.'.bytes()
	mut test_blob := fs_factory.fs_blob.new(data: test_content)!
	test_blob = fs_factory.fs_blob.set(test_blob)!

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
	test_file = fs_factory.fs_file.set(test_file)!

	// Add file to root directory
	fs_factory.fs_file.add_to_directory(test_file.id, test_fs.root_dir_id)!

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
	updated_file = fs_factory.fs_file.set(updated_file)!

	// Verify metadata was updated
	final_file := fs_factory.fs_file.get(test_file.id)!
	assert final_file.metadata['author'] == 'updated_user'
	assert final_file.metadata['version'] == '2.0'

	// Test file renaming
	fs_factory.fs_file.rename(test_file.id, 'renamed_test.txt')!
	renamed_file := fs_factory.fs_file.get(test_file.id)!
	assert renamed_file.name == 'renamed_test.txt'

	// Test file listing by directory
	files_in_root := fs_factory.fs_file.list_by_directory(test_fs.root_dir_id)!
	assert files_in_root.len == 1
	assert files_in_root[0].id == test_file.id

	println('✓ File operations tests passed!')
}