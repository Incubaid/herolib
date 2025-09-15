#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.herofs
import freeflowuniverse.herolib.hero.db

fn main() {
	println('Testing FsDir functionality...')
	
	// Initialize the HeroFS factory
	mut fs_factory := herofs.new()!
	println('HeroFS factory initialized')
	
	// Create a new filesystem (required for FsDir)
	mut my_fs := fs_factory.fs.new(
		name:        'test_filesystem'
		description: 'Filesystem for testing FsDir functionality'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!
	
	// Save the filesystem to get an ID
	fs_id := fs_factory.fs.set(my_fs)!
	println('Created test filesystem with ID: ${fs_id}')
	
	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:        'root'
		fs_id:       fs_id
		parent_id:   0 // Root has no parent
		description: 'Root directory for testing'
	)!
	
	// Save the root directory
	root_dir_id := fs_factory.fs_dir.set(root_dir)!
	println('Created root directory with ID: ${root_dir_id}')
	
	// Update the filesystem with the root directory ID
	my_fs.root_dir_id = root_dir_id
	fs_factory.fs.set(my_fs)!
	
	// Create test directories with various parameters
	mut test_dir1 := fs_factory.fs_dir.new(
		name:        'test_dir1'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'First test directory'
	)!
	
	mut test_dir2 := fs_factory.fs_dir.new(
		name:        'test_dir2'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Second test directory with tags'
		tags:        ['test', 'directory', 'example']
	)!
	
	mut test_dir3 := fs_factory.fs_dir.new(
		name:        'test_dir3'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Third test directory with comments'
		comments:    [db.CommentArg{
			text: 'This is a test comment'
			author: 'test_user'
		}]
	)!
	
	// Save the test directories
	dir1_id := fs_factory.fs_dir.set(test_dir1)!
	dir2_id := fs_factory.fs_dir.set(test_dir2)!
	dir3_id := fs_factory.fs_dir.set(test_dir3)!
	
	println('Created test directories:')
	println('- ${test_dir1.name} with ID: ${dir1_id}')
	println('- ${test_dir2.name} with ID: ${dir2_id}')
	println('- ${test_dir3.name} with ID: ${dir3_id}')
	
	// Test loading directories by ID
	println('\nTesting directory loading...')
	
	loaded_root_dir := fs_factory.fs_dir.get(root_dir_id)!
	println('Loaded root directory: ${loaded_root_dir.name} (ID: ${loaded_root_dir.id})')
	
	loaded_dir1 := fs_factory.fs_dir.get(dir1_id)!
	println('Loaded test_dir1: ${loaded_dir1.name} (ID: ${loaded_dir1.id})')
	println('  Description: ${loaded_dir1.description}')
	
	loaded_dir2 := fs_factory.fs_dir.get(dir2_id)!
	println('Loaded test_dir2: ${loaded_dir2.name} (ID: ${loaded_dir2.id})')
	println('  Description: ${loaded_dir2.description}')
	println('  Tags: ${loaded_dir2.tags}')
	
	loaded_dir3 := fs_factory.fs_dir.get(dir3_id)!
	println('Loaded test_dir3: ${loaded_dir3.name} (ID: ${loaded_dir3.id})')
	println('  Description: ${loaded_dir3.description}')
	
	// Verify that loaded directories match the original ones
	println('\nVerifying data integrity...')
	
	if loaded_root_dir.name == root_dir.name && loaded_root_dir.description == root_dir.description {
		println('✓ Root directory data integrity verified')
	} else {
		println('✗ Root directory data integrity check failed')
	}
	
	if loaded_dir1.name == test_dir1.name && loaded_dir1.description == test_dir1.description {
		println('✓ Test directory 1 data integrity verified')
	} else {
		println('✗ Test directory 1 data integrity check failed')
	}
	
	if loaded_dir2.name == test_dir2.name && loaded_dir2.description == test_dir2.description && loaded_dir2.tags == test_dir2.tags {
		println('✓ Test directory 2 data integrity verified')
	} else {
		println('✗ Test directory 2 data integrity check failed')
	}
	
	if loaded_dir3.name == test_dir3.name && loaded_dir3.description == test_dir3.description {
		println('✓ Test directory 3 data integrity verified')
	} else {
		println('✗ Test directory 3 data integrity check failed')
	}
	
	// Test exist method
	println('\nTesting directory existence checks...')
	
	exists := fs_factory.fs_dir.exist(root_dir_id)!
	println('Root directory exists: ${exists}')
	
	exists = fs_factory.fs_dir.exist(dir1_id)!
	println('Test directory 1 exists: ${exists}')
	
	exists = fs_factory.fs_dir.exist(dir2_id)!
	println('Test directory 2 exists: ${exists}')
	
	exists = fs_factory.fs_dir.exist(dir3_id)!
	println('Test directory 3 exists: ${exists}')
	
	// Test with non-existent ID
	exists = fs_factory.fs_dir.exist(999999)!
	println('Non-existent directory exists: ${exists}')
	
	println('\nFsDir test completed successfully!')
}