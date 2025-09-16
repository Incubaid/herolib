#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

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

	// Save the filesystem
	fs_factory.fs.set(mut my_fs)!
	println('Created filesystem: ${my_fs.name} with ID: ${my_fs.id}')

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:        'root'
		fs_id:       my_fs.id
		parent_id:   0
		description: 'Root directory'
	)!
	fs_factory.fs_dir.set(mut root_dir)!

	// Update the filesystem with the root directory ID
	my_fs.root_dir_id = root_dir.id
	fs_factory.fs.set(mut my_fs)!

	// Create some sample directory structure
	println('\nCreating sample directory structure...')

	// Create directories using the high-level tools (which will use create_path)
	src_dir_id := fs_factory.fs_dir.create_path(my_fs.id, '/src')!
	_ := fs_factory.fs_dir.create_path(my_fs.id, '/docs')!
	test_dir_id := fs_factory.fs_dir.create_path(my_fs.id, '/tests')!
	examples_dir_id := fs_factory.fs_dir.create_path(my_fs.id, '/examples')!

	// Create some sample files
	println('Creating sample files...')

	// Create blobs for file content
	v_code := 'fn main() {\n    println("Hello from V!")\n}\n'.bytes()
	mut v_blob := fs_factory.fs_blob.new(data: v_code)!
	fs_factory.fs_blob.set(mut v_blob)!

	readme_content := '# My Project\n\nThis is a sample project.\n\n## Features\n\n- Feature 1\n- Feature 2\n'.bytes()
	mut readme_blob := fs_factory.fs_blob.new(data: readme_content)!
	fs_factory.fs_blob.set(mut readme_blob)!

	test_content := 'fn test_main() {\n    assert 1 == 1\n}\n'.bytes()
	mut test_blob := fs_factory.fs_blob.new(data: test_content)!
	fs_factory.fs_blob.set(mut test_blob)!

	// Create files
	mut main_file := fs_factory.fs_file.new(
		name:      'main.v'
		fs_id:     my_fs.id
		blobs:     [v_blob.id]
		mime_type: .txt
	)!
	fs_factory.fs_file.set(mut main_file)!
	fs_factory.fs_file.add_to_directory(main_file.id, src_dir_id)!

	mut readme_file := fs_factory.fs_file.new(
		name:      'README.md'
		fs_id:     my_fs.id
		blobs:     [readme_blob.id]
		mime_type: .md
	)!
	fs_factory.fs_file.set(mut readme_file)!
	fs_factory.fs_file.add_to_directory(readme_file.id, root_dir.id)!

	mut test_file := fs_factory.fs_file.new(
		name:      'main_test.v'
		fs_id:     my_fs.id
		blobs:     [test_blob.id]
		mime_type: .txt
	)!
	fs_factory.fs_file.set(mut test_file)!
	fs_factory.fs_file.add_to_directory(test_file.id, test_dir_id)!

	// Create a symbolic link
	mut main_symlink := fs_factory.fs_symlink.new(
		name:        'main_link.v'
		fs_id:       my_fs.id
		parent_id:   examples_dir_id
		target_id:   main_file.id
		target_type: .file
		description: 'Link to main.v'
	)!
	fs_factory.fs_symlink.set(mut main_symlink)!

	println('Sample filesystem structure created!')

	// Get the filesystem instance for tools operations
	mut fs := fs_factory.fs.get(my_fs.id)!

	// Demonstrate FIND functionality
	println('\n=== FIND OPERATIONS ===')

	// Find all files
	println('\nFinding all files...')
	all_results := fs.find('/', recursive: true)!
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
	v_files := fs.find('/', recursive: true, include_patterns: ['*.v'])!
	for result in v_files {
		println('V FILE: ${result.path}')
	}

	// Find with exclude patterns
	println('\nFinding all except test files...')
	non_test_results := fs.find('/',
		recursive:        true
		exclude_patterns: [
			'*test*',
		]
	)!
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

	// Copy a single file
	println('Copying /src/main.v to /docs/')
	fs.cp('/src/main.v', '/docs/', herofs.FindOptions{ recursive: false }, herofs.CopyOptions{
		overwrite:  true
		copy_blobs: true
	})!

	// Copy all V files to examples directory
	println('Copying all .v files to /examples/')
	fs.cp('/', '/examples/', herofs.FindOptions{
		recursive:        true
		include_patterns: [
			'*.v',
		]
	}, herofs.CopyOptions{
		overwrite:  true
		copy_blobs: false
	})! // Reference same blobs

	// Demonstrate MOVE functionality
	println('\n=== MOVE OPERATIONS ===')

	// Move the copied file to a new location with rename
	println('Moving /docs/main.v to /examples/main_backup.v')
	fs.mv('/docs/main.v', '/examples/main_backup.v', herofs.MoveOptions{ overwrite: true })!

	// Move README to root
	println('Moving /README.md to /project_readme.md')
	fs.mv('/README.md', '/project_readme.md', herofs.MoveOptions{ overwrite: false })!

	// Demonstrate REMOVE functionality
	println('\n=== REMOVE OPERATIONS ===')

	// Remove a specific file
	println('Removing /tests/main_test.v')
	fs.rm('/tests/main_test.v', herofs.FindOptions{ recursive: false }, herofs.RemoveOptions{
		delete_blobs: false
	})!

	// Remove all files in docs directory (but keep the directory)
	println('Removing all files in /docs/ directory')
	fs.rm('/docs/', herofs.FindOptions{ recursive: false, include_patterns: ['*'] }, herofs.RemoveOptions{
		delete_blobs: false
	})!

	println('\nAll copy, move, and remove operations completed successfully!')

	// Show final filesystem state
	println('\n=== FINAL FILESYSTEM STATE ===')
	final_results := fs.find('/', recursive: true)!
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
