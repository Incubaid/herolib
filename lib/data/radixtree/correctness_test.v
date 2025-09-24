module radixtree

import freeflowuniverse.herolib.ui.console

// Test for the critical bug: prefix-of-existing edge inserted after the longer key
fn test_prefix_overlap_bug() ! {
	console.print_debug('Testing prefix overlap bug fix')
	mut rt := new(path: '/tmp/radixtree_prefix_overlap_test', reset: true)!

	// Insert longer key first
	rt.set('test', 'value1'.bytes())!
	rt.set('testing', 'value2'.bytes())!

	// Now insert shorter key that is a prefix - this was the bug
	rt.set('te', 'value3'.bytes())!

	// Verify all keys work regardless of child iteration order
	value1 := rt.get('test')!
	assert value1.bytestr() == 'value1', 'Failed to get "test"'

	value2 := rt.get('testing')!
	assert value2.bytestr() == 'value2', 'Failed to get "testing"'

	value3 := rt.get('te')!
	assert value3.bytestr() == 'value3', 'Failed to get "te"'

	// Test that all keys are found in list
	all_keys := rt.list('')!
	assert 'test' in all_keys, '"test" not found in list'
	assert 'testing' in all_keys, '"testing" not found in list'
	assert 'te' in all_keys, '"te" not found in list'

	console.print_debug('Prefix overlap bug test passed')
}

// Test partial overlap where neither key is a prefix of the other
fn test_partial_overlap_split() ! {
	console.print_debug('Testing partial overlap split')
	mut rt := new(path: '/tmp/radixtree_partial_overlap_test', reset: true)!

	// Insert keys that share a common prefix but neither is a prefix of the other
	rt.set('foobar', 'value1'.bytes())!
	console.print_debug('After inserting foobar')
	rt.print_tree()!

	rt.set('foobaz', 'value2'.bytes())!
	console.print_debug('After inserting foobaz')
	rt.print_tree()!

	// Verify both keys work
	value1 := rt.get('foobar')!
	assert value1.bytestr() == 'value1', 'Failed to get "foobar"'

	value2 := rt.get('foobaz')!
	assert value2.bytestr() == 'value2', 'Failed to get "foobaz"'

	// Test prefix search
	foo_keys := rt.list('foo')!
	console.print_debug('foo_keys: ${foo_keys}')
	assert foo_keys.len == 2, 'Expected 2 keys with prefix "foo"'
	assert 'foobar' in foo_keys, '"foobar" not found with prefix "foo"'
	assert 'foobaz' in foo_keys, '"foobaz" not found with prefix "foo"'

	fooba_keys := rt.list('fooba')!
	assert fooba_keys.len == 2, 'Expected 2 keys with prefix "fooba"'

	console.print_debug('Partial overlap split test passed')
}

// Test deletion with path compression
fn test_deletion_compression() ! {
	console.print_debug('Testing deletion with path compression')
	mut rt := new(path: '/tmp/radixtree_deletion_compression_test', reset: true)!

	// Insert keys that will create intermediate nodes
	rt.set('car', 'value1'.bytes())!
	rt.set('cargo', 'value2'.bytes())!

	// Verify both keys exist
	value1 := rt.get('car')!
	assert value1.bytestr() == 'value1', 'Failed to get "car"'

	value2 := rt.get('cargo')!
	assert value2.bytestr() == 'value2', 'Failed to get "cargo"'

	// Delete the shorter key
	rt.delete('car')!

	// Verify the longer key still works (tests compression)
	value2_after := rt.get('cargo')!
	assert value2_after.bytestr() == 'value2', 'Failed to get "cargo" after deletion'

	// Verify the deleted key is gone
	if _ := rt.get('car') {
		assert false, 'Expected "car" to be deleted'
	}

	console.print_debug('Deletion compression test passed')
}

// Test large fan-out to stress the system
fn test_large_fanout() ! {
	console.print_debug('Testing large fan-out')
	mut rt := new(path: '/tmp/radixtree_large_fanout_test', reset: true)!

	// Insert keys with single character differences to create large fan-out
	for i in 0 .. 100 {
		key := 'prefix${i:03d}'
		rt.set(key, 'value${i}'.bytes())!
	}

	// Verify all keys can be retrieved
	for i in 0 .. 100 {
		key := 'prefix${i:03d}'
		value := rt.get(key)!
		expected := 'value${i}'
		assert value.bytestr() == expected, 'Failed to get key "${key}"'
	}

	// Test prefix search
	prefix_keys := rt.list('prefix')!
	assert prefix_keys.len == 100, 'Expected 100 keys with prefix "prefix"'

	console.print_debug('Large fan-out test passed')
}

// Test sorted output
fn test_sorted_output() ! {
	console.print_debug('Testing sorted output')
	mut rt := new(path: '/tmp/radixtree_sorted_test', reset: true)!

	// Insert keys in random order
	keys := ['zebra', 'apple', 'banana', 'cherry', 'date']
	for key in keys {
		rt.set(key, '${key}_value'.bytes())!
	}

	// Get all keys and verify they are sorted
	all_keys := rt.list('')!
	assert all_keys.len == keys.len, 'Expected ${keys.len} keys'

	// Check if sorted (should be: apple, banana, cherry, date, zebra)
	expected_order := ['apple', 'banana', 'cherry', 'date', 'zebra']
	for i, expected_key in expected_order {
		assert all_keys[i] == expected_key, 'Expected key at position ${i} to be "${expected_key}", got "${all_keys[i]}"'
	}

	console.print_debug('Sorted output test passed')
}

// Test edge case: empty key
fn test_empty_key() ! {
	console.print_debug('Testing empty key')
	mut rt := new(path: '/tmp/radixtree_empty_key_test', reset: true)!

	// Set empty key
	rt.set('', 'empty_value'.bytes())!

	// Set regular key
	rt.set('regular', 'regular_value'.bytes())!

	// Verify both work
	empty_value := rt.get('')!
	assert empty_value.bytestr() == 'empty_value', 'Failed to get empty key'

	regular_value := rt.get('regular')!
	assert regular_value.bytestr() == 'regular_value', 'Failed to get "regular"'

	// Test list with empty prefix
	all_keys := rt.list('')!
	assert all_keys.len == 2, 'Expected 2 keys total'
	assert '' in all_keys, 'Empty key not found in list'
	assert 'regular' in all_keys, '"regular" not found in list'

	console.print_debug('Empty key test passed')
}

// Test very long keys
fn test_long_keys() ! {
	console.print_debug('Testing very long keys')
	mut rt := new(path: '/tmp/radixtree_long_keys_test', reset: true)!

	// Create very long keys
	long_key1 := 'a'.repeat(1000) + 'key1'
	long_key2 := 'a'.repeat(1000) + 'key2'
	long_key3 := 'b'.repeat(500) + 'different'

	rt.set(long_key1, 'value1'.bytes())!
	rt.set(long_key2, 'value2'.bytes())!
	rt.set(long_key3, 'value3'.bytes())!

	// Verify retrieval
	value1 := rt.get(long_key1)!
	assert value1.bytestr() == 'value1', 'Failed to get long_key1'

	value2 := rt.get(long_key2)!
	assert value2.bytestr() == 'value2', 'Failed to get long_key2'

	value3 := rt.get(long_key3)!
	assert value3.bytestr() == 'value3', 'Failed to get long_key3'

	// Test prefix search with long prefix
	long_prefix_keys := rt.list('a'.repeat(1000))!
	assert long_prefix_keys.len == 2, 'Expected 2 keys with long prefix'

	console.print_debug('Long keys test passed')
}

// Test complex overlapping scenarios
fn test_complex_overlaps() ! {
	console.print_debug('Testing complex overlapping scenarios')
	mut rt := new(path: '/tmp/radixtree_complex_overlaps_test', reset: true)!

	// Create a complex set of overlapping keys
	keys := [
		'a',
		'ab',
		'abc',
		'abcd',
		'abcde',
		'abcdef',
		'abd',
		'ac',
		'b',
		'ba',
		'bb',
	]

	// Insert in random order to test robustness
	for i, key in keys {
		rt.set(key, 'value${i}'.bytes())!
	}

	// Verify all keys can be retrieved
	for i, key in keys {
		value := rt.get(key)!
		expected := 'value${i}'
		assert value.bytestr() == expected, 'Failed to get key "${key}"'
	}

	// Test various prefix searches
	a_keys := rt.list('a')!
	assert a_keys.len == 8, 'Expected 8 keys with prefix "a"'

	ab_keys := rt.list('ab')!
	assert ab_keys.len == 6, 'Expected 6 keys with prefix "ab"'

	abc_keys := rt.list('abc')!
	assert abc_keys.len == 4, 'Expected 4 keys with prefix "abc"'

	b_keys := rt.list('b')!
	assert b_keys.len == 3, 'Expected 3 keys with prefix "b"'

	console.print_debug('Complex overlaps test passed')
}

// Run all correctness tests
fn test_all_correctness() ! {
	console.print_debug('Running all correctness tests...')

	test_prefix_overlap_bug()!
	test_partial_overlap_split()!
	test_deletion_compression()!
	test_large_fanout()!
	test_sorted_output()!
	test_empty_key()!
	test_long_keys()!
	test_complex_overlaps()!

	console.print_debug('All correctness tests passed!')
}
