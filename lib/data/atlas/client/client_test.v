module client

import os
import incubaid.herolib.core.texttools { name_fix_no_underscore_no_ext }

// Helper function to create a test export directory structure
fn setup_test_export() string {
	test_dir := os.join_path(os.temp_dir(), 'atlas_client_test_${os.getpid()}')

	// Clean up if exists
	if os.exists(test_dir) {
		os.rmdir_all(test_dir) or {}
	}

	// Create directory structure
	os.mkdir_all(os.join_path(test_dir, 'content', 'testcollection')) or { panic(err) }
	os.mkdir_all(os.join_path(test_dir, 'content', 'anothercollection')) or { panic(err) }
	os.mkdir_all(os.join_path(test_dir, 'meta')) or { panic(err) }

	// Create test pages
	os.write_file(os.join_path(test_dir, 'content', 'testcollection', 'page1.md'), '# Page 1\n\nContent here.') or {
		panic(err)
	}
	os.write_file(os.join_path(test_dir, 'content', 'testcollection', 'page2.md'), '# Page 2\n\n![logo](logo.png)') or {
		panic(err)
	}
	os.write_file(os.join_path(test_dir, 'content', 'anothercollection', 'intro.md'),
		'# Intro\n\nWelcome!') or { panic(err) }

	// Create test images
	os.mkdir_all(os.join_path(test_dir, 'content', 'testcollection', 'img')) or { panic(err) }
	os.write_file(os.join_path(test_dir, 'content', 'testcollection', 'img', 'logo.png'), 'fake png data') or {
		panic(err)
	}
	os.write_file(os.join_path(test_dir, 'content', 'testcollection', 'img', 'banner.jpg'), 'fake jpg data') or {
		panic(err)
	}

	// Create test files
	os.mkdir_all(os.join_path(test_dir, 'content', 'testcollection', 'files')) or { panic(err) }
	os.write_file(os.join_path(test_dir, 'content', 'testcollection', 'files', 'data.csv'), 'col1,col2\nval1,val2') or {
		panic(err)
	}

	// Create metadata files
	metadata1 := '{
  "name": "testcollection",
  "path": "",
  "pages": {
    "page1": {
      "name": "page1",
      "path": "",
      "collection_name": "testcollection",
      "links": []
    },
    "page2": {
      "name": "page2",
      "path": "",
      "collection_name": "testcollection",
      "links": [
        {
          "src": "logo.png",
          "text": "logo",
          "target": "logo.png",
          "line": 3,
          "target_collection_name": "testcollection",
          "target_item_name": "logo",
          "status": "ok",
          "is_file_link": false,
          "is_image_link": true
        }
      ]
    }
  },
  "files": {
    "logo.png": {
      "name": "logo.png",
      "path": "img/logo.png"
    },
    "banner.jpg": {
      "name": "banner.jpg",
      "path": "img/banner.jpg"
    },
    "data.csv": {
      "name": "data.csv",
      "path": "files/data.csv"
    }
  },
  "errors": []
}'
	os.write_file(os.join_path(test_dir, 'meta', 'testcollection.json'), metadata1) or {
		panic(err)
	}

	metadata2 := '{
  "name": "anothercollection",
  "path": "",
  "pages": {
    "intro": {
      "name": "intro",
      "path": "",
      "collection_name": "anothercollection",
      "links": []
    }
  },
  "files": {},
  "errors": [
    {
      "category": "test",
      "page_key": "intro",
      "message": "Test error",
      "line": 10
    }
  ]
}'
	os.write_file(os.join_path(test_dir, 'meta', 'anothercollection.json'), metadata2) or {
		panic(err)
	}

	return test_dir
}

// Helper function to cleanup test directory
fn cleanup_test_export(test_dir string) {
	os.rmdir_all(test_dir) or {}
}

// Test creating a new client
fn test_new_client() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	assert client.export_dir == test_dir
}

// Test creating client with non-existent directory
fn test_new_client_nonexistent_dir() {
	mut client := new(export_dir: '/nonexistent/path/to/export') or { panic(err) }
	// Client creation should succeed, but operations will fail
	assert client.export_dir == '/nonexistent/path/to/export'
}

// Test get_page_path - success
fn test_get_page_path_success() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	path := client.get_page_path('testcollection', 'page1') or { panic(err) }

	assert path.contains('testcollection')
	assert path.ends_with('page1.md')
	assert os.exists(path)
}

// Test get_page_path - with naming normalization
fn test_get_page_path_normalization() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	// Create a page with normalized name
	normalized_name := name_fix_no_underscore_no_ext('Test_Page-Name')
	os.write_file(os.join_path(test_dir, 'content', 'testcollection', '${normalized_name}.md'),
		'# Test') or { panic(err) }

	mut client := new(export_dir: test_dir) or { panic(err) }

	// Should find the page regardless of input format
	path := client.get_page_path('testcollection', 'Test_Page-Name') or { panic(err) }
	assert os.exists(path)
}

// Test get_page_path - page not found
fn test_get_page_path_not_found() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	client.get_page_path('testcollection', 'nonexistent') or {
		assert err.msg().contains('page_not_found')
		assert err.msg().contains('nonexistent')
		return
	}
	assert false, 'Should have returned an error'
}

// Test get_page_path - export dir not found
fn test_get_page_path_no_export_dir() {
	mut client := new(export_dir: '/nonexistent/path') or { panic(err) }
	client.get_page_path('testcollection', 'page1') or {
		assert err.msg().contains('export_dir_not_found')
		return
	}
	assert false, 'Should have returned an error'
}

// Test get_file_path - success
fn test_get_file_path_success() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	path := client.get_file_path('testcollection', 'data.csv') or { panic(err) }

	assert path.contains('testcollection')
	assert path.ends_with('data.csv')
	assert os.exists(path)
}

// Test get_file_path - file not found
fn test_get_file_path_not_found() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	client.get_file_path('testcollection', 'missing.pdf') or {
		assert err.msg().contains('file_not_found')
		assert err.msg().contains('missing.pdf')
		return
	}
	assert false, 'Should have returned an error'
}

// Test get_image_path - success
fn test_get_image_path_success() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	path := client.get_image_path('testcollection', 'logo.png') or { panic(err) }

	assert path.contains('testcollection')
	assert path.ends_with('logo.png')
	assert os.exists(path)
}

// Test get_image_path - image not found
fn test_get_image_path_not_found() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	client.get_image_path('testcollection', 'missing.jpg') or {
		assert err.msg().contains('image_not_found')
		assert err.msg().contains('missing.jpg')
		return
	}
	assert false, 'Should have returned an error'
}

// Test page_exists - true
fn test_page_exists_true() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	exists := client.page_exists('testcollection', 'page1')
	assert exists == true
}

// Test page_exists - false
fn test_page_exists_false() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	exists := client.page_exists('testcollection', 'nonexistent')
	assert exists == false
}

// Test file_exists - true
fn test_file_exists_true() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	exists := client.file_exists('testcollection', 'data.csv')
	assert exists == true
}

// Test file_exists - false
fn test_file_exists_false() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	exists := client.file_exists('testcollection', 'missing.pdf')
	assert exists == false
}

// Test image_exists - true
fn test_image_exists_true() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	exists := client.image_exists('testcollection', 'logo.png')
	assert exists == true
}

// Test image_exists - false
fn test_image_exists_false() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	exists := client.image_exists('testcollection', 'missing.svg')
	assert exists == false
}

// Test get_page_content - success
fn test_get_page_content_success() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	content := client.get_page_content('testcollection', 'page1') or { panic(err) }

	assert content.contains('# Page 1')
	assert content.contains('Content here.')
}

// Test get_page_content - page not found
fn test_get_page_content_not_found() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	client.get_page_content('testcollection', 'nonexistent') or {
		assert err.msg().contains('page_not_found')
		return
	}
	assert false, 'Should have returned an error'
}

// Test list_collections
fn test_list_collections() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	collections := client.list_collections() or { panic(err) }

	assert collections.len == 2
	assert 'testcollection' in collections
	assert 'anothercollection' in collections
}

// Test list_collections - no content dir
fn test_list_collections_no_content_dir() {
	test_dir := os.join_path(os.temp_dir(), 'empty_export_${os.getpid()}')
	os.mkdir_all(test_dir) or { panic(err) }
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	client.list_collections() or {
		assert err.msg().contains('invalid_export_structure')
		return
	}
	assert false, 'Should have returned an error'
}

// Test list_pages - success
fn test_list_pages_success() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	pages := client.list_pages('testcollection') or { panic(err) }

	assert pages.len == 2
	assert 'page1' in pages
	assert 'page2' in pages
}

// Test list_pages - collection not found
fn test_list_pages_collection_not_found() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	client.list_pages('nonexistent') or {
		assert err.msg().contains('collection_not_found')
		return
	}
	assert false, 'Should have returned an error'
}

// Test list_files - success
fn test_list_files_success() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	files := client.list_files('testcollection') or { panic(err) }

	assert files.len == 1
	assert 'data.csv' in files
}

// Test list_files - no files
fn test_list_files_empty() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	files := client.list_files('anothercollection') or { panic(err) }

	assert files.len == 0
}

// Test list_images - success
fn test_list_images_success() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	images := client.list_images('testcollection') or { panic(err) }

	assert images.len == 2
	assert 'logo.png' in images
	assert 'banner.jpg' in images
}

// Test list_images - no images
fn test_list_images_empty() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	images := client.list_images('anothercollection') or { panic(err) }

	assert images.len == 0
}

// Test list_pages_map
fn test_list_pages_map() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	pages_map := client.list_pages_map() or { panic(err) }

	assert pages_map.len == 2
	assert 'testcollection' in pages_map
	assert 'anothercollection' in pages_map
	assert pages_map['testcollection'].len == 2
	assert pages_map['anothercollection'].len == 1
}

// Test list_markdown
fn test_list_markdown() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	markdown := client.list_markdown() or { panic(err) }

	assert markdown.contains('testcollection')
	assert markdown.contains('anothercollection')
	assert markdown.contains('page1')
	assert markdown.contains('page2')
	assert markdown.contains('intro')
	assert markdown.contains('##')
	assert markdown.contains('*')
}

// Test get_collection_metadata - success
fn test_get_collection_metadata_success() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	metadata := client.get_collection_metadata('testcollection') or { panic(err) }

	assert metadata.name == 'testcollection'
	assert metadata.pages.len == 2
	assert metadata.errors.len == 0
}

// Test get_collection_metadata - with errors
fn test_get_collection_metadata_with_errors() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	metadata := client.get_collection_metadata('anothercollection') or { panic(err) }

	assert metadata.name == 'anothercollection'
	assert metadata.pages.len == 1
	assert metadata.errors.len == 1
	assert metadata.errors[0].message == 'Test error'
	assert metadata.errors[0].line == 10
}

// Test get_collection_metadata - not found
fn test_get_collection_metadata_not_found() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	client.get_collection_metadata('nonexistent') or {
		assert err.msg().contains('collection_not_found')
		return
	}
	assert false, 'Should have returned an error'
}

// Test get_page_links - success
fn test_get_page_links_success() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	links := client.get_page_links('testcollection', 'page2') or { panic(err) }

	assert links.len == 1
	assert links[0].target_item_name == 'logo'
	assert links[0].target_collection_name == 'testcollection'
	assert links[0].is_image_link == true
}

// Test get_page_links - no links
fn test_get_page_links_empty() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	links := client.get_page_links('testcollection', 'page1') or { panic(err) }

	assert links.len == 0
}

// Test get_page_links - page not found
fn test_get_page_links_page_not_found() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	client.get_page_links('testcollection', 'nonexistent') or {
		assert err.msg().contains('page_not_found')
		return
	}
	assert false, 'Should have returned an error'
}

// Test get_collection_errors - success
fn test_get_collection_errors_success() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	errors := client.get_collection_errors('anothercollection') or { panic(err) }

	assert errors.len == 1
	assert errors[0].message == 'Test error'
}

// Test get_collection_errors - no errors
fn test_get_collection_errors_empty() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	errors := client.get_collection_errors('testcollection') or { panic(err) }

	assert errors.len == 0
}

// Test has_errors - true
fn test_has_errors_true() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	has_errors := client.has_errors('anothercollection')

	assert has_errors == true
}

// Test has_errors - false
fn test_has_errors_false() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	has_errors := client.has_errors('testcollection')

	assert has_errors == false
}

// Test has_errors - collection not found
fn test_has_errors_collection_not_found() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	has_errors := client.has_errors('nonexistent')

	assert has_errors == false
}

// Test copy_images - success
fn test_copy_images_success() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	dest_dir := os.join_path(os.temp_dir(), 'copy_dest_${os.getpid()}')
	os.mkdir_all(dest_dir) or { panic(err) }
	defer { cleanup_test_export(dest_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	client.copy_images('testcollection', 'page2', dest_dir) or { panic(err) }

	// Check that logo.png was copied to img subdirectory
	assert os.exists(os.join_path(dest_dir, 'img', 'logo.png'))
}

// Test copy_images - no images
fn test_copy_images_no_images() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	dest_dir := os.join_path(os.temp_dir(), 'copy_dest_empty_${os.getpid()}')
	os.mkdir_all(dest_dir) or { panic(err) }
	defer { cleanup_test_export(dest_dir) }

	mut client := new(export_dir: test_dir) or { panic(err) }
	client.copy_images('testcollection', 'page1', dest_dir) or { panic(err) }

	// Should succeed even with no images
	assert true
}

// Test naming normalization edge cases
fn test_naming_normalization_underscores() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	// Create page with underscores
	normalized := texttools.name_fix('test_page_name')
	os.write_file(os.join_path(test_dir, 'content', 'testcollection', '${normalized}.md'),
		'# Test') or { panic(err) }

	mut client := new(export_dir: test_dir) or { panic(err) }

	// Should find with underscores
	exists := client.page_exists('testcollection', 'test_page_name')
	assert exists == true
}

// Test naming normalization edge cases - dashes
fn test_naming_normalization_dashes() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	// Create page with dashes
	normalized := texttools.name_fix('test-page-name')
	os.write_file(os.join_path(test_dir, 'content', 'testcollection', '${normalized}.md'),
		'# Test') or { panic(err) }

	mut client := new(export_dir: test_dir) or { panic(err) }

	// Should find with dashes
	exists := client.page_exists('testcollection', 'test-page-name')
	assert exists == true
}

// Test naming normalization edge cases - mixed case
fn test_naming_normalization_case() {
	test_dir := setup_test_export()
	defer { cleanup_test_export(test_dir) }

	// Create page with mixed case
	normalized := texttools.name_fix('TestPageName')
	os.write_file(os.join_path(test_dir, 'content', 'testcollection', '${normalized}.md'),
		'# Test') or { panic(err) }

	mut client := new(export_dir: test_dir) or { panic(err) }

	// Should find with mixed case
	exists := client.page_exists('testcollection', 'TestPageName')
	assert exists == true
}
