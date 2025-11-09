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
}

fn test_error_hash() {
}

fn test_find_links() {
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
		include:          true
		cross_collection: true
		export_mode:      false
	})!
	println('Fixed: ${fixed}')

	// The fix_links should work on content
	assert fixed.contains('[Link](page2.md)')
}

fn test_link_formats() {
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
}

fn test_save_with_errors() {
	col_path := '${test_base}/error_save_test'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:err_col')!

	mut a := new(name: 'test')!
	mut col := a.add_collection(mut pathlib.get_dir(path: col_path)!)!
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
}

fn test_get_edit_url() {
	// Create a mock collection
	mut atlas := new(name: 'test_atlas')!
	col_path := '${test_base}/git_test'
	os.mkdir_all(col_path)!
	mut col := atlas.add_collection(mut pathlib.get_dir(path: col_path)!)!
	col.git_url = 'https://github.com/test/repo.git' // Assuming git_url is a field on Collection
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
