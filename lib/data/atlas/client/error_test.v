module client

// Test error_collection_not_found
fn test_error_collection_not_found() {
	err_handler := AtlasError{}
	result := err_handler.error_collection_not_found(collection_name: 'test_collection')

	assert result.msg().contains('collection_not_found')
	assert result.msg().contains('test_collection')
	assert result.msg().contains('Collection')
	assert result.msg().contains('not found')
}

// Test error_collection_not_found with special characters
fn test_error_collection_not_found_special_chars() {
	err_handler := AtlasError{}
	result := err_handler.error_collection_not_found(collection_name: 'test-collection_123')

	assert result.msg().contains('test-collection_123')
}

// Test error_collection_not_found with empty string
fn test_error_collection_not_found_empty() {
	err_handler := AtlasError{}
	result := err_handler.error_collection_not_found(collection_name: '')

	assert result.msg().contains('collection_not_found')
}

// Test error_collection_not_found_at
fn test_error_collection_not_found_at() {
	err_handler := AtlasError{}
	result := err_handler.error_collection_not_found_at(
		collection_name: 'my_collection'
		path:            '/tmp/meta/my_collection.json'
	)

	assert result.msg().contains('collection_not_found')
	assert result.msg().contains('my_collection')
	assert result.msg().contains('/tmp/meta/my_collection.json')
	assert result.msg().contains('Metadata file')
}

// Test error_page_not_found
fn test_error_page_not_found() {
	err_handler := AtlasError{}
	result := err_handler.error_page_not_found(
		collection_name: 'docs'
		page_name:       'intro'
	)

	assert result.msg().contains('page_not_found')
	assert result.msg().contains('docs')
	assert result.msg().contains('intro')
	assert result.msg().contains('Page')
}

// Test error_page_not_found with underscores and dashes
fn test_error_page_not_found_naming() {
	err_handler := AtlasError{}
	result := err_handler.error_page_not_found(
		collection_name: 'my-docs_v2'
		page_name:       'getting_started'
	)

	assert result.msg().contains('my-docs_v2')
	assert result.msg().contains('getting_started')
}

// Test error_page_not_found_in_metadata
fn test_error_page_not_found_in_metadata() {
	err_handler := AtlasError{}
	result := err_handler.error_page_not_found_in_metadata(
		collection_name: 'api'
		page_name:       'endpoints'
	)

	assert result.msg().contains('page_not_found')
	assert result.msg().contains('endpoints')
	assert result.msg().contains('metadata')
}

// Test error_page_file_not_exists
fn test_error_page_file_not_exists() {
	err_handler := AtlasError{}
	result := err_handler.error_page_file_not_exists(
		page_path: '/tmp/content/docs/page.md'
	)

	assert result.msg().contains('page_not_found')
	assert result.msg().contains('/tmp/content/docs/page.md')
	assert result.msg().contains('does not exist')
}

// Test error_file_not_found
fn test_error_file_not_found() {
	err_handler := AtlasError{}
	result := err_handler.error_file_not_found(
		collection_name: 'resources'
		file_name:       'data.csv'
	)

	assert result.msg().contains('file_not_found')
	assert result.msg().contains('resources')
	assert result.msg().contains('data.csv')
	assert result.msg().contains('File')
}

// Test error_file_not_found with various extensions
fn test_error_file_not_found_extensions() {
	err_handler := AtlasError{}

	// Test PDF
	result1 := err_handler.error_file_not_found(
		collection_name: 'docs'
		file_name:       'manual.pdf'
	)
	assert result1.msg().contains('manual.pdf')

	// Test JSON
	result2 := err_handler.error_file_not_found(
		collection_name: 'config'
		file_name:       'settings.json'
	)
	assert result2.msg().contains('settings.json')
}

// Test error_image_not_found
fn test_error_image_not_found() {
	err_handler := AtlasError{}
	result := err_handler.error_image_not_found(
		collection_name: 'gallery'
		image_name:      'logo.png'
	)

	assert result.msg().contains('image_not_found')
	assert result.msg().contains('gallery')
	assert result.msg().contains('logo.png')
	assert result.msg().contains('Image')
}

// Test error_image_not_found with various image formats
fn test_error_image_not_found_formats() {
	err_handler := AtlasError{}

	formats := ['logo.png', 'banner.jpg', 'icon.svg', 'photo.webp', 'diagram.gif']
	for format in formats {
		result := err_handler.error_image_not_found(
			collection_name: 'images'
			image_name:      format
		)
		assert result.msg().contains(format)
	}
}

// Test error_image_not_found_linked
fn test_error_image_not_found_linked() {
	err_handler := AtlasError{}
	result := err_handler.error_image_not_found_linked(
		collection_name: 'blog'
		image_name:      'header.jpg'
	)

	assert result.msg().contains('Linked image')
	assert result.msg().contains('blog')
	assert result.msg().contains('header.jpg')
}

// Test error_export_dir_not_found
fn test_error_export_dir_not_found() {
	err_handler := AtlasError{}
	result := err_handler.error_export_dir_not_found(
		export_dir: '/nonexistent/path'
	)

	assert result.msg().contains('export_dir_not_found')
	assert result.msg().contains('/nonexistent/path')
	assert result.msg().contains('Export directory')
}

// Test error_invalid_export_structure
fn test_error_invalid_export_structure() {
	err_handler := AtlasError{}
	result := err_handler.error_invalid_export_structure(
		content_dir: '/tmp/export/content'
	)

	assert result.msg().contains('invalid_export_structure')
	assert result.msg().contains('/tmp/export/content')
	assert result.msg().contains('Content directory')
}

// Test new_error function
fn test_new_error() {
	err := new_error(
		message: 'Test error message'
		reason:  .page_not_found
	)

	assert err.message == 'Test error message'
	assert err.reason == .page_not_found
}

// Test new_error with all error types
fn test_new_error_all_types() {
	error_types := [
		AtlasErrors.collection_not_found,
		AtlasErrors.page_not_found,
		AtlasErrors.file_not_found,
		AtlasErrors.image_not_found,
		AtlasErrors.export_dir_not_found,
		AtlasErrors.invalid_export_structure,
	]

	for error_type in error_types {
		err := new_error(
			message: 'Test message'
			reason:  error_type
		)
		assert err.reason == error_type
	}
}

// Test throw_error internal method
fn test_throw_error() {
	err_handler := AtlasError{}
	result := err_handler.throw_error(
		message: 'Custom error message'
		reason:  .file_not_found
	)

	assert result.msg().contains('file_not_found')
	assert result.msg().contains('Custom error message')
}

// Test error messages are properly formatted
fn test_error_message_format() {
	err_handler := AtlasError{}

	// Test that error messages follow the pattern: "reason: message"
	result := err_handler.error_page_not_found(
		collection_name: 'test'
		page_name:       'page'
	)

	msg := result.msg()
	assert msg.contains(':')

	// Split by colon and verify format
	parts := msg.split(':')
	assert parts.len >= 2
}

// Test error consistency across similar methods
fn test_error_consistency() {
	err_handler := AtlasError{}

	// All "not found" errors should contain "not found" in message
	err1 := err_handler.error_collection_not_found(collection_name: 'test')
	err2 := err_handler.error_page_not_found(collection_name: 'test', page_name: 'page')
	err3 := err_handler.error_file_not_found(collection_name: 'test', file_name: 'file')
	err4 := err_handler.error_image_not_found(collection_name: 'test', image_name: 'img')

	assert err1.msg().contains('not found')
	assert err2.msg().contains('not found')
	assert err3.msg().contains('not found')
	assert err4.msg().contains('not found')
}
