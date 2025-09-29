module herofs

import freeflowuniverse.herolib.hero.db

fn test_cleanup() ! {
	delete_fs_test()!
}

fn test_basic() ! {
	defer {
		test_cleanup() or { panic('cleanup failed: ${err.msg()}') }
	}

	test_cleanup()!

	// Initialize the HeroFS factory for test purposes
	mut fs_factory := new()!

	// Create a new filesystem (required for FsBlobMembership validation)
	mut test_fs := fs_factory.fs.new_get_set(
		name:        'test_filesystem'
		description: 'Filesystem for testing FsBlobMembership functionality'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!
	println('Created test filesystem with ID: ${test_fs.id}')

	assert test_fs.id > 0
	assert test_fs.root_dir_id > 0

	mut root_dir := test_fs.root_dir()!

	// this means root_dir is automatically there, no need to create

	println(root_dir)

	// Create test blob for membership
	test_data := 'This is test content for blob membership'.bytes()
	mut test_blob := fs_factory.fs_blob.new(data: test_data)!
	test_blob = fs_factory.fs_blob.set(test_blob)!
	blob_id := test_blob.id
	println('Created test blob with ID: ${blob_id}')

	// Create test file to get a valid fsid (file ID) for membership
	mut test_file := fs_factory.fs_file.new(
		name:        'test_file.txt'
		fs_id:       test_fs.id
		blobs:       [blob_id]
		description: 'Test file for blob membership'
		mime_type:   .txt
	)!
	test_file = fs_factory.fs_file.set(test_file)!
	file_id := test_file.id
	println('Created test file with ID: ${file_id}')

	// Add file to directory
	mut dir := fs_factory.fs_dir.get(test_fs.root_dir_id)!
	dir.files << file_id
	dir = fs_factory.fs_dir.set(dir)!

	// Create test blob membership
	mut test_membership := fs_factory.fs_blob_membership.new(
		hash:   test_blob.hash
		fsid:   [test_fs.id] // Use filesystem ID
		blobid: blob_id
	)!

	// Save the test membership
	test_membership = fs_factory.fs_blob_membership.set(test_membership)!
	membership_hash := test_membership.hash
	println('Created test blob membership with hash: ${membership_hash}')

	// Test loading membership by hash
	println('Testing blob membership loading...')

	loaded_membership := fs_factory.fs_blob_membership.get(membership_hash)!
	assert loaded_membership.hash == test_membership.hash
	assert loaded_membership.fsid == test_membership.fsid
	assert loaded_membership.blobid == test_membership.blobid
	println('✓ Loaded blob membership: ${loaded_membership.hash} (Blob ID: ${loaded_membership.blobid})')

	// Verify that loaded membership matches the original one
	println('Verifying data integrity...')
	assert loaded_membership.hash == test_blob.hash
	println('✓ Blob membership data integrity check passed')

	// Test exist method
	println('Testing blob membership existence checks...')

	mut exists := fs_factory.fs_blob_membership.exist(membership_hash)!
	assert exists == true
	println('✓ Blob membership exists: ${exists}')

	// Test with non-existent hash
	non_existent_hash := '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
	exists = fs_factory.fs_blob_membership.exist(non_existent_hash)!
	assert exists == false
	println('✓ Non-existent blob membership exists: ${exists}')

	println('FsBlobMembership basic test completed successfully!')
}

fn test_filesystem_operations() ! {
	println('Testing FsBlobMembership filesystem operations...')

	defer {
		test_cleanup() or { panic('cleanup failed: ${err.msg()}') }
	}
	// Initialize the HeroFS factory for test purposes
	mut fs_factory := new()!

	// Create filesystems for testing
	mut fs1 := fs_factory.fs.new_get_set(
		name:        'test_filesystem_1'
		description: 'First filesystem for testing'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!
	fs1 = fs_factory.fs.set(fs1)!
	fs1_id := fs1.id

	mut fs2 := fs_factory.fs.new_get_set(
		name:        'test_filesystem_2'
		description: 'Second filesystem for testing'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!
	fs2 = fs_factory.fs.set(fs2)!
	fs1_root_dir_id := fs1.root_dir_id
	fs2_id := fs2.id

	// Create test blob
	test_data := 'This is test content for filesystem operations'.bytes()
	mut test_blob := fs_factory.fs_blob.new(data: test_data)!
	test_blob = fs_factory.fs_blob.set(test_blob)!
	blob_id := test_blob.id

	// Create test files to get valid fsid (file IDs) for membership
	mut test_file1 := fs_factory.fs_file.new(
		name:        'test_file1.txt'
		fs_id:       fs1_id
		blobs:       [blob_id]
		description: 'Test file 1 for blob membership'
		mime_type:   .txt
	)!
	test_file1 = fs_factory.fs_file.set(test_file1)!
	file1_id := test_file1.id
	println('Created test file 1 with ID: ${file1_id}')

	// Add file to directory
	mut fs1_root_dir := fs_factory.fs_dir.get(fs1.root_dir_id)!
	fs1_root_dir.files << file1_id
	fs1_root_dir = fs_factory.fs_dir.set(fs1_root_dir)!

	mut test_file2 := fs_factory.fs_file.new(
		name:        'test_file2.txt'
		fs_id:       fs2_id
		blobs:       [blob_id]
		description: 'Test file 2 for blob membership'
		mime_type:   .txt
	)!
	test_file2 = fs_factory.fs_file.set(test_file2)!
	file2_id := test_file2.id
	println('Created test file 2 with ID: ${file2_id}')

	// Add file to directory
	mut fs2_root_dir := fs_factory.fs_dir.get(fs2.root_dir_id)!
	fs2_root_dir.files << file2_id
	fs2_root_dir = fs_factory.fs_dir.set(fs2_root_dir)!

	// Create blob membership with first filesystem
	mut membership := fs_factory.fs_blob_membership.new(
		hash:   test_blob.hash
		fsid:   [fs1_id]
		blobid: blob_id
	)!
	membership = fs_factory.fs_blob_membership.set(membership)!
	membership_hash := membership.hash
	println('Created blob membership with filesystem 1: ${membership_hash}')

	// Test adding a filesystem to membership
	println('Testing add_filesystem operation...')

	// Add second filesystem
	fs_factory.fs_blob_membership.add_filesystem(membership_hash, fs2_id)!
	mut updated_membership := fs_factory.fs_blob_membership.get(membership_hash)!

	// Verify both filesystems are in the list
	assert updated_membership.fsid.len == 2
	assert fs1_id in updated_membership.fsid
	assert fs2_id in updated_membership.fsid
	println('✓ Added filesystem 2 to blob membership')

	// Test removing a filesystem from membership
	println('Testing remove_filesystem operation...')

	// Remove first filesystem
	fs_factory.fs_blob_membership.remove_filesystem(membership_hash, fs1_id)!
	mut updated_membership2 := fs_factory.fs_blob_membership.get(membership_hash)!

	// Verify only second filesystem is in the list
	assert updated_membership2.fsid.len == 1
	assert updated_membership2.fsid[0] == fs2_id
	println('✓ Removed filesystem 1 from blob membership')

	// Test removing the last filesystem (should delete the membership)
	fs_factory.fs_blob_membership.remove_filesystem(membership_hash, fs2_id)!

	// Verify membership no longer exists
	exists := fs_factory.fs_blob_membership.exist(membership_hash)!
	assert exists == false
	println('✓ Removed last filesystem and deleted blob membership')

	println('FsBlobMembership filesystem operations test completed successfully!')
}

fn test_validation() ! {
	println('Testing FsBlobMembership validation...')

	defer {
		test_cleanup() or { panic('cleanup failed: ${err.msg()}') }
	}
	// Initialize the HeroFS factory for test purposes
	mut fs_factory := new()!

	// Create a filesystem for validation tests
	mut test_fs := fs_factory.fs.new_get_set(
		name:        'validation_filesystem'
		description: 'Filesystem for validation tests'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!
	test_fs = fs_factory.fs.set(test_fs)!
	fs_id := test_fs.id

	// Test setting membership with non-existent blob (should fail)
	println('Testing membership set with non-existent blob...')

	// Create a membership with a non-existent blob ID
	mut test_membership := fs_factory.fs_blob_membership.new(
		hash:   '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
		fsid:   [test_fs.id]
		blobid: 999999 // Non-existent blob ID
	)!

	// Try to save it, which should fail
	test_membership = fs_factory.fs_blob_membership.set(test_membership) or {
		println('✓ Membership set correctly failed with non-existent blob')
		return
	}
	panic('Validation should have failed for non-existent blob')

	// Test setting membership with non-existent filesystem (should fail)
	println('Testing membership set with non-existent filesystem...')

	// Create a test blob
	test_data := 'This is test content for validation'.bytes()
	mut test_blob := fs_factory.fs_blob.new(data: test_data)!
	test_blob = fs_factory.fs_blob.set(test_blob)!
	blob_id := test_blob.id

	// Create a membership with a non-existent filesystem ID
	mut test_membership2 := fs_factory.fs_blob_membership.new(
		hash:   test_blob.hash
		fsid:   [u32(999999)] // Non-existent filesystem ID
		blobid: blob_id
	)!

	// Try to save it, which should fail
	test_membership2 = fs_factory.fs_blob_membership.set(test_membership2) or {
		println('✓ Membership set correctly failed with non-existent filesystem')
		return
	}
	panic('Validation should have failed for non-existent filesystem')

	println('FsBlobMembership validation test completed successfully!')
}

fn test_list_by_prefix() ! {
	println('
Testing FsBlobMembership list by prefix...')

	defer {
		test_cleanup() or { panic('cleanup failed: ${err.msg()}') }
	}
	// Initialize the HeroFS factory for test purposes
	mut fs_factory := new()!

	// Create a filesystem
	mut test_fs := fs_factory.fs.new_get_set(
		name:        'list_test_filesystem'
		description: 'Filesystem for list testing'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!
	test_fs = fs_factory.fs.set(test_fs)!
	fs_id := test_fs.id

	// Create root directory for the filesystem
	mut root_dir := fs_factory.fs_dir.new(
		name:        'root'
		fs_id:       fs_id
		parent_id:   0 // Root has no parent
		description: 'Root directory for testing'
	)!
	root_dir = fs_factory.fs_dir.set(root_dir)!
	root_dir_id := root_dir.id

	// Update the filesystem with the root directory ID
	test_fs.root_dir_id = root_dir_id
	test_fs = fs_factory.fs.set(test_fs)!

	// Create multiple test blobs
	test_data1 := 'This is test content 1'.bytes()
	test_data2 := 'This is test content 2'.bytes()
	test_data3 := 'This is test content 3'.bytes()

	mut blob1 := fs_factory.fs_blob.new(data: test_data1)!
	mut blob2 := fs_factory.fs_blob.new(data: test_data2)!
	mut blob3 := fs_factory.fs_blob.new(data: test_data3)!

	blob1 = fs_factory.fs_blob.set(blob1)!
	blob1_id := blob1.id
	blob2 = fs_factory.fs_blob.set(blob2)!
	blob2_id := blob2.id
	blob3 = fs_factory.fs_blob.set(blob3)!
	blob3_id := blob3.id

	// Create test files to get valid fsid (file IDs) for membership
	mut test_file := fs_factory.fs_file.new(
		name:        'test_file.txt'
		fs_id:       fs_id
		blobs:       [blob1_id]
		description: 'Test file for blob membership'
		mime_type:   .txt
	)!
	test_file = fs_factory.fs_file.set(test_file)!
	file_id := test_file.id
	println('Created test file with ID: ${file_id}')

	// Create memberships with similar hashes (first 16 characters)
	mut membership1 := fs_factory.fs_blob_membership.new(
		hash:   blob1.hash
		fsid:   [test_fs.id]
		blobid: blob1_id
	)!
	membership1 = fs_factory.fs_blob_membership.set(membership1)!
	membership1_hash := membership1.hash

	mut membership2 := fs_factory.fs_blob_membership.new(
		hash:   blob2.hash
		fsid:   [test_fs.id]
		blobid: blob2_id
	)!
	membership2 = fs_factory.fs_blob_membership.set(membership2)!
	membership2_hash := membership2.hash

	mut membership3 := fs_factory.fs_blob_membership.new(
		hash:   blob3.hash
		fsid:   [test_fs.id]
		blobid: blob3_id
	)!
	membership3 = fs_factory.fs_blob_membership.set(membership3)!
	membership3_hash := membership3.hash

	println('Created test memberships:')
	println('- Membership 1 hash: ${membership1_hash}')
	println('- Membership 2 hash: ${membership2_hash}')
	println('- Membership 3 hash: ${membership3_hash}')

	// Test listing by hash prefix
	// Use first 16 characters of the first hash as prefix
	prefix := membership1_hash[..16]
	mut memberships := fs_factory.fs_blob_membership.list_prefix(prefix)!

	// Should find at least one membership (membership1)
	assert memberships.len >= 1
	mut found := false
	for membership in memberships {
		if membership.hash == membership1.hash {
			found = true
			break
		}
	}
	assert found == true
	println('✓ Listed blob memberships by prefix: ${prefix}')

	// Test with non-existent prefix
	non_existent_prefix := '0000000000000000'
	mut empty_memberships := fs_factory.fs_blob_membership.list_prefix(non_existent_prefix)!
	assert empty_memberships.len == 0
	println('✓ List with non-existent prefix returns empty array')

	println('FsBlobMembership list by prefix test completed successfully!')
}
