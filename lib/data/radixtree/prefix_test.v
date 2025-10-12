module radixtree

import incubaid.herolib.ui.console

fn test_list() ! {
	// console.print_debug('Starting test_list')
	mut rt := new(path: '/tmp/radixtree_prefix_test', reset: true)!

	// Insert keys with various prefixes
	test_data := {
		'apple':       'fruit1'
		'application': 'software1'
		'apply':       'verb1'
		'banana':      'fruit2'
		'ball':        'toy1'
		'cat':         'animal1'
		'car':         'vehicle1'
		'cargo':       'shipping1'
	}

	// Set all test data
	for key, value in test_data {
		rt.set(key, value.bytes())!
	}

	// Test prefix 'app' - should return apple, application, apply
	// console.print_debug('Testing prefix "app"')
	app_keys := rt.list('app')!
	// console.print_debug('app_keys: ${app_keys}')
	assert app_keys.len == 3
	assert 'apple' in app_keys
	assert 'application' in app_keys
	assert 'apply' in app_keys

	// Test prefix 'ba' - should return banana, ball
	// console.print_debug('Testing prefix "ba"')
	ba_keys := rt.list('ba')!
	// console.print_debug('ba_keys: ${ba_keys}')
	assert ba_keys.len == 2
	assert 'banana' in ba_keys
	assert 'ball' in ba_keys

	// Test prefix 'car' - should return car, cargo
	// console.print_debug('Testing prefix "car"')
	car_keys := rt.list('car')!
	// console.print_debug('car_keys: ${car_keys}')
	assert car_keys.len == 2
	assert 'car' in car_keys
	assert 'cargo' in car_keys

	// Test prefix 'z' - should return empty list
	// console.print_debug('Testing prefix "z"')
	z_keys := rt.list('z')!
	// console.print_debug('z_keys: ${z_keys}')
	assert z_keys.len == 0

	// Test empty prefix - should return all keys
	// console.print_debug('Testing empty prefix')
	all_keys := rt.list('')!
	// console.print_debug('all_keys: ${all_keys}')
	assert all_keys.len == test_data.len
	for key in test_data.keys() {
		assert key in all_keys
	}

	// Test exact key as prefix - should return just that key
	// console.print_debug('Testing exact key as prefix "apple"')
	exact_key := rt.list('apple')!
	// console.print_debug('exact_key: ${exact_key}')
	assert exact_key.len == 1
	assert exact_key[0] == 'apple'
	// console.print_debug('test_list completed successfully')
}

fn test_list_with_deletion() ! {
	// console.print_debug('Starting test_list_with_deletion')
	mut rt := new(path: '/tmp/radixtree_prefix_deletion_test', reset: true)!

	// Set keys with common prefixes
	rt.set('test1', 'value1'.bytes())!
	rt.set('test2', 'value2'.bytes())!
	rt.set('test3', 'value3'.bytes())!
	rt.set('other', 'value4'.bytes())!

	// Initial check
	// console.print_debug('Testing initial prefix "test"')
	test_keys := rt.list('test')!
	// console.print_debug('test_keys: ${test_keys}')
	assert test_keys.len == 3
	assert 'test1' in test_keys
	assert 'test2' in test_keys
	assert 'test3' in test_keys

	// Delete one key
	// console.print_debug('Deleting key "test2"')
	rt.delete('test2')!

	// Check after deletion
	// console.print_debug('Testing prefix "test" after deletion')
	test_keys_after := rt.list('test')!
	// console.print_debug('test_keys_after: ${test_keys_after}')
	assert test_keys_after.len == 2
	assert 'test1' in test_keys_after
	assert 'test2' !in test_keys_after
	assert 'test3' in test_keys_after

	// Check all keys
	// console.print_debug('Testing empty prefix')
	all_keys := rt.list('')!
	// console.print_debug('all_keys: ${all_keys}')
	assert all_keys.len == 3
	assert 'other' in all_keys
	// console.print_debug('test_list_with_deletion completed successfully')
}

fn test_list_edge_cases() ! {
	// console.print_debug('Starting test_list_edge_cases')
	mut rt := new(path: '/tmp/radixtree_prefix_edge_test', reset: true)!

	// Test with empty tree
	// console.print_debug('Testing empty tree with prefix "any"')
	empty_result := rt.list('any')!
	// console.print_debug('empty_result: ${empty_result}')
	assert empty_result.len == 0

	// Set a single key
	// console.print_debug('Setting single key "single"')
	rt.set('single', 'value'.bytes())!

	// Test with prefix that's longer than any key
	// console.print_debug('Testing prefix longer than any key "singlelonger"')
	long_prefix := rt.list('singlelonger')!
	// console.print_debug('long_prefix: ${long_prefix}')
	assert long_prefix.len == 0

	// Test with partial prefix match
	// console.print_debug('Testing partial prefix match "sing"')
	partial := rt.list('sing')!
	// console.print_debug('partial: ${partial}')
	assert partial.len == 1
	assert partial[0] == 'single'

	// Test with very long keys
	// console.print_debug('Testing with very long keys')
	long_key1 := 'a'.repeat(100) + 'key1'
	long_key2 := 'a'.repeat(100) + 'key2'

	rt.set(long_key1, 'value1'.bytes())!
	rt.set(long_key2, 'value2'.bytes())!

	// console.print_debug('Testing long prefix')
	long_prefix_result := rt.list('a'.repeat(100))!
	// console.print_debug('long_prefix_result: ${long_prefix_result}')
	assert long_prefix_result.len == 2
	assert long_key1 in long_prefix_result
	assert long_key2 in long_prefix_result
	// console.print_debug('test_list_edge_cases completed successfully')
}

fn test_list_performance() ! {
	// console.print_debug('Starting test_list_performance')
	mut rt := new(path: '/tmp/radixtree_prefix_perf_test', reset: true)!

	// Insert a large number of keys with different prefixes
	// console.print_debug('Setting up prefixes')
	prefixes := ['user', 'post', 'comment', 'like', 'share']

	// Set 100 keys for each prefix (500 total)
	// console.print_debug('Setting 500 keys (100 for each prefix)')
	for prefix in prefixes {
		for i in 0 .. 100 {
			key := '${prefix}_${i}'
			rt.set(key, 'value_${key}'.bytes())!
		}
	}

	// Test retrieving by each prefix
	// console.print_debug('Testing retrieval by each prefix')
	for prefix in prefixes {
		// console.print_debug('Testing prefix "${prefix}"')
		keys := rt.list(prefix)!
		// console.print_debug('Found ${keys.len} keys for prefix "${prefix}"')
		assert keys.len == 100

		// Verify all keys have the correct prefix
		for key in keys {
			assert key.starts_with(prefix)
		}
	}

	// Test retrieving all keys
	// console.print_debug('Testing retrieval of all keys')
	all_keys := rt.list('')!
	// console.print_debug('Found ${all_keys.len} total keys')
	assert all_keys.len == 500
	// console.print_debug('test_list_performance completed successfully')
}
