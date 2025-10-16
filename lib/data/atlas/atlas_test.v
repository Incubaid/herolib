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