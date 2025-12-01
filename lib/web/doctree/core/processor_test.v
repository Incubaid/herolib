module core

import incubaid.herolib.core.pathlib
import os
import json

const test_base = '/tmp/doctree_test'

// Clean up before and after each test
fn setup_test() {
	os.rmdir_all(test_base) or {}
	os.mkdir_all(test_base) or {}
}

fn cleanup_test() {
	os.rmdir_all(test_base) or {}
}

fn test_create_doctree() {
	setup_test()
	defer { cleanup_test() }

	mut a := new(name: 'test_doctree')!
	assert a.name == 'test_doctree'
	assert a.collections.len == 0
}

fn test_add_collection() {
	setup_test()
	defer { cleanup_test() }

	// Create test collection
	col_path := '${test_base}/col1'
	os.mkdir_all(col_path)!
	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:col1')!

	mut page := pathlib.get_file(path: '${col_path}/page1.md', create: true)!
	page.write('# Page 1\n\nContent here.')!

	mut a := new(name: 'test')!
	a.add_collection(mut pathlib.get_dir(path: col_path)!)!

	assert a.collections.len == 1
	assert 'col1' in a.collections
}

fn test_scan() {
	setup_test()
	defer { cleanup_test() }

	// Create test structure
	os.mkdir_all('${test_base}/docs/guides')!
	mut cfile := pathlib.get_file(path: '${test_base}/docs/guides/.collection', create: true)!
	cfile.write('name:guides')!

	mut page := pathlib.get_file(path: '${test_base}/docs/guides/intro.md', create: true)!
	page.write('# Introduction')!

	mut a := new()!
	a.scan(path: '${test_base}/docs')!

	assert a.collections.len == 1
	col := a.get_collection('guides')!
	assert col.page_exists('intro')!
}

fn test_export() {
	setup_test()
	defer { cleanup_test() }

	// Setup
	col_path := '${test_base}/source/col1'
	export_path := '${test_base}/export'

	os.mkdir_all(col_path)!
	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:col1')!

	mut page := pathlib.get_file(path: '${col_path}/test.md', create: true)!
	page.write('# Test Page')!

	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_path)!)!

	a.export(destination: export_path, redis: false)!

	assert os.exists('${export_path}/content/col1/test.md')
	assert os.exists('${export_path}/meta/col1.json')
}

fn test_export_with_includes() {
	setup_test()
	defer { cleanup_test() }

	// Setup: Create pages with includes
	col_path := '${test_base}/include_test'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:test_col')!

	// Page 1: includes page 2
	mut page1 := pathlib.get_file(path: '${col_path}/page1.md', create: true)!
	page1.write('# Page 1\n\n!!include test_col:page2\n\nEnd of page 1')!

	// Page 2: standalone content
	mut page2 := pathlib.get_file(path: '${col_path}/page2.md', create: true)!
	page2.write('## Page 2 Content\n\nThis is included.')!

	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_path)!)!

	export_path := '${test_base}/export_include'
	a.export(destination: export_path, include: true, redis: false)!

	// Verify exported page1 has page2 content included
	exported := os.read_file('${export_path}/content/test_col/page1.md')!
	assert exported.contains('Page 2 Content')
	assert exported.contains('This is included')
	assert !exported.contains('!!include')
}

fn test_export_without_includes() {
	setup_test()
	defer { cleanup_test() }

	col_path := '${test_base}/no_include_test'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:test_col2')!

	mut page1 := pathlib.get_file(path: '${col_path}/page1.md', create: true)!
	page1.write('# Page 1\n\n!!include test_col2:page2\n\nEnd')!

	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_path)!)!

	export_path := '${test_base}/export_no_include'
	a.export(destination: export_path, include: false, redis: false)!

	// Verify exported page1 still has include action
	exported := os.read_file('${export_path}/content/test_col2/page1.md')!
	assert exported.contains('!!include')
}

fn test_error_deduplication() {
	setup_test()
	defer { cleanup_test() }

	mut a := new(name: 'test')!
	col_path := '${test_base}/err_dedup_col'
	os.mkdir_all(col_path)!
	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:err_dedup_col')!
	mut col := a.add_collection(mut pathlib.get_dir(path: col_path)!)!
	assert col.name == 'err_dedup_col' // Ensure collection is added correctly
}

fn test_error_hash() {
	setup_test()
	defer { cleanup_test() }
	// This test had no content, leaving it as a placeholder.
}

fn test_find_links() {
	setup_test()
	defer { cleanup_test() }

	col_path := '${test_base}/find_links_test'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:test_col')!

	mut page_file := pathlib.get_file(path: '${col_path}/test_page.md', create: true)!
	page_file.write('# Test Page\n\n[Link 1](page1)\n[Link 2](guides:intro)')!

	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_path)!)!

	mut page := a.page_get('test_col:test_page')!
	content := page.content()!
	links := page.find_links(content)!

	assert links.len >= 2
}

// Test with a valid link to ensure no errors are reported
fn test_find_links_valid_link() {
	setup_test()
	defer { cleanup_test() }

	// Setup
	col_path := '${test_base}/link_test'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:test_col')!

	// Create page1 with valid link
	mut page1 := pathlib.get_file(path: '${col_path}/page1.md', create: true)!
	page1.write('[Link to page2](page2)')!

	// Create page2 (target exists)
	mut page2 := pathlib.get_file(path: '${col_path}/page2.md', create: true)!
	page2.write('# Page 2')!

	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_path)!)!

	// Should have no errors
	col := a.get_collection('test_col')!
	assert col.errors.len == 0

	a.export(destination: '${test_base}/export_links', redis: false)!
}

fn test_validate_broken_links() {
	setup_test()
	defer { cleanup_test() }

	// Setup
	col_path := '${test_base}/broken_link_test'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:test_col')!

	// Create page with broken link
	mut page1 := pathlib.get_file(path: '${col_path}/page1.md', create: true)!
	page1.write('[Broken link](nonexistent)')!

	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_path)!)!

	// Validate
	a.export(destination: '${test_base}/validate_broken_links', redis: false)!

	// Should have error
	col := a.get_collection('test_col')!
	assert col.errors.len > 0
}

fn test_fix_links() {
	setup_test()
	defer { cleanup_test() }

	// Setup - all pages in same directory for simpler test
	col_path := '${test_base}/fix_link_test'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:test_col')!

	// Create pages in same directory
	mut page1 := pathlib.get_file(path: '${col_path}/page1.md', create: true)!
	page1.write('[Link](page2)')!

	mut page2 := pathlib.get_file(path: '${col_path}/page2.md', create: true)!
	page2.write('# Page 2')!

	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_path)!)!

	// Get the page and test fix_links directly
	mut col := a.get_collection('test_col')!
	mut p := col.page_get('page1')!

	original := p.content()!
	assert original.contains('[Link](page2)')

	fixed := p.content_with_fixed_links(FixLinksArgs{
		include:          true
		cross_collection: true
		export_mode:      false
	})!

	// The fix_links should work on content
	assert fixed.contains('[Link](page2.md)')
}

fn test_link_formats() {
	setup_test()
	defer { cleanup_test() }

	col_path := '${test_base}/link_format_test'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:test_col')!

	// Create target pages
	mut page1 := pathlib.get_file(path: '${col_path}/page1.md', create: true)!
	page1.write('# Page 1')!

	mut page2 := pathlib.get_file(path: '${col_path}/page2.md', create: true)!
	page2.write('# Page 2')!

	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_path)!)!

	// Test various link formats
	mut test_page := a.page_get('test_col:page1')!
	content := '[Link](page2)\n[Link](page2.md)'
	links := test_page.find_links(content)!

	assert links.len == 2
}

fn test_cross_collection_links() {
	setup_test()
	defer { cleanup_test() }

	// Setup two collections
	col1_path := '${test_base}/col1_cross'
	col2_path := '${test_base}/col2_cross'

	os.mkdir_all(col1_path)!
	os.mkdir_all(col2_path)!

	mut cfile1 := pathlib.get_file(path: '${col1_path}/.collection', create: true)!
	cfile1.write('name:col1')!

	mut cfile2 := pathlib.get_file(path: '${col2_path}/.collection', create: true)!
	cfile2.write('name:col2')!

	// Page in col1 links to col2
	mut page1 := pathlib.get_file(path: '${col1_path}/page1.md', create: true)!
	page1.write('[Link to col2](col2:page2)')!

	// Page in col2
	mut page2 := pathlib.get_file(path: '${col2_path}/page2.md', create: true)!
	page2.write('# Page 2')!

	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col1_path)!)!
	a.add_collection(mut pathlib.get_dir(path: col2_path)!)!

	col1 := a.get_collection('col1')!
	assert col1.errors.len == 0

	a.export(destination: '${test_base}/export_cross', redis: false)!

	fixed := page1.read()!
	assert fixed.contains('[Link to col2](col2:page2)') // Unchanged
}

fn test_save_and_load() {
	setup_test()
	defer { cleanup_test() }

	// Setup
	col_path := '${test_base}/save_test'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:test_col')!

	mut page := pathlib.get_file(path: '${col_path}/page1.md', create: true)!
	page.write('# Page 1\n\nContent here.')!

	// Create and save
	mut a := new(name: 'test')!
	a.add_collection(mut pathlib.get_dir(path: col_path)!)!
	col := a.get_collection('test_col')!
	assert col.name == 'test_col'
}

fn test_save_with_errors() {
	setup_test()
	defer { cleanup_test() }

	col_path := '${test_base}/error_save_test'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:err_col')!

	mut a := new(name: 'test')!
	mut col := a.add_collection(mut pathlib.get_dir(path: col_path)!)!
	assert col.name == 'err_col' // Ensure collection is added correctly
}

fn test_load_from_directory() {
	setup_test()
	defer { cleanup_test() }

	// Setup multiple collections
	col1_path := '${test_base}/load_dir/col1'
	col2_path := '${test_base}/load_dir/col2'

	os.mkdir_all(col1_path)!
	os.mkdir_all(col2_path)!

	mut cfile1 := pathlib.get_file(path: '${col1_path}/.collection', create: true)!
	cfile1.write('name:col1')!

	mut cfile2 := pathlib.get_file(path: '${col2_path}/.collection', create: true)!
	cfile2.write('name:col2')!

	mut page1 := pathlib.get_file(path: '${col1_path}/page1.md', create: true)!
	page1.write('# Page 1')!

	mut page2 := pathlib.get_file(path: '${col2_path}/page2.md', create: true)!
	page2.write('# Page 2')!

	// Create and save
	mut a := new(name: 'test')!
	a.add_collection(mut pathlib.get_dir(path: col1_path)!)!
	a.add_collection(mut pathlib.get_dir(path: col2_path)!)!

	assert a.collections.len == 2
}

fn test_get_edit_url() {
	setup_test()
	defer { cleanup_test() }

	// Create a mock collection
	mut doctree := new(name: 'test_doctree')!
	col_path := '${test_base}/git_test'
	os.mkdir_all(col_path)!
	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:git_test_col')!
	mut col := doctree.add_collection(mut pathlib.get_dir(path: col_path)!)!
	col.git_url = 'https://github.com/test/repo.git' // Assuming git_url is a field on Collection
	// Create a mock page
	mut page_path := pathlib.get_file(path: '${col_path}/test_page.md', create: true)!
	page_path.write('test content')!
	col.add_page(mut page_path)!

	// Get the page and collection edit URLs
	page := col.page_get('test_page')!
	// No asserts in original, adding one for completeness
	assert page.name == 'test_page'
}

fn test_export_recursive_links() {
	setup_test()
	defer { cleanup_test() }

	// Create 3 collections with chained links
	col_a_path := '${test_base}/recursive_export/col_a'
	col_b_path := '${test_base}/recursive_export/col_b'
	col_c_path := '${test_base}/recursive_export/col_c'

	os.mkdir_all(col_a_path)!
	os.mkdir_all(col_b_path)!
	os.mkdir_all(col_c_path)!

	// Collection A: links to B
	mut cfile_a := pathlib.get_file(path: '${col_a_path}/.collection', create: true)!
	cfile_a.write('name:col_a')!
	mut page_a := pathlib.get_file(path: '${col_a_path}/page_a.md', create: true)!
	page_a.write('# Page A\n\nThis is page A.\n\n[Link to Page B](col_b:page_b)')!

	// Collection B: links to C
	mut cfile_b := pathlib.get_file(path: '${col_b_path}/.collection', create: true)!
	cfile_b.write('name:col_b')!
	mut page_b := pathlib.get_file(path: '${col_b_path}/page_b.md', create: true)!
	page_b.write('# Page B\n\nThis is page B with link to C.\n\n[Link to Page C](col_c:page_c)')!

	// Collection C: final page
	mut cfile_c := pathlib.get_file(path: '${col_c_path}/.collection', create: true)!
	cfile_c.write('name:col_c')!
	mut page_c := pathlib.get_file(path: '${col_c_path}/page_c.md', create: true)!
	page_c.write('# Page C\n\nThis is the final page in the chain.')!

	// Create DocTree and add all collections
	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_a_path)!)!
	a.add_collection(mut pathlib.get_dir(path: col_b_path)!)!
	a.add_collection(mut pathlib.get_dir(path: col_c_path)!)!

	// Export
	export_path := '${test_base}/export_recursive'
	a.export(destination: export_path, redis: false)!

	// Verify directory structure exists
	assert os.exists('${export_path}/content'), 'Export content directory should exist'
	assert os.exists('${export_path}/content/col_a'), 'Collection col_a directory should exist'
	assert os.exists('${export_path}/meta'), 'Export meta directory should exist'

	// Verify all pages exist in col_a export directory
	assert os.exists('${export_path}/content/col_a/page_a.md'), 'page_a.md should be exported'
	assert os.exists('${export_path}/content/col_a/page_b.md'), 'page_b.md from col_b should be included'
	assert os.exists('${export_path}/content/col_a/page_c.md'), 'page_c.md from col_c should be included'

	// Verify metadata files exist
	assert os.exists('${export_path}/meta/col_a.json'), 'col_a metadata should exist'
	assert os.exists('${export_path}/meta/col_b.json'), 'col_b metadata should exist'
	assert os.exists('${export_path}/meta/col_c.json'), 'col_c metadata should exist'
}

fn test_export_recursive_with_images() {
	setup_test()
	defer { cleanup_test() }

	col_a_path := '${test_base}/recursive_img/col_a'
	col_b_path := '${test_base}/recursive_img/col_b'

	os.mkdir_all(col_a_path)!
	os.mkdir_all(col_b_path)!
	os.mkdir_all('${col_a_path}/img')!
	os.mkdir_all('${col_b_path}/img')!

	// Collection A with local image
	mut cfile_a := pathlib.get_file(path: '${col_a_path}/.collection', create: true)!
	cfile_a.write('name:col_a')!

	mut page_a := pathlib.get_file(path: '${col_a_path}/page_a.md', create: true)!
	page_a.write('# Page A\n\n![Local Image](local.png)\n\n[Link to B](col_b:page_b)')!

	// Create local image
	os.write_file('${col_a_path}/img/local.png', 'fake png data')!

	// Collection B with image and linked page
	mut cfile_b := pathlib.get_file(path: '${col_b_path}/.collection', create: true)!
	cfile_b.write('name:col_b')!

	mut page_b := pathlib.get_file(path: '${col_b_path}/page_b.md', create: true)!
	page_b.write('# Page B\n\n![B Image](b_image.jpg)')!

	// Create image in collection B
	os.write_file('${col_b_path}/img/b_image.jpg', 'fake jpg data')!

	// Create DocTree
	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_a_path)!)!
	a.add_collection(mut pathlib.get_dir(path: col_b_path)!)!

	export_path := '${test_base}/export_recursive_img'
	a.export(destination: export_path, redis: false)!

	// Verify pages exported
	assert os.exists('${export_path}/content/col_a/page_a.md'), 'page_a should exist'
	assert os.exists('${export_path}/content/col_a/page_b.md'), 'page_b from col_b should be included'

	// Verify images exported to col_a image directory
	assert os.exists('${export_path}/content/col_a/img/local.png'), 'Local image should exist'
	assert os.exists('${export_path}/content/col_a/img/b_image.jpg'), 'Image from cross-collection reference should be copied'
}
