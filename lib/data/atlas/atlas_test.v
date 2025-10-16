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
    a.add_collection(name: 'col1', path: col_path)!
    
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
    a.add_collection(name: 'col1', path: col_path)!
    
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
    a.add_collection(name: 'test_col', path: col_path)!
    
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
    a.add_collection(name: 'test_col2', path: col_path)!
    
    export_path := '${test_base}/export_no_include'
    a.export(destination: export_path, include: false)!
    
    // Verify exported page1 still has include action
    exported := os.read_file('${export_path}/test_col2/page1.md')!
    assert exported.contains('!!include')
}

fn test_error_deduplication() {
	mut a := new(name: 'test')!
	mut col := a.new_collection(name: 'test', path: test_base)!
	
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
	
	assert col.errors.len == 1
	
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