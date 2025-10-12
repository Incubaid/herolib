module dedupe_ourdb

import os
import incubaid.herolib.data.dedupestor

fn testsuite_begin() ! {
	// Ensure test directories exist and are clean
	test_dirs := [
		'/tmp/dedupestor_test',
		'/tmp/dedupestor_test_size',
		'/tmp/dedupestor_test_exists',
		'/tmp/dedupestor_test_multiple',
		'/tmp/dedupestor_test_refs',
	]

	for dir in test_dirs {
		if os.exists(dir) {
			os.rmdir_all(dir) or {}
		}
		os.mkdir_all(dir) or {}
	}
}

fn test_basic_operations() ! {
	mut ds := new(
		path:  '/tmp/dedupestor_test'
		reset: true
	)!

	// Test storing and retrieving data
	value1 := 'test data 1'.bytes()
	ref1 := dedupestor.Reference{
		owner: 1
		id:    1
	}
	id1 := ds.store(value1, ref1)!

	retrieved1 := ds.get(id1)!
	assert retrieved1 == value1

	// Test deduplication with different reference
	ref2 := dedupestor.Reference{
		owner: 1
		id:    2
	}
	id2 := ds.store(value1, ref2)!
	assert id1 == id2 // Should return same id for same data

	// Test different data gets different id
	value2 := 'test data 2'.bytes()
	ref3 := dedupestor.Reference{
		owner: 1
		id:    3
	}
	id3 := ds.store(value2, ref3)!
	assert id1 != id3 // Should be different id for different data

	retrieved2 := ds.get(id3)!
	assert retrieved2 == value2
}

fn test_size_limit() ! {
	mut ds := new(
		path:  '/tmp/dedupestor_test_size'
		reset: true
	)!

	// Test data under size limit (1KB)
	small_data := []u8{len: 1024, init: u8(index)}
	ref := dedupestor.Reference{
		owner: 1
		id:    1
	}
	small_id := ds.store(small_data, ref)!
	retrieved := ds.get(small_id)!
	assert retrieved == small_data

	// Test data over size limit (2MB)
	large_data := []u8{len: 2 * 1024 * 1024, init: u8(index)}
	if _ := ds.store(large_data, ref) {
		assert false, 'Expected error for data exceeding size limit'
	}
}

fn test_exists() ! {
	mut ds := new(
		path:  '/tmp/dedupestor_test_exists'
		reset: true
	)!

	value := 'test data'.bytes()
	ref := dedupestor.Reference{
		owner: 1
		id:    1
	}
	id := ds.store(value, ref)!

	assert ds.id_exists(id) == true
	assert ds.id_exists(u32(99)) == false
}

fn test_multiple_operations() ! {
	mut ds := new(
		path:  '/tmp/dedupestor_test_multiple'
		reset: true
	)!

	// Store multiple values
	mut values := [][]u8{}
	mut ids := []u32{}

	for i in 0 .. 5 {
		value := 'test data ${i}'.bytes()
		values << value
		ref := dedupestor.Reference{
			owner: 1
			id:    u32(i)
		}
		id := ds.store(value, ref)!
		ids << id
	}

	// Verify all values can be retrieved
	for i, id in ids {
		retrieved := ds.get(id)!
		assert retrieved == values[i]
	}

	// Test deduplication by storing same values again
	for i, value in values {
		ref := dedupestor.Reference{
			owner: 2
			id:    u32(i)
		}
		id := ds.store(value, ref)!
		assert id == ids[i] // Should get same id for same data
	}
}

fn test_references() ! {
	mut ds := new(
		path:  '/tmp/dedupestor_test_refs'
		reset: true
	)!

	// Store same data with different references
	value := 'test data'.bytes()
	ref1 := dedupestor.Reference{
		owner: 1
		id:    1
	}
	ref2 := dedupestor.Reference{
		owner: 1
		id:    2
	}
	ref3 := dedupestor.Reference{
		owner: 2
		id:    1
	}

	// Store with first reference
	id := ds.store(value, ref1)!

	// Store same data with second reference
	id2 := ds.store(value, ref2)!
	assert id == id2 // Same id for same data

	// Store same data with third reference
	id3 := ds.store(value, ref3)!
	assert id == id3 // Same id for same data

	// Delete first reference - data should still exist
	ds.delete(id, ref1)!
	assert ds.id_exists(id) == true

	// Delete second reference - data should still exist
	ds.delete(id, ref2)!
	assert ds.id_exists(id) == true

	// Delete last reference - data should be gone
	ds.delete(id, ref3)!
	assert ds.id_exists(id) == false

	// Verify data is actually deleted by trying to get it
	if _ := ds.get(id) {
		assert false, 'Expected error getting deleted data'
	}
}
