module radixtree

import incubaid.herolib.ui.console

fn test_basic_operations() ! {
	mut rt := new(path: '/tmp/radixtree_test', reset: true)!

	// Test set and get
	rt.set('test', 'value1'.bytes())!
	value1 := rt.get('test')!
	assert value1.bytestr() == 'value1'

	// Test updating existing key
	rt.set('test', 'value2'.bytes())!
	value2 := rt.get('test')!
	assert value2.bytestr() == 'value2'

	// Test non-existent key
	if _ := rt.get('nonexistent') {
		assert false, 'Expected error for non-existent key'
	}

	// Test delete
	rt.delete('test')!
	mut ok := false
	if _ := rt.get('test') {
		ok = true
	} else {
		ok = false
	}
	assert !ok, 'Expected error for deleted key'
}

fn test_prefix_matching() ! {
	mut rt := new(path: '/tmp/radixtree_test_prefix')!

	// Set keys with common prefixes
	rt.set('team', 'value1'.bytes())!
	rt.set('test', 'value2'.bytes())!
	rt.set('testing', 'value3'.bytes())!

	// Verify each key has correct value
	value1 := rt.get('team')!
	assert value1.bytestr() == 'value1'

	value2 := rt.get('test')!
	assert value2.bytestr() == 'value2'

	value3 := rt.get('testing')!
	assert value3.bytestr() == 'value3'

	// Delete middle key and verify others still work
	rt.delete('test')!

	if _ := rt.get('test') {
		assert false, 'Expected error after deletion'
	}

	value1_after := rt.get('team')!
	assert value1_after.bytestr() == 'value1'

	value3_after := rt.get('testing')!
	assert value3_after.bytestr() == 'value3'
}

fn test_edge_cases() ! {
	mut rt := new(path: '/tmp/radixtree_test_edge')!

	// Test empty key
	rt.set('', 'empty'.bytes())!
	empty_value := rt.get('')!
	assert empty_value.bytestr() == 'empty'

	// Test very long key
	long_key := 'a'.repeat(1000)
	rt.set(long_key, 'long'.bytes())!
	long_value := rt.get(long_key)!
	assert long_value.bytestr() == 'long'

	// Test keys that require node splitting
	rt.set('test', 'value1'.bytes())!
	rt.set('testing', 'value2'.bytes())!
	rt.set('te', 'value3'.bytes())!

	value1 := rt.get('test')!
	assert value1.bytestr() == 'value1'

	value2 := rt.get('testing')!
	assert value2.bytestr() == 'value2'

	value3 := rt.get('te')!
	assert value3.bytestr() == 'value3'
}

fn test_update_metadata() ! {
	mut rt := new(path: '/tmp/radixtree_test_update')!

	// Simulate hash.bytes + id_bytes + metadata_bytes
	prefix := 'hashbytes123id456'
	initial_metadata := 'metadata_initial'.bytes()
	new_metadata := 'metadata_updated'.bytes()

	// Set initial entry
	rt.set(prefix, initial_metadata)!

	// Verify initial value
	value := rt.get(prefix)!
	assert value.bytestr() == 'metadata_initial'

	// Update metadata while keeping the same prefix
	rt.update(prefix, new_metadata)!

	// Verify updated value
	updated_value := rt.get(prefix)!
	assert updated_value.bytestr() == 'metadata_updated'

	// Test updating non-existent prefix
	if _ := rt.update('nonexistent', 'test'.bytes()) {
		assert false, 'Expected error for non-existent prefix'
	}
}

fn test_multiple_operations() ! {
	mut rt := new(path: '/tmp/radixtree_test_multiple')!

	// Set multiple keys
	keys := ['abc', 'abcd', 'abcde', 'bcd', 'bcde']
	for i, key in keys {
		rt.set(key, 'value${i + 1}'.bytes())!
	}

	// Verify all keys
	for i, key in keys {
		value := rt.get(key)!
		assert value.bytestr() == 'value${i + 1}'
	}

	// Delete some keys
	rt.delete('abcd')!
	rt.delete('bcde')!

	// Verify remaining keys
	remaining := ['abc', 'abcde', 'bcd']
	expected := ['value1', 'value3', 'value4']

	for i, key in remaining {
		value := rt.get(key)!
		assert value.bytestr() == expected[i]
	}

	// Verify deleted keys return error
	deleted := ['abcd', 'bcde']
	for key in deleted {
		if _ := rt.get(key) {
			assert false, 'Expected error for deleted key: ${key}'
		}
	}
}
