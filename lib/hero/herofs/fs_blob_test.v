module herofs

import freeflowuniverse.herolib.hero.db
import crypto.blake3

fn test_basic() {
	println('Testing FsBlob functionality...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!
	println('HeroFS factory initialized')

	// Create test data
	test_data1 := 'This is test content for blob 1'.bytes()
	test_data2 := 'This is test content for blob 2'.bytes()
	test_data3 := 'Another test content'.bytes()

	// Test creating new blobs with various data
	mut test_blob1 := fs_factory.fs_blob.new(
		data: test_data1
	)!

	mut test_blob2 := fs_factory.fs_blob.new(
		data: test_data2
	)!

	mut test_blob3 := fs_factory.fs_blob.new(
		data: test_data3
	)!

	// Verify blob properties
	assert test_blob1.data == test_data1
	assert test_blob1.size_bytes == test_data1.len
	assert test_blob1.hash != ''
	println('✓ Created test blobs with correct properties')

	// Test saving blobs
	fs_factory.fs_blob.set(mut test_blob1)!
	blob1_id := test_blob1.id
	fs_factory.fs_blob.set(mut test_blob2)!
	blob2_id := test_blob2.id
	fs_factory.fs_blob.set(mut test_blob3)!
	blob3_id := test_blob3.id

	println('Created test blobs with IDs:')
	println('- Blob 1 ID: ${blob1_id}')
	println('- Blob 2 ID: ${blob2_id}')
	println('- Blob 3 ID: ${blob3_id}')

	// Test loading blobs by ID
	println('\nTesting blob loading...')

	loaded_blob1 := fs_factory.fs_blob.get(blob1_id)!
	assert loaded_blob1.data == test_data1
	assert loaded_blob1.size_bytes == test_data1.len
	assert loaded_blob1.hash == test_blob1.hash
	println('✓ Loaded blob 1: ${loaded_blob1.hash} (ID: ${loaded_blob1.id})')

	loaded_blob2 := fs_factory.fs_blob.get(blob2_id)!
	assert loaded_blob2.data == test_data2
	assert loaded_blob2.size_bytes == test_data2.len
	assert loaded_blob2.hash == test_blob2.hash
	println('✓ Loaded blob 2: ${loaded_blob2.hash} (ID: ${loaded_blob2.id})')

	loaded_blob3 := fs_factory.fs_blob.get(blob3_id)!
	assert loaded_blob3.data == test_data3
	assert loaded_blob3.size_bytes == test_data3.len
	assert loaded_blob3.hash == test_blob3.hash
	println('✓ Loaded blob 3: ${loaded_blob3.hash} (ID: ${loaded_blob3.id})')

	// Verify that loaded blobs match the original ones
	println('\nVerifying data integrity...')
	assert loaded_blob1.verify_integrity() == true
	assert loaded_blob2.verify_integrity() == true
	assert loaded_blob3.verify_integrity() == true
	println('✓ All blob data integrity checks passed')

	// Test exist method
	println('\nTesting blob existence checks...')

	mut exists := fs_factory.fs_blob.exist(blob1_id)!
	assert exists == true
	println('✓ Blob 1 exists: ${exists}')

	exists = fs_factory.fs_blob.exist(blob2_id)!
	assert exists == true
	println('✓ Blob 2 exists: ${exists}')

	exists = fs_factory.fs_blob.exist(blob3_id)!
	assert exists == true
	println('✓ Blob 3 exists: ${exists}')

	// Test with non-existent ID
	exists = fs_factory.fs_blob.exist(999999)!
	assert exists == false
	println('✓ Non-existent blob exists: ${exists}')

	println('\nFsBlob basic test completed successfully!')
}

fn test_blob_deduplication() {
	println('\nTesting FsBlob deduplication...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!

	// Create identical test data
	identical_data := 'This is identical content'.bytes()

	// Create first blob
	mut blob1 := fs_factory.fs_blob.new(
		data: identical_data
	)!
	fs_factory.fs_blob.set(mut blob1)!
	println('Created first blob with ID: ${blob1.id}')

	// Create second blob with identical data
	mut blob2 := fs_factory.fs_blob.new(
		data: identical_data
	)!
	fs_factory.fs_blob.set(mut blob2)!
	println('Created second blob with ID: ${blob2.id}')

	// Verify that both blobs have the same ID (deduplication)
	assert blob1.id == blob2.id
	println('✓ Deduplication works correctly - identical content gets same ID')

	// Verify that the blob can be retrieved by the ID
	loaded_blob := fs_factory.fs_blob.get(blob1.id)!
	assert loaded_blob.data == identical_data
	assert loaded_blob.hash == blob1.hash
	println('✓ Retrieved deduplicated blob correctly')

	println('FsBlob deduplication test completed successfully!')
}

fn test_blob_operations() {
	println('\nTesting FsBlob operations...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!

	// Create test data
	test_data1 := 'Operation test content 1'.bytes()
	test_data2 := 'Operation test content 2'.bytes()
	test_data3 := 'Operation test content 3'.bytes()

	// Create and save test blobs
	mut blob1 := fs_factory.fs_blob.new(data: test_data1)!
	mut blob2 := fs_factory.fs_blob.new(data: test_data2)!
	mut blob3 := fs_factory.fs_blob.new(data: test_data3)!

	fs_factory.fs_blob.set(mut blob1)!
	fs_factory.fs_blob.set(mut blob2)!
	fs_factory.fs_blob.set(mut blob3)!

	println('Created test blobs:')
	println('- Blob 1 ID: ${blob1.id}')
	println('- Blob 2 ID: ${blob2.id}')
	println('- Blob 3 ID: ${blob3.id}')

	// Test get_multi method
	mut ids := []u32{len: 3}
	ids[0] = blob1_id
	ids[1] = blob2_id
	ids[2] = blob3_id
	mut blobs := fs_factory.fs_blob.get_multi(ids)!

	assert blobs.len == 3
	assert blobs[0].id == blob1_id
	assert blobs[1].id == blob2_id
	assert blobs[2].id == blob3_id
	println('✓ Retrieved multiple blobs correctly')

	// Test exist_multi method
	mut exists := fs_factory.fs_blob.exist_multi(ids)!
	assert exists == true
	println('✓ Multiple blob existence check passed')

	// Test with non-existent ID in exist_multi
	mut ids_with_nonexistent := []u32{len: 3}
	ids_with_nonexistent[0] = blob1_id
	ids_with_nonexistent[1] = 999999
	ids_with_nonexistent[2] = blob3_id
	exists = fs_factory.fs_blob.exist_multi(ids_with_nonexistent)!
	assert exists == false
	println('✓ Multiple blob existence check correctly failed with non-existent ID')

	println('FsBlob operations test completed successfully!')
}

fn test_blob_deletion() {
	println('\nTesting FsBlob deletion...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!

	// Create test data
	test_data := 'Deletion test content'.bytes()

	// Create and save test blob
	mut blob := fs_factory.fs_blob.new(data: test_data)!
	blob_id := fs_factory.fs_blob.set(blob)!
	println('Created test blob with ID: ${blob_id}')

	// Verify blob exists
	mut exists := fs_factory.fs_blob.exist(blob_id)!
	assert exists == true
	println('✓ Blob exists before deletion')

	// Delete the blob
	fs_factory.fs_blob.delete(blob_id)!

	// Verify blob no longer exists by ID
	exists = fs_factory.fs_blob.exist(blob_id)!
	assert exists == false
	println('✓ Blob no longer exists by ID after deletion')

	// Test delete_multi with multiple blobs
	test_data1 := 'Multi deletion test 1'.bytes()
	test_data2 := 'Multi deletion test 2'.bytes()
	test_data3 := 'Multi deletion test 3'.bytes()

	mut blob1 := fs_factory.fs_blob.new(data: test_data1)!
	mut blob2 := fs_factory.fs_blob.new(data: test_data2)!
	mut blob3 := fs_factory.fs_blob.new(data: test_data3)!

	blob1_id := fs_factory.fs_blob.set(blob1)!
	blob2_id := fs_factory.fs_blob.set(blob2)!
	blob3_id := fs_factory.fs_blob.set(blob3)!

	println('Created multiple blobs for deletion test:')
	println('- Blob 1 ID: ${blob1_id}')
	println('- Blob 2 ID: ${blob2_id}')
	println('- Blob 3 ID: ${blob3_id}')

	// Delete multiple blobs
	mut ids := []u32{len: 3}
	ids[0] = blob1_id
	ids[1] = blob2_id
	ids[2] = blob3_id
	fs_factory.fs_blob.delete_multi(ids)!

	// Verify all blobs are deleted
	exists = fs_factory.fs_blob.exist_multi(ids)!
	assert exists == false
	println('✓ Multiple blobs deleted successfully')

	println('FsBlob deletion test completed successfully!')
}

fn test_blob_size_limit() {
	println('\nTesting FsBlob size limit...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!

	// Create data that exceeds 1MB limit
	mut large_data := []u8{len: 1024 * 1024 + 1} // 1MB + 1 byte
	for i := 0; i < large_data.len; i++ {
		large_data[i] = u8(i % 256)
	}

	// Try to create a blob with data exceeding the limit
	mut result := fs_factory.fs_blob.new(data: large_data) or {
		println('✓ Blob creation correctly failed with data exceeding 1MB limit')
		return
	}

	// If we get here, the validation didn't work as expected
	// Try to save it, which should fail
	result_id := fs_factory.fs_blob.set(result) or {
		println('✓ Blob set correctly failed with data exceeding 1MB limit')
		return
	}

	panic('Validation should have failed for data exceeding 1MB limit')

	println('FsBlob size limit test completed successfully!')
}

fn test_blob_hash_functionality() {
	println('\nTesting FsBlob hash functionality...')

	// Initialize the HeroFS factory
	mut fs_factory := new()!

	// Create test data
	test_data := 'Hash test content'.bytes()

	// Create blob
	mut blob := fs_factory.fs_blob.new(data: test_data)!

	// Verify hash is calculated correctly
	expected_hash := blake3.sum256(test_data).hex()[..48]
	assert blob.hash == expected_hash
	println('✓ Blob hash calculated correctly')

	// Save blob
	blob_id := fs_factory.fs_blob.set(blob)!

	// Retrieve by hash
	loaded_blob := fs_factory.fs_blob.get_by_hash(blob.hash)!
	assert loaded_blob.id == blob_id
	assert loaded_blob.data == test_data
	println('✓ Blob retrieved by hash correctly')

	// Test with non-existent hash
	non_existent_hash := '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
	non_existent_blob := fs_factory.fs_blob.get_by_hash(non_existent_hash) or {
		println('✓ Retrieval correctly failed with non-existent hash')
		return
	}

	panic('Retrieval should have failed for non-existent hash')

	println('FsBlob hash functionality test completed successfully!')
}
