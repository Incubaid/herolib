#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.hero.herofs
import os

// Example demonstrating HeroFS import/export functionality
// This shows how to import files from real filesystem to VFS and export them back

fn main() {
	// Initialize the HeroFS factory
	mut fs_factory := herofs.new()!
	println('HeroFS factory initialized')

	// Create a new filesystem
	mut my_fs := fs_factory.fs.new(
		name:        'import_export_demo'
		description: 'Demonstration filesystem for import/export'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem
	my_fs = fs_factory.fs.set(my_fs)!
	println('Created filesystem: ${my_fs.name} with ID: ${my_fs.id}')

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     my_fs.id
		parent_id: 0 // Root has no parent
	)!
	root_dir = fs_factory.fs_dir.set(root_dir)!
	my_fs.root_dir_id = root_dir.id
	my_fs = fs_factory.fs.set(my_fs)!

	// Get filesystem instance for operations
	mut fs := fs_factory.fs.get(my_fs.id)!
	fs.factory = &fs_factory

	// Create temporary test directory and files on real filesystem
	test_dir := '/tmp/herofs_import_test_${my_fs.id}'
	os.mkdir_all(test_dir)!
	defer {
		os.rmdir_all(test_dir) or {}
	}

	// Create test files
	test_file1 := os.join_path(test_dir, 'hello.txt')
	test_file2 := os.join_path(test_dir, 'example.v')
	test_file3 := os.join_path(test_dir, 'README.md')

	// Create subdirectory with files
	sub_dir := os.join_path(test_dir, 'docs')
	os.mkdir_all(sub_dir)!
	test_file4 := os.join_path(sub_dir, 'guide.md')

	// Write test content
	os.write_file(test_file1, 'Hello, HeroFS Import/Export!')!
	os.write_file(test_file2, 'fn main() {\n    println("Imported V code!")\n}')!
	os.write_file(test_file3, '# HeroFS Demo\n\nThis file was imported from real filesystem.')!
	os.write_file(test_file4, '# User Guide\n\nThis is a guide in a subdirectory.')!

	println('\n=== IMPORT OPERATIONS ===')

	// Import single file
	println('Importing single file: ${test_file1}')
	fs.import(test_file1, '/imported_hello.txt', herofs.ImportOptions{
		overwrite:     true
		preserve_meta: true
	})!

	// Import entire directory recursively
	println('Importing directory: ${test_dir}')
	fs.import(test_dir, '/imported_files', herofs.ImportOptions{
		recursive:     true
		overwrite:     true
		preserve_meta: true
	})!

	// Verify imports
	println('\nVerifying imported files...')
	imported_results := fs.find('/', recursive: true)!
	for result in imported_results {
		type_str := match result.result_type {
			.file { 'FILE' }
			.directory { 'DIR ' }
			.symlink { 'LINK' }
		}
		println('${type_str}: ${result.path}')
	}

	// Find specific file types
	v_files := fs.find('/', recursive: true, include_patterns: ['*.v'])!
	println('\nFound ${v_files.len} V files:')
	for file in v_files {
		println('  - ${file.path}')
	}

	md_files := fs.find('/', recursive: true, include_patterns: ['*.md'])!
	println('\nFound ${md_files.len} Markdown files:')
	for file in md_files {
		println('  - ${file.path}')
	}

	println('\n=== EXPORT OPERATIONS ===')

	// Create export directory
	export_dir := '/tmp/herofs_export_test_${my_fs.id}'
	os.mkdir_all(export_dir)!
	defer {
		os.rmdir_all(export_dir) or {}
	}

	// Export single file
	println('Exporting single file to: ${export_dir}/exported_hello.txt')
	fs.export('/imported_hello.txt', os.join_path(export_dir, 'exported_hello.txt'), herofs.ExportOptions{
		overwrite:     true
		preserve_meta: true
	})!

	// Export entire directory
	println('Exporting directory to: ${export_dir}/exported_files')
	fs.export('/imported_files', os.join_path(export_dir, 'exported_files'), herofs.ExportOptions{
		recursive:     true
		overwrite:     true
		preserve_meta: true
	})!

	// Verify exports
	println('\nVerifying exported files...')
	if os.exists(os.join_path(export_dir, 'exported_hello.txt')) {
		content := os.read_file(os.join_path(export_dir, 'exported_hello.txt'))!
		println('✓ exported_hello.txt: "${content}"')
	}

	if os.exists(os.join_path(export_dir, 'exported_files', 'hello.txt')) {
		content := os.read_file(os.join_path(export_dir, 'exported_files', 'hello.txt'))!
		println('✓ exported_files/hello.txt: "${content}"')
	}

	if os.exists(os.join_path(export_dir, 'exported_files', 'example.v')) {
		content := os.read_file(os.join_path(export_dir, 'exported_files', 'example.v'))!
		println('✓ exported_files/example.v contains: ${content.split('\n')[0]}')
	}

	if os.exists(os.join_path(export_dir, 'exported_files', 'docs', 'guide.md')) {
		content := os.read_file(os.join_path(export_dir, 'exported_files', 'docs', 'guide.md'))!
		println('✓ exported_files/docs/guide.md: "${content.split('\n')[0]}"')
	}

	println('\n=== MIME TYPE DETECTION ===')

	// Test MIME type detection
	test_extensions := ['.txt', '.v', '.md', '.html', '.json', '.png', '.unknown']
	for ext in test_extensions {
		mime_type := herofs.extension_to_mime_type(ext)
		println('Extension ${ext} -> MIME type: ${mime_type}')
	}

	println('\n=== OVERWRITE BEHAVIOR TEST ===')

	// Test overwrite behavior
	test_overwrite_file := os.join_path(test_dir, 'overwrite_test.txt')
	os.write_file(test_overwrite_file, 'Original content')!

	// Import without overwrite
	fs.import(test_overwrite_file, '/overwrite_test.txt', herofs.ImportOptions{
		overwrite: false
	})!

	// Try to import again without overwrite (should fail silently or with error)
	println('Testing import without overwrite (should fail)...')
	fs.import(test_overwrite_file, '/overwrite_test.txt', herofs.ImportOptions{
		overwrite: false
	}) or { println('✓ Import correctly failed when overwrite=false: ${err}') }

	// Update file content and import with overwrite
	os.write_file(test_overwrite_file, 'Updated content')!
	fs.import(test_overwrite_file, '/overwrite_test.txt', herofs.ImportOptions{
		overwrite: true
	})!
	println('✓ Import with overwrite=true succeeded')

	// Test export overwrite behavior
	export_test_file := os.join_path(export_dir, 'overwrite_export_test.txt')

	// Export first time
	fs.export('/overwrite_test.txt', export_test_file, herofs.ExportOptions{
		overwrite: false
	})!

	// Try to export again without overwrite (should fail)
	println('Testing export without overwrite (should fail)...')
	fs.export('/overwrite_test.txt', export_test_file, herofs.ExportOptions{
		overwrite: false
	}) or { println('✓ Export correctly failed when overwrite=false: ${err}') }

	// Export with overwrite
	fs.export('/overwrite_test.txt', export_test_file, herofs.ExportOptions{
		overwrite: true
	})!
	println('✓ Export with overwrite=true succeeded')

	// Verify final content
	final_content := os.read_file(export_test_file)!
	println('Final exported content: "${final_content}"')

	println('\n✅ Import/Export demonstration completed successfully!')
	println('All files have been imported to VFS and exported back to real filesystem.')
	println('Temporary directories will be cleaned up automatically.')
}
