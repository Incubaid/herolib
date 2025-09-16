module herofs

import os

fn test_import_export_file() ! {
	// Initialize HeroFS factory
	mut fs_factory := new()!

	// Create a test filesystem
	mut test_fs := fs_factory.fs.new(
		name:        'import_export_test'
		description: 'Test filesystem for import/export'
		quota_bytes: 1024 * 1024 * 10 // 10MB quota
	)!
	test_fs = fs_factory.fs.set(test_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     test_fs.id
		parent_id: 0
	)!
	root_dir = fs_factory.fs_dir.set(root_dir)!
	test_fs.root_dir_id = root_dir.id
	test_fs = fs_factory.fs.set(test_fs)!

	// Get filesystem instance for operations
	mut fs := fs_factory.fs.get(test_fs.id)!
	fs.factory = &fs_factory

	// Create temporary test files on real filesystem
	test_dir := '/tmp/herofs_test_${test_fs.id}'
	os.mkdir_all(test_dir)!
	defer {
		os.rmdir_all(test_dir) or {}
	}

	// Create test files
	test_file1 := os.join_path(test_dir, 'test1.txt')
	test_file2 := os.join_path(test_dir, 'test2.v')
	test_subdir := os.join_path(test_dir, 'subdir')
	test_file3 := os.join_path(test_subdir, 'test3.md')

	os.write_file(test_file1, 'Hello, World!')!
	os.write_file(test_file2, 'fn main() {\n    println("Hello from V!")\n}')!
	os.mkdir_all(test_subdir)!
	os.write_file(test_file3, '# Test Markdown\n\nThis is a test.')!

	// Test single file import
	println('Testing single file import...')
	fs.import(test_file1, '/imported_test1.txt', ImportOptions{ overwrite: true })!

	// Verify file was imported
	imported_results := fs.find('/imported_test1.txt', FindOptions{ recursive: false })!
	assert imported_results.len == 1
	assert imported_results[0].result_type == .file

	// Test directory import
	println('Testing directory import...')
	fs.import(test_dir, '/imported_dir', ImportOptions{ recursive: true, overwrite: true })!

	// Verify directory structure was imported
	dir_results := fs.find('/imported_dir', FindOptions{ recursive: true })!
	assert dir_results.len >= 4 // Directory + 3 files

	// Find specific files
	v_files := fs.find('/imported_dir', FindOptions{
		recursive:        true
		include_patterns: [
			'*.v',
		]
	})!
	assert v_files.len == 1

	md_files := fs.find('/imported_dir', FindOptions{
		recursive:        true
		include_patterns: [
			'*.md',
		]
	})!
	assert md_files.len == 1

	// Test export functionality
	println('Testing export functionality...')
	export_dir := '/tmp/herofs_export_${test_fs.id}'
	defer {
		os.rmdir_all(export_dir) or {}
	}

	// Export single file
	fs.export('/imported_test1.txt', os.join_path(export_dir, 'exported_test1.txt'), ExportOptions{
		overwrite: true
	})!

	// Verify exported file
	assert os.exists(os.join_path(export_dir, 'exported_test1.txt'))
	exported_content := os.read_file(os.join_path(export_dir, 'exported_test1.txt'))!
	assert exported_content == 'Hello, World!'

	// Export directory
	fs.export('/imported_dir', os.join_path(export_dir, 'exported_dir'), ExportOptions{
		recursive: true
		overwrite: true
	})!

	// Verify exported directory structure
	assert os.exists(os.join_path(export_dir, 'exported_dir'))
	assert os.exists(os.join_path(export_dir, 'exported_dir', 'test1.txt'))
	assert os.exists(os.join_path(export_dir, 'exported_dir', 'test2.v'))
	assert os.exists(os.join_path(export_dir, 'exported_dir', 'subdir', 'test3.md'))

	// Verify file contents
	exported_v_content := os.read_file(os.join_path(export_dir, 'exported_dir', 'test2.v'))!
	assert exported_v_content.contains('fn main()')

	exported_md_content := os.read_file(os.join_path(export_dir, 'exported_dir', 'subdir',
		'test3.md'))!
	assert exported_md_content.contains('# Test Markdown')

	println('✓ Import/Export tests passed!')
}

fn test_import_export_overwrite() ! {
	// Initialize HeroFS factory
	mut fs_factory := new()!

	// Create a test filesystem
	mut test_fs := fs_factory.fs.new(
		name:        'overwrite_test'
		description: 'Test filesystem for overwrite behavior'
		quota_bytes: 1024 * 1024 * 5 // 5MB quota
	)!
	test_fs = fs_factory.fs.set(test_fs)!

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:      'root'
		fs_id:     test_fs.id
		parent_id: 0
	)!
	root_dir = fs_factory.fs_dir.set(root_dir)!
	test_fs.root_dir_id = root_dir.id
	test_fs = fs_factory.fs.set(test_fs)!

	// Get filesystem instance
	mut fs := fs_factory.fs.get(test_fs.id)!
	fs.factory = &fs_factory

	// Create temporary test file
	test_dir := '/tmp/herofs_overwrite_test_${test_fs.id}'
	os.mkdir_all(test_dir)!
	defer {
		os.rmdir_all(test_dir) or {}
	}

	test_file := os.join_path(test_dir, 'overwrite_test.txt')
	os.write_file(test_file, 'Original content')!

	// Import file first time
	fs.import(test_file, '/test_overwrite.txt', ImportOptions{ overwrite: false })!

	// Try to import again without overwrite (should fail)
	fs.import(test_file, '/test_overwrite.txt', ImportOptions{ overwrite: false }) or {
		println('✓ Import correctly failed when overwrite=false')
		// This is expected
	}

	// Import again with overwrite (should succeed)
	os.write_file(test_file, 'Updated content')!
	fs.import(test_file, '/test_overwrite.txt', ImportOptions{ overwrite: true })!

	// Test export overwrite behavior
	export_dir := '/tmp/herofs_export_overwrite_${test_fs.id}'
	os.mkdir_all(export_dir)!
	defer {
		os.rmdir_all(export_dir) or {}
	}

	export_file := os.join_path(export_dir, 'test_export.txt')

	// Export first time
	fs.export('/test_overwrite.txt', export_file, ExportOptions{ overwrite: false })!

	// Try to export again without overwrite (should fail)
	fs.export('/test_overwrite.txt', export_file, ExportOptions{ overwrite: false }) or {
		println('✓ Export correctly failed when overwrite=false')
		// This is expected
	}

	// Export again with overwrite (should succeed)
	fs.export('/test_overwrite.txt', export_file, ExportOptions{ overwrite: true })!

	// Verify final content
	final_content := os.read_file(export_file)!
	assert final_content == 'Updated content'

	println('✓ Overwrite behavior tests passed!')
}

fn test_mime_type_detection() ! {
	// Test the extension_to_mime_type function
	assert extension_to_mime_type('.txt') == .txt
	assert extension_to_mime_type('.v') == .txt
	assert extension_to_mime_type('.md') == .md
	assert extension_to_mime_type('.html') == .html
	assert extension_to_mime_type('.json') == .json
	assert extension_to_mime_type('.png') == .png
	assert extension_to_mime_type('.jpg') == .jpg
	assert extension_to_mime_type('.unknown') == .bin

	// Test without leading dot
	assert extension_to_mime_type('txt') == .txt
	assert extension_to_mime_type('PDF') == .pdf // Test case insensitive

	println('✓ MIME type detection tests passed!')
}
