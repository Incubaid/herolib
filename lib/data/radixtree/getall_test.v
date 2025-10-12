module radixtree

import incubaid.herolib.ui.console

fn test_getall() ! {
	// console.print_debug('Starting test_getall')
	mut rt := new(path: '/tmp/radixtree_getall_test', reset: true)!

	// Set up test data with common prefixes
	test_data := {
		'user_1':  'data1'
		'user_2':  'data2'
		'user_3':  'data3'
		'admin_1': 'admin_data1'
		'admin_2': 'admin_data2'
		'guest':   'guest_data'
	}

	// Set all test data
	for key, value in test_data {
		rt.set(key, value.bytes())!
	}

	// Test getall with 'user_' prefix
	// console.print_debug('Testing getall with prefix "user_"')
	user_values := rt.getall('user_')!
	// console.print_debug('user_values count: ${user_values.len}')

	// Should return 3 values
	assert user_values.len == 3

	// Convert byte arrays to strings for easier comparison
	mut user_value_strings := []string{}
	for value in user_values {
		user_value_strings << value.bytestr()
	}

	// Check all expected values are present
	assert 'data1' in user_value_strings
	assert 'data2' in user_value_strings
	assert 'data3' in user_value_strings

	// Test getall with 'admin_' prefix
	// console.print_debug('Testing getall with prefix "admin_"')
	admin_values := rt.getall('admin_')!
	// console.print_debug('admin_values count: ${admin_values.len}')

	// Should return 2 values
	assert admin_values.len == 2

	// Convert byte arrays to strings for easier comparison
	mut admin_value_strings := []string{}
	for value in admin_values {
		admin_value_strings << value.bytestr()
	}

	// Check all expected values are present
	assert 'admin_data1' in admin_value_strings
	assert 'admin_data2' in admin_value_strings

	// Test getall with empty prefix (should return all values)
	// console.print_debug('Testing getall with empty prefix')
	all_values := rt.getall('')!
	// console.print_debug('all_values count: ${all_values.len}')

	// Should return all 6 values
	assert all_values.len == test_data.len

	// Test getall with non-existent prefix
	// console.print_debug('Testing getall with non-existent prefix "xyz"')
	non_existent_values := rt.getall('xyz')!
	// console.print_debug('non_existent_values count: ${non_existent_values.len}')

	// Should return empty array
	assert non_existent_values.len == 0

	// console.print_debug('test_getall completed successfully')
}
