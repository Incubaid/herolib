#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.hero.herofs

// Example demonstrating the new FsTools high-level filesystem operations
// This shows how to use find, cp, rm, and mv operations

fn main() {
	// Initialize the HeroFS factory
	mut fs_factory := herofs.new()!
	println('HeroFS factory initialized')

	// Create a new filesystem
	mut my_fs := fs_factory.fs.new(
		name:        'tools_demo'
		description: 'Demonstration filesystem for fs_tools'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem to get an ID
	fs_id := fs_factory.fs.set(my_fs)!
	println('Created filesystem: ${my_fs.name} with ID: ${fs_id}')

	// Get the tools interface
	mut tools := fs_factory.tools()

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:        'root'
		fs_id:       fs_id
		parent_id:   0
		description: 'Root directory'
	)!
	root_dir_id := fs_factory.fs_dir.set(root_dir)!
	
	// Update the filesystem with the root directory ID
	my_fs.root_dir_id = root_dir_id
	fs_factory.fs.set(my_fs)!

	// Create some sample directory structure
	println('\nCreating sample directory structure...')
	
	// Create directories using the high-level tools (which will use create_path)
	src_dir_id := fs_factory.fs_dir.create_path(fs_id, '/src')!
	docs_dir_id := fs_factory.fs_dir.create_path(fs_id, '/docs')!
	test_dir_id := fs_factory.fs_dir.create_path(fs_id, '/tests')!
	examples_dir_id := fs_factory.fs_dir.create_path(fs_id, '/examples')!

	// Create some sample files
	println('Creating sample files...')

	// Create blobs for file content
	v_code := 'fn main() {\n    println("Hello from V!")\n}\n'.bytes()
	v_blob := fs_factory.fs_blob.new(
		data:      v_code
		mime_type: 'text/plain'
		name:      'main.v content'
	)!
	v_blob_id := fs_factory.fs_blob.set(v_blob)!

	readme_content := '# My Project\n\nThis is a sample project.\n\n## Features\n\n- Feature 1\n- Feature 2\n'.bytes()
	readme_blob := fs_factory.fs_blob.new(
		data:      readme_content
		mime_type: 'text/markdown'
		name:      'README.md content'
	)!
	readme_blob_id := fs_factory.fs_blob.set(readme_blob)!

	test_content := 'fn test_main() {\n    assert 1 == 1\n}\n'.bytes()
	test_blob := fs_factory.fs_blob.new(
		data:      test_content
		mime_type: 'text/plain'
		name:      'test content'
	)!
	test_blob_id := fs_factory.fs_blob.set(test_blob)!

	// Create files
	main_file := fs_factory.fs_file.new(
		name:        'main.v'
		fs_id:       fs_id
		directories: [src_dir_id]
		blobs:       [v_blob_id]
		mime_type:   'text/plain'
	)!
	fs_factory.fs_file.set(main_file)!

	readme_file := fs_factory.fs_file.new(
		name:        'README.md'
		fs_id:       fs_id
		directories: [root_dir_id]
		blobs:       [readme_blob_id]
		mime_type:   'text/markdown'
	)!
	fs_factory.fs_file.set(readme_file)!

	test_file := fs_factory.fs_file.new(
		name:        'main_test.v'
		fs_id:       fs_id
		directories: [test_dir_id]
		blobs:       [test_blob_id]
		mime_type:   'text/plain'
	)!
	fs_factory.fs_file.set(test_file)!

	// Create a symbolic link
	main_symlink := fs_factory.fs_symlink.new(
		name:        'main_link.v'
		fs_id:       fs_id
		parent_id:   examples_dir_id
		target_id:   main_file.id
		target_type: .file
		description: 'Link to main.v'
	)!
	fs_factory.fs_symlink.set(main_symlink)!

	println('Sample filesystem structure created!')

	// Demonstrate FIND functionality
	println('\n=== FIND OPERATIONS ===')

	// Find all files
	println('\nFinding all files...')
	all_results := tools.find(fs_id, '/', recursive: true)!
	for result in all_results {
		type_str := match result.result_type {
			.file { 'FILE' }
			.directory { 'DIR ' }
			.symlink { 'LINK' }
		}
		println('${type_str}: ${result.path} (ID: ${result.id})')
	}

	// Find only V files
	println('\nFinding only .v files...')
	v_files := tools.find(fs_id, '/', recursive: true, include_patterns: ['*.v'])!
	for result in v_files {
		println('V FILE: ${result.path}')
	}

	// Find with exclude patterns
	println('\nFinding all except test files...')
	non_test_results := tools.find(fs_id, '/', recursive: true, exclude_patterns: ['*test*'])!
	for result in non_test_results {
		type_str := match result.result_type {
			.file { 'FILE' }
			.directory { 'DIR ' }
			.symlink { 'LINK' }
		}
		println('${type_str}: ${result.path}')
	}

	// Demonstrate COPY functionality
	println('\n=== COPY OPERATIONS ===')

	// Copy a file
	println('\nCopying main.v to docs directory...')
	tools.cp(fs_id, '/src/main.v', '/docs/main_copy.v', recursive: true)!
	println('File copied successfully')

	// Copy a directory
	println('\nCopying src directory to backup...')
	tools.cp(fs_id, '/src', '/src_backup', recursive: true)!
	println('Directory copied successfully')

	// Verify the copies
	println('\nVerifying copies...')
	copy_results := tools.find(fs_id, '/', recursive: true, include_patterns: ['*copy*', '*backup*'])!
	for result in copy_results {
		println('COPIED: ${result.path}')
	}

	// Demonstrate MOVE functionality
	println('\n=== MOVE OPERATIONS ===')

	// Move a file
	println('\nMoving main_copy.v to examples directory...')
	tools.mv(fs_id, '/docs/main_copy.v', '/examples/main_example.v', overwrite: false)!
	println('File moved successfully')

	// Move a directory
	println('\nMoving src_backup to archive...')
	tools.mv(fs_id, '/src_backup', '/archive', overwrite: false)!
	println('Directory moved successfully')

	// Verify the moves
	println('\nVerifying moves...')
	move_results := tools.find(fs_id, '/', recursive: true)!
	for result in move_results {
		if result.path.contains('example') || result.path.contains('archive') {
			type_str := match result.result_type {
				.file { 'FILE' }
				.directory { 'DIR ' }
				.symlink { 'LINK' }
			}
			println('MOVED: ${type_str}: ${result.path}')
		}
	}

	// Demonstrate REMOVE functionality
	println('\n=== REMOVE OPERATIONS ===')

	// Remove a single file
	println('\nRemoving test file...')
	tools.rm(fs_id, '/tests/main_test.v', recursive: false, delete_blobs: false)!
	println('Test file removed')

	// Create a temporary directory with content for removal demo
	temp_dir_id := fs_factory.fs_dir.create_path(fs_id, '/temp')!
	temp_file := fs_factory.fs_file.new(
		name:        'temp.txt'
		fs_id:       fs_id
		directories: [temp_dir_id]
		blobs:       [readme_blob_id] // Reuse existing blob
		mime_type:   'text/plain'
	)!
	fs_factory.fs_file.set(temp_file)!

	// Remove directory with contents
	println('\nRemoving temp directory and its contents...')
	tools.rm(fs_id, '/temp', recursive: true, delete_blobs: false)!
	println('Temp directory and contents removed')

	// Show final filesystem state
	println('\n=== FINAL FILESYSTEM STATE ===')
	final_results := tools.find(fs_id, '/', recursive: true)!
	for result in final_results {
		type_str := match result.result_type {
			.file { 'FILE' }
			.directory { 'DIR ' }
			.symlink { 'LINK' }
		}
		println('${type_str}: ${result.path} (ID: ${result.id})')
	}

	println('\nfs_tools demonstration completed successfully!')
}