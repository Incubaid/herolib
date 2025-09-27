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

	// Create a new filesystem
	mut test_fs := fs_factory.fs.new_get_set(
		name:        'test_filesystem'
		description: 'Filesystem for testing FsBlobMembership functionality'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!
	
	assert test_fs.id > 0
	assert test_fs.root_dir_id > 0

	// Create test blob
	test_data := 'This is test content for blob membership'.bytes()
	mut test_blob := fs_factory.fs_blob.new(data: test_data)!
	test_blob = fs_factory.fs_blob.set(test_blob)!

	// Create blob membership
	mut test_membership := fs_factory.fs_blob_membership.new(
		hash:   test_blob.hash
		fsid:   [test_fs.id]
		blobid: test_blob.id
	)!
	test_membership = fs_factory.fs_blob_membership.set(test_membership)!

	// Test retrieval
	loaded_membership := fs_factory.fs_blob_membership.get(test_membership.hash)!
	assert loaded_membership.hash == test_membership.hash
	assert loaded_membership.fsid == test_membership.fsid
	assert loaded_membership.blobid == test_membership.blobid

	println('✓ FsBlobMembership basic test passed!')
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
	fs2_id := fs2.id

	// Create test blob
	test_data := 'This is test content for filesystem operations'.bytes()
	mut test_blob := fs_factory.fs_blob.new(data: test_data)!
	test_blob = fs_factory.fs_blob.set(test_blob)!
	blob_id := test_blob.id

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
	fs_factory.fs_blob_membership.add_filesystem(membership_hash, fs2_id)!
	mut updated_membership := fs_factory.fs_blob_membership.get(membership_hash)!

	// Verify both filesystems are in the list
	assert updated_membership.fsid.len == 2
	assert fs1_id in updated_membership.fsid
	assert fs2_id in updated_membership.fsid
	println('✓ Added filesystem 2 to blob membership')

	// Test removing a filesystem from membership
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

	// Test setting membership with non-existent blob (should fail)
	// Create a membership with a non-existent blob ID
	mut test_membership := fs_factory.fs_blob_membership.new(
		hash:   '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
		fsid:   [test_fs.id]
		blobid: 999999 // Non-existent blob ID
	)!

	// Try to save it, which should fail
	fs_factory.fs_blob_membership.set(test_membership) or {
		println('✓ Membership set correctly failed with non-existent blob')
		return
	}
	panic('Validation should have failed for non-existent blob')
}