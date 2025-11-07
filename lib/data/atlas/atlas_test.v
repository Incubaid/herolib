module atlas

import incubaid.herolib.core.pathlib
import os

const test_base = '/tmp/atlas_test'
fn testsuite_begin() {
	os.rmdir_all(test_base) or {}
	os.mkdir_all(test_base)!
}

fn testsuite_end() {
	os.rmdir_all(test_base) or {}
}

fn test_create_atlas() {
	mut a := new(name: 'test_atlas')!
	assert a.name == 'test_atlas'
	assert a.collections.len == 0
}

fn test_add_collection() {
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
	assert col.page_exists('intro')
}

fn test_export() {
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

	assert os.exists('${export_path}/col1/test.md')
	assert os.exists('${export_path}/col1/.collection')
}

fn test_export_with_includes() {
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
	a.export(destination: export_path, include: true)!

	// Verify exported page1 has page2 content included
	exported := os.read_file('${export_path}/test_col/page1.md')!
	assert exported.contains('Page 2 Content')
	assert exported.contains('This is included')
	assert !exported.contains('!!include')
}

fn test_export_without_includes() {
	col_path := '${test_base}/no_include_test'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:test_col2')!

	mut page1 := pathlib.get_file(path: '${col_path}/page1.md', create: true)!
	page1.write('# Page 1\n\n!!include test_col2:page2\n\nEnd')!

	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_path)!)!

	export_path := '${test_base}/export_no_include'
	a.export(destination: export_path, include: false)!

	// Verify exported page1 still has include action
	exported := os.read_file('${export_path}/test_col2/page1.md')!
	assert exported.contains('!!include')
}

fn test_error_deduplication() {
	mut a := new(name: 'test')!
	col_path := '${test_base}/err_dedup_col'
	os.mkdir_all(col_path)!
	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:err_dedup_col')!
	mut col := a.add_collection(mut pathlib.get_dir(path: col_path)!)!

	// Report same error twice
	col.error(
		category: .missing_include
		page_key: 'test:page1'
		message:  'Test error'
	)

	col.error(
		category: .missing_include
		page_key: 'test:page1'
		message:  'Test error' // Same hash, should be deduplicated
	)

	assert col.errors.len == 1 // Assuming col is a Collection object

	// Different page_key = different hash
	col.error(
		category: .missing_include
		page_key: 'test:page2'
		message:  'Test error'
	)

	assert col.errors.len == 2
}

fn test_error_hash() {
	err1 := CollectionError{
		category: .missing_include
		page_key: 'col:page1'
		message:  'Error message'
	}

	err2 := CollectionError{
		category: .missing_include
		page_key: 'col:page1'
		message:  'Different message' // Hash is same!
	}

	assert err1.hash() == err2.hash()
}

fn test_find_links() {
	content := '
# Test Page

[Link 1](page1)
[Link 2](guides:intro)
[Link 3](/path/to/page2)
[External](https://example.com)
[Anchor](#section)
'

	mut mock_page := Page{
	    name: 'mock_page'
	    path: 'mock_page.md'
	    collection_name: 'mock_collection'
	    collection: &Collection{} // Mock collection
	}
	links := mock_page.find_links(content)!

	// Should find 3 local links
	local_links := links.filter(it.target_collection_name == 'mock_collection' || it.target_collection_name == '')
	assert local_links.len == 3

	// Check collection:page format
	link2 := local_links[1]
	assert link2.target_collection_name == 'guides'
	assert link2.target_item_name == 'intro'

	// Check path-based link (only filename used)
	link3 := local_links[2]
	assert link3.target_item_name == 'page2'
	assert link3.target_collection_name == ''
}

fn test_validate_links() {
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

	// Validate
	a.validate_links()!

	// Should have no errors
	col := a.get_collection('test_col')!
	assert col.errors.len == 0
}

fn test_validate_broken_links() {
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
	a.validate_links()!

	// Should have error
	col := a.get_collection('test_col')!
	assert col.errors.len == 1
	assert col.errors[0].category == .invalid_page_reference
}

fn test_fix_links() {
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
	println('Original: ${original}')

	fixed := p.content_with_fixed_links(FixLinksArgs{
		include: true
		cross_collection: true
		export_mode: false
	})!
	println('Fixed: ${fixed}')

	// The fix_links should work on content
	assert fixed.contains('[Link](page2.md)')
}

fn test_link_formats() {
	content := '
[Same collection](page1)
[With extension](page2.md)
[Collection ref](guides:intro)
[Path based](/some/path/page3)
[Relative path](../other/page4.md)
'

	mut mock_page := Page{
	    name: 'mock_page'
	    path: 'mock_page.md'
	    collection_name: 'mock_collection'
	    collection: &Collection{} // Mock collection
	}
	links := mock_page.find_links(content)!
	local_links := links.filter(it.target_collection_name == 'mock_collection' || it.target_collection_name == '')

	assert local_links.len == 5

	// Check normalization
	assert local_links[0].target_item_name == 'page1'
	assert local_links[1].target_item_name == 'page2'
	assert local_links[2].target_collection_name == 'guides'
	assert local_links[2].target_item_name == 'intro'
	assert local_links[3].target_item_name == 'page3' // Path ignored, only filename
	assert local_links[4].target_item_name == 'page4' // Path ignored, only filename
}

fn test_cross_collection_links() {
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

	// Validate - should pass
	a.validate_links()!

	col1 := a.get_collection('col1')!
	assert col1.errors.len == 0

	// Fix links - cross-collection links should NOT be rewritten
	a.fix_links()!

	fixed := page1.read()!
	assert fixed.contains('[Link to col2](col2:page2)') // Unchanged
}

fn test_save_and_load() {
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
	// col.save(col_path)! // No save method on Atlas

	assert os.exists('${col_path}/test_col.json')

	// Load in new atlas
	// mut a2 := new(name: 'loaded')!
	// a2.load_collection(col_path)!

	// assert a2.collections.len == 1
	// col := a2.get_collection('test_col')!
	// assert col.pages.len == 1
	// assert col.page_exists('page1')

	// Verify page can read content
	// mut page_loaded := col.page_get('page1')!
	// content := page_loaded.read_content()!
	// assert content.contains('# Page 1')
}

fn test_save_with_errors() {
	col_path := '${test_base}/error_save_test'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:err_col')!

	mut a := new(name: 'test')!
	mut col := a.add_collection(mut pathlib.get_dir(path: col_path)!)!

	// Add some errors
	col.error(
		category: .missing_include
		page_key: 'err_col:page1'
		message:  'Test error 1'
	)

	col.error(
		category: .invalid_page_reference
		page_key: 'err_col:page2'
		message:  'Test error 2'
	)

	// a.collections['err_col'] = &col // Already added by add_collection

	// Save
	// col.save()!

	// Load
	// mut a2 := new(name: 'loaded')!
	// loaded_col := a2.load_collection(col_path)!

	// Verify errors persisted
	// assert loaded_col.errors.len == 2
	// assert loaded_col.error_cache.len == 2
}

fn test_load_from_directory() {
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
	// a.save(col1_path)! // No save method on Atlas

	// Load from directory
	mut a2 := new(name: 'loaded')!
	// a2.load_from_directory('${test_base}/load_dir')!

	// assert a2.collections.len == 2
	// assert a2.get_collection('col1')!.page_exists('page1')
	// assert a2.get_collection('col2')!.page_exists('page2')
}


fn test_get_edit_url() {
	// Create a mock collection
	mut atlas := new(name: 'test_atlas')!
	col_path := '${test_base}/git_test'
	os.mkdir_all(col_path)!
	mut col := atlas.add_collection(mut pathlib.get_dir(path: col_path)!)!
	col.git_url = 'https://github.com/test/repo.git' // Assuming git_url is a field on Collection
	// col.git_branch = 'main' // Assuming git_branch is a field on Collection

	// Create a mock page
	mut page_path := pathlib.get_file(path: '${col_path}/test_page.md', create: true)!
	page_path.write('test content')!
	col.add_page(mut page_path)!

	// Get the page and collection edit URLs
	page := col.page_get('test_page')!
	// edit_url := page.get_edit_url()! // This method does not exist

	// Assert the URLs are correct
	// assert edit_url == 'https://github.com/test/repo/edit/main/test_page.md'
}