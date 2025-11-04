module atlas

import incubaid.herolib.core.texttools

// Test that normalize_page_name removes underscores and normalizes consistently
fn test_normalize_page_name() {
	// Test basic normalization
	assert normalize_page_name('token_system') == 'tokensystem'
	assert normalize_page_name('token-system') == 'tokensystem'
	assert normalize_page_name('TokenSystem') == 'tokensystem'
	assert normalize_page_name('Token System') == 'tokensystem'

	// Test with .md extension
	assert normalize_page_name('token_system.md') == 'tokensystem'
	assert normalize_page_name('token-system.md') == 'tokensystem'
	assert normalize_page_name('TokenSystem.md') == 'tokensystem'

	// Test edge cases
	assert normalize_page_name('token__system') == 'tokensystem'
	assert normalize_page_name('token___system') == 'tokensystem'
	assert normalize_page_name('_token_system_') == 'tokensystem'

	// Test special characters
	assert normalize_page_name('token@system') == 'tokensystem'
	assert normalize_page_name('token!system') == 'tokensystem'
	// Note: # is treated specially (truncates at #, like URL anchors)
	assert normalize_page_name('token#system') == 'token'
}

// Test collection name normalization
fn test_collection_name_normalization() {
	// All these should normalize to the same value
	assert texttools.name_fix_no_underscore_no_ext('my_collection') == 'mycollection'
	assert texttools.name_fix_no_underscore_no_ext('my-collection') == 'mycollection'
	assert texttools.name_fix_no_underscore_no_ext('MyCollection') == 'mycollection'
	assert texttools.name_fix_no_underscore_no_ext('My Collection') == 'mycollection'
	assert texttools.name_fix_no_underscore_no_ext('my collection') == 'mycollection'
}

// Test that different link formats resolve to the same target
fn test_link_target_normalization() {
	// All these should normalize to 'tokensystem'
	test_cases := [
		'token_system',
		'token-system',
		'TokenSystem',
		'token_system.md',
		'token-system.md',
		'TokenSystem.md',
		'TOKEN_SYSTEM',
		'Token_System',
	]

	for test_case in test_cases {
		normalized := normalize_page_name(test_case)
		assert normalized == 'tokensystem', 'Expected "${test_case}" to normalize to "tokensystem", got "${normalized}"'
	}
}

// Test collection name in links
fn test_collection_name_in_links() {
	// All these should normalize to 'collectiona'
	test_cases := [
		'collection_a',
		'collection-a',
		'CollectionA',
		'Collection_A',
		'COLLECTION_A',
	]

	for test_case in test_cases {
		normalized := texttools.name_fix_no_underscore_no_ext(test_case)
		assert normalized == 'collectiona', 'Expected "${test_case}" to normalize to "collectiona", got "${normalized}"'
	}
}

// Test real-world examples
fn test_real_world_examples() {
	// Common documentation page names
	assert normalize_page_name('getting_started.md') == 'gettingstarted'
	assert normalize_page_name('api_reference.md') == 'apireference'
	assert normalize_page_name('user-guide.md') == 'userguide'
	assert normalize_page_name('FAQ.md') == 'faq'
	assert normalize_page_name('README.md') == 'readme'

	// Technical terms
	assert normalize_page_name('token_system.md') == 'tokensystem'
	assert normalize_page_name('mycelium_cloud.md') == 'myceliumcloud'
	assert normalize_page_name('tf_grid.md') == 'tfgrid'
}

// Test that normalization is idempotent (applying it twice gives same result)
fn test_normalization_idempotent() {
	test_cases := [
		'token_system',
		'TokenSystem',
		'token-system',
		'Token System',
	]

	for test_case in test_cases {
		first := normalize_page_name(test_case)
		second := normalize_page_name(first)
		assert first == second, 'Normalization should be idempotent: "${test_case}" -> "${first}" -> "${second}"'
	}
}
