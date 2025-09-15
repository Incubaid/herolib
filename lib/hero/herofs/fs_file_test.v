module herofs

import freeflowuniverse.herolib.hero.db

fn test_basic() {
	println('Testing FsFile functionality...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!
	println('HeroFS factory initialized')

	// Create a new filesystem (required for FsFile)
	mut my_fs := fs_factory.fs.new(
		name:        'test_filesystem'
		description: 'Filesystem for testing FsFile functionality'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem to get an ID
	fs_factory.fs.set(mut my_fs)!
	fs_id := my_fs.id
	println('Created test filesystem with ID: ${fs_id}')

	// Create test directories for files
	mut test_dir1 := fs_factory.fs_dir.new(
		name:        'test_dir1'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'First test directory for files'
	)!
	dir1_id := test_dir1.id

	mut test_dir2 := fs_factory.fs_dir.new(
		name:        'test_dir2'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Second test directory for files'
	)!
	fs_factory.fs_dir.set(mut test_dir2)!
	dir2_id := test_dir2.id

	// Create test blobs for files
	mut test_blob1 := fs_factory.fs_blob.new(
		data: 'This is test content for blob 1'.bytes()
	)!
	blob1_id := fs_factory.fs_blob.set(test_blob1)!
	println('Created test blob with ID: ${blob1_id}')

	mut test_blob2 := fs_factory.fs_blob.new(
		data: 'This is test content for blob 2'.bytes()
	)!
	blob2_id := fs_factory.fs_blob.set(test_blob2)!
	println('Created test blob with ID: ${blob2_id}')

	// Create test files with various parameters
	mut test_file1 := fs_factory.fs_file.new(
		name:        'test_file1.txt'
		fs_id:       fs_id
		directories: [dir1_id]
		blobs:       [blob1_id]
		description: 'First test file'
		mime_type:   .txt
		checksum:    'test_checksum_1'
		metadata:    {
			'author':  'test_user1'
			'version': '1.0'
		}
	)!

	mut test_file2 := fs_factory.fs_file.new(
		name:        'test_file2.png'
		fs_id:       fs_id
		directories: [dir1_id, dir2_id]   // Multiple directories (hard links)
		blobs:       [blob1_id, blob2_id] // Multiple blobs
		description: 'Second test file with multiple directories and blobs'
		mime_type:   .png
		checksum:    'test_checksum_2'
		metadata:    {
			'author':  'test_user2'
			'version': '2.0'
			'created': '2023-01-01'
		}
		tags:        ['test', 'image', 'example']
	)!

	mut test_file3 := fs_factory.fs_file.new(
		name:        'test_file3.json'
		fs_id:       fs_id
		directories: [dir2_id]
		blobs:       [blob2_id]
		description: 'Third test file with comments'
		mime_type:   .json
		checksum:    'test_checksum_3'
		metadata:    {
			'author':  'test_user3'
			'version': '1.5'
		}
		comments:    [
			db.CommentArg{
				comment: 'This is a test comment for file 3'
				author:  1
			},
		]
	)!

	// Save the test files
	file1_id := fs_factory.fs_file.set(test_file1)!
	file2_id := fs_factory.fs_file.set(test_file2)!
	file3_id := fs_factory.fs_file.set(test_file3)!

	println('Created test files:')
	println('- ${test_file1.name} with ID: ${file1_id}')
	println('- ${test_file2.name} with ID: ${file2_id}')
	println('- ${test_file3.name} with ID: ${file3_id}')

	// Test loading files by ID
	println('\nTesting file loading...')

	loaded_file1 := fs_factory.fs_file.get(file1_id)!
	assert loaded_file1.name == test_file1.name
	assert loaded_file1.description == test_file1.description
	assert loaded_file1.fs_id == test_file1.fs_id
	assert loaded_file1.directories == test_file1.directories
	assert loaded_file1.blobs == test_file1.blobs
	assert loaded_file1.mime_type == test_file1.mime_type
	assert loaded_file1.checksum == test_file1.checksum
	assert loaded_file1.metadata == test_file1.metadata
	println('✓ Loaded test_file1: ${loaded_file1.name} (ID: ${loaded_file1.id})')

	loaded_file2 := fs_factory.fs_file.get(file2_id)!
	assert loaded_file2.name == test_file2.name
	assert loaded_file2.description == test_file2.description
	assert loaded_file2.fs_id == test_file2.fs_id
	assert loaded_file2.directories.len == 2
	assert loaded_file2.directories[0] == dir1_id
	assert loaded_file2.directories[1] == dir2_id
	assert loaded_file2.blobs.len == 2
	assert loaded_file2.blobs[0] == blob1_id
	assert loaded_file2.blobs[1] == blob2_id
	assert loaded_file2.mime_type == test_file2.mime_type
	assert loaded_file2.checksum == test_file2.checksum
	assert loaded_file2.metadata == test_file2.metadata
	assert loaded_file2.tags == test_file2.tags
	println('✓ Loaded test_file2: ${loaded_file2.name} (ID: ${loaded_file2.id})')

	loaded_file3 := fs_factory.fs_file.get(file3_id)!
	assert loaded_file3.name == test_file3.name
	assert loaded_file3.description == test_file3.description
	assert loaded_file3.fs_id == test_file3.fs_id
	assert loaded_file3.directories == test_file3.directories
	assert loaded_file3.blobs == test_file3.blobs
	assert loaded_file3.mime_type == test_file3.mime_type
	assert loaded_file3.checksum == test_file3.checksum
	assert loaded_file3.metadata == test_file3.metadata
	println('✓ Loaded test_file3: ${loaded_file3.name} (ID: ${loaded_file3.id})')

	// Verify that loaded files match the original ones
	println('\nVerifying data integrity...')
	println('✓ All file data integrity checks passed')

	// Test exist method
	println('\nTesting file existence checks...')

	mut exists := fs_factory.fs_file.exist(file1_id)!
	assert exists == true
	println('✓ Test file 1 exists: ${exists}')

	exists = fs_factory.fs_file.exist(file2_id)!
	assert exists == true
	println('✓ Test file 2 exists: ${exists}')

	exists = fs_factory.fs_file.exist(file3_id)!
	assert exists == true
	println('✓ Test file 3 exists: ${exists}')

	// Test with non-existent ID
	exists = fs_factory.fs_file.exist(999999)!
	assert exists == false
	println('✓ Non-existent file exists: ${exists}')

	println('\nFsFile basic test completed successfully!')
}

fn test_file_operations() {
	println('\nTesting FsFile operations...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!

	// Create a new filesystem (required for FsFile)
	mut my_fs := fs_factory.fs.new(
		name:        'test_filesystem_ops'
		description: 'Filesystem for testing FsFile operations'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem to get an ID
	fs_factory.fs.set(mut my_fs)!
	fs_id := my_fs.id

	// Create test directory
	mut test_dir := fs_factory.fs_dir.new(
		name:        'test_dir'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Test directory for file operations'
	)!
	dir_id := fs_factory.fs_dir.set(test_dir)!

	// Create test blob
	mut test_blob := fs_factory.fs_blob.new(
		data: 'Test content for operations'.bytes()
	)!
	blob_id := fs_factory.fs_blob.set(test_blob)!

	// Create a test file
	test_file := fs_factory.fs_file.new(
		name:        'test_operations.txt'
		fs_id:       fs_id
		directories: [dir_id]
		blobs:       [blob_id]
		description: 'File for testing operations'
		mime_type:   .txt
		checksum:    'test_checksum_ops'
		metadata:    {
			'author':  'test_user_ops'
			'version': '1.0'
		}
	)!

	// Save the test file
	file_id := fs_factory.fs_file.set(test_file)!
	println('Created test file with ID: ${file_id}')

	// Test update_accessed method
	println('Testing update_accessed operation...')

	// Get original accessed_at timestamp
	original_file := fs_factory.fs_file.get(file_id)!
	original_accessed_at := original_file.accessed_at

	// Update accessed timestamp
	mut updated_file_id := fs_factory.fs_file.update_accessed(file_id)!
	mut updated_file := fs_factory.fs_file.get(updated_file_id)!

	// Verify that accessed_at was updated
	assert updated_file.accessed_at >= original_accessed_at
	println('✓ File accessed timestamp updated successfully')

	// Test update_metadata method
	println('Testing update_metadata operation...')

	// Add new metadata key-value pair
	updated_file_id = fs_factory.fs_file.update_metadata(file_id, 'new_key', 'new_value')!
	updated_file = fs_factory.fs_file.get(updated_file_id)!

	// Verify that metadata was updated
	assert updated_file.metadata['new_key'] == 'new_value'
	assert updated_file.metadata['author'] == 'test_user_ops' // Original key should still exist
	println('✓ File metadata updated successfully')

	// Update existing metadata key
	updated_file_id = fs_factory.fs_file.update_metadata(file_id, 'author', 'updated_user')!
	updated_file = fs_factory.fs_file.get(updated_file_id)!

	// Verify that existing metadata key was updated
	assert updated_file.metadata['author'] == 'updated_user'
	assert updated_file.metadata['version'] == '1.0' // Other keys should still exist
	println('✓ Existing file metadata key updated successfully')

	println('FsFile operations test completed successfully!')
}

fn test_file_deletion() {
	println('\nTesting FsFile deletion...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!

	// Create a new filesystem (required for FsFile)
	mut my_fs := fs_factory.fs.new(
		name:        'test_filesystem_delete'
		description: 'Filesystem for testing FsFile deletion'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem to get an ID
	fs_factory.fs.set(mut my_fs)!
	fs_id := my_fs.id

	// Create test directory
	mut test_dir := fs_factory.fs_dir.new(
		name:        'test_dir'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Test directory for file deletion'
	)!
	dir_id := fs_factory.fs_dir.set(test_dir)!

	// Create test blob
	mut test_blob := fs_factory.fs_blob.new(
		data: 'Test content for deletion'.bytes()
	)!
	blob_id := fs_factory.fs_blob.set(test_blob)!

	// Create a test file
	mut test_file := fs_factory.fs_file.new(
		name:        'test_delete.txt'
		fs_id:       fs_id
		directories: [dir_id]
		blobs:       [blob_id]
		description: 'File for testing deletion'
		mime_type:   .txt
		checksum:    'test_checksum_delete'
		metadata:    {
			'author':  'test_user_delete'
			'version': '1.0'
		}
	)!

	// Save the test file
	file_id := fs_factory.fs_file.set(test_file)!

	// Verify file exists
	mut exists := fs_factory.fs_file.exist(file_id)!
	assert exists == true
	println('✓ File exists before deletion')

	// Delete the file
	fs_factory.fs_file.delete(file_id)!

	// Verify file no longer exists
	exists = fs_factory.fs_file.exist(file_id)!
	assert exists == false
	println('✓ File no longer exists after deletion')

	println('FsFile deletion test completed successfully!')
}

fn test_file_validation() {
	println('\nTesting FsFile validation...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!

	// Create a new filesystem (required for FsFile)
	mut my_fs := fs_factory.fs.new(
		name:        'test_filesystem_validation'
		description: 'Filesystem for testing FsFile validation'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem to get an ID
	fs_factory.fs.set(mut my_fs)!
	fs_id := my_fs.id

	// Create test directory
	mut test_dir := fs_factory.fs_dir.new(
		name:        'test_dir'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Test directory for file validation'
	)!
	dir_id := fs_factory.fs_dir.set(test_dir)!

	// Create test blob
	mut test_blob := fs_factory.fs_blob.new(
		data: 'Test content for validation'.bytes()
	)!
	blob_id := fs_factory.fs_blob.set(test_blob)!

	// Test creating file with non-existent directory (should fail)
	println('Testing file creation with non-existent directory...')
	mut directories := []u32{len: 1}
	directories[0] = 999999 // Non-existent directory ID
	mut validation_result := fs_factory.fs_file.new(
		name:        'validation_test.txt'
		fs_id:       fs_id
		directories: directories
		blobs:       [blob_id]
		description: 'File for testing validation'
		mime_type:   .txt
	) or {
		println('✓ File creation correctly failed with non-existent directory')
		return
	}

	// If we get here, the validation didn't work as expected
	// Try to save it, which should fail
	validation_result_id := fs_factory.fs_file.set(validation_result) or {
		println('✓ File set correctly failed with non-existent directory')
		return
	}
	panic('Validation should have failed for non-existent directory')

	// Test creating file with non-existent blob (should fail)
	println('Testing file creation with non-existent blob...')
	mut blobs := []u32{len: 1}
	blobs[0] = 999999 // Non-existent blob ID
	mut validation_result2 := fs_factory.fs_file.new(
		name:        'validation_test2.txt'
		fs_id:       fs_id
		directories: [dir_id]
		blobs:       blobs
		description: 'File for testing validation with blob'
		mime_type:   .txt
	) or {
		println('✓ File creation correctly failed with non-existent blob')
		return
	}

	// If we get here, the validation didn't work as expected
	// Try to save it, which should fail
	validation_result_id2 := fs_factory.fs_file.set(validation_result2) or {
		println('✓ File set correctly failed with non-existent blob')
		return
	}
	panic('Validation should have failed for non-existent blob')

	println('FsFile validation test completed successfully!')
}
