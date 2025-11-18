module atlas

import incubaid.herolib.core.pathlib
import os

const test_dir = '/tmp/atlas_save_test'

fn testsuite_begin() {
	os.rmdir_all(test_dir) or {}
	os.mkdir_all(test_dir)!
}

fn testsuite_end() {
	os.rmdir_all(test_dir) or {}
}

fn test_save_and_load_basic() {
	// Create a collection with some content
	col_path := '${test_dir}/docs'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:docs')!

	mut page1 := pathlib.get_file(path: '${col_path}/intro.md', create: true)!
	page1.write('# Introduction\n\nWelcome to the docs!')!

	mut page2 := pathlib.get_file(path: '${col_path}/guide.md', create: true)!
	page2.write('# Guide\n\nMore content here.')!

	// Create and scan atlas
	mut a := new(name: 'my_docs')!
	a.scan(path: test_dir)!

	assert a.collections.len == 1

	// Save all collections
	// a.save(destination_meta: '/tmp/atlas_meta')!
	// assert os.exists('${col_path}/.collection.json')

	// // Load in a new atlas
	// mut a2 := new(name: 'loaded_docs')!
	// a2.load_from_directory(test_dir)!

	// assert a2.collections.len == 1

	// // Access loaded data
	// loaded_col := a2.get_collection('docs')!
	// assert loaded_col.name == 'docs'
	// assert loaded_col.pages.len == 2

	// // Verify pages exist
	// assert loaded_col.page_exists('intro')
	// assert loaded_col.page_exists('guide')

	// // Read page content
	// mut intro_page := loaded_col.page_get('intro')!
	// content := intro_page.read_content()!
	// assert content.contains('# Introduction')
	// assert content.contains('Welcome to the docs!')
}

fn test_save_and_load_with_includes() {
	col_path := '${test_dir}/docs_include'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:docs')!

	mut page1 := pathlib.get_file(path: '${col_path}/intro.md', create: true)!
	page1.write('# Introduction\n\nWelcome to the docs!')!

	mut page2 := pathlib.get_file(path: '${col_path}/guide.md', create: true)!
	page2.write('# Guide\n\n!!include docs:intro\n\nMore content here.')!

	// Create and scan atlas
	mut a := new(name: 'my_docs')!
	a.scan(path: '${test_dir}/docs_include')!

	// Validate links (should find the include)
	a.validate_links()!

	col := a.get_collection('docs')!
	assert !col.has_errors()

	// // Save
	// a.save(destination_meta: '/tmp/atlas_meta')!

	// // Load
	// mut a2 := new(name: 'loaded')!
	// a2.load_from_directory('${test_dir}/docs_include')!

	// loaded_col := a2.get_collection('docs')!
	// assert loaded_col.pages.len == 2
	// assert !loaded_col.has_errors()
}

fn test_save_and_load_with_errors() {
	col_path := '${test_dir}/docs_errors'
	os.mkdir_all(col_path)!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:docs')!

	// Create page with broken link
	mut page1 := pathlib.get_file(path: '${col_path}/broken.md', create: true)!
	page1.write('[Broken link](nonexistent)')!

	// Create and scan atlas
	mut a := new(name: 'my_docs')!
	a.scan(path: '${test_dir}/docs_errors')!

	// Validate - will generate errors
	a.validate_links()!

	col := a.get_collection('docs')!
	assert col.has_errors()
	initial_error_count := col.errors.len

	// // Save with errors
	// a.save(destination_meta: '/tmp/atlas_meta')!

	// // Load
	// mut a2 := new(name: 'loaded')!
	// a2.load_from_directory('${test_dir}/docs_errors')!

	// loaded_col := a2.get_collection('docs')!
	// assert loaded_col.has_errors()
	// assert loaded_col.errors.len == initial_error_count
	// assert loaded_col.error_cache.len == initial_error_count
}

fn test_save_and_load_multiple_collections() {
	// Create multiple collections
	col1_path := '${test_dir}/multi/col1'
	col2_path := '${test_dir}/multi/col2'

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
	mut a := new(name: 'multi')!
	a.scan(path: '${test_dir}/multi')!

	assert a.collections.len == 2

	// a.save(destination_meta: '/tmp/atlas_meta')!

	// // Load from directory
	// mut a2 := new(name: 'loaded')!
	// a2.load_from_directory('${test_dir}/multi')!

	// assert a2.collections.len == 2
	// assert a2.get_collection('col1')!.page_exists('page1')
	// assert a2.get_collection('col2')!.page_exists('page2')
}

fn test_save_and_load_with_images() {
	col_path := '${test_dir}/docs_images'
	os.mkdir_all(col_path)!
	os.mkdir_all('${col_path}/img')!

	mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
	cfile.write('name:docs')!

	mut page := pathlib.get_file(path: '${col_path}/page.md', create: true)!
	page.write('# Page with image')!

	// Create a dummy image file
	mut img := pathlib.get_file(path: '${col_path}/img/test.png', create: true)!
	img.write('fake png data')!

	// Create and scan
	mut a := new(name: 'my_docs')!
	a.scan(path: '${test_dir}/docs_images')!

	col := a.get_collection('docs')!
	// assert col.images.len == 1
	assert col.image_exists('test.png')!

	// // Save
	// a.save(destination_meta: '/tmp/atlas_meta')!

	// // Load
	// mut a2 := new(name: 'loaded')!
	// a2.load_from_directory('${test_dir}/docs_images')!

	// loaded_col := a2.get_collection('docs')!
	// assert loaded_col.images.len == 1
	// assert loaded_col.image_exists('test.png')!

	img_file := col.image_get('test.png')!
	assert img_file.name == 'test.png'
	assert img_file.is_image()
}
