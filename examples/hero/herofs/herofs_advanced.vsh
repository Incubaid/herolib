#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import incubaid.herolib.hero.herofs

// Advanced example of using HeroFS - the Hero Filesystem
// Demonstrates more complex operations including:
// - File operations (move, rename, metadata)
// - Symlinks
// - Binary data handling
// - Directory hierarchies
// - Searching and filtering

fn main() {
	// Initialize the HeroFS factory
	mut fs_factory := herofs.new()!
	println('HeroFS factory initialized')

	// Create a new filesystem
	mut my_fs := fs_factory.fs.new(
		name:        'project_workspace'
		description: 'Project development workspace'
		quota_bytes: 5 * 1024 * 1024 * 1024 // 5GB quota
	)!

	// Save the filesystem
	my_fs = fs_factory.fs.set(my_fs)!
	println('Created filesystem: ${my_fs.name} with ID: ${my_fs.id}')

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:        'root'
		fs_id:       my_fs.id
		parent_id:   0 // Root has no parent
		description: 'Root directory'
	)!

	// Save the root directory
	root_dir = fs_factory.fs_dir.set(root_dir)!
	println('Created root directory with ID: ${root_dir.id}')

	// Update the filesystem with the root directory ID
	my_fs.root_dir_id = root_dir.id
	my_fs = fs_factory.fs.set(my_fs)!

	// Create a directory hierarchy
	println('\nCreating directory hierarchy...')

	// Main project directories
	mut src_dir := fs_factory.fs_dir.new(
		name:        'src'
		fs_id:       my_fs.id
		parent_id:   root_dir.id
		description: 'Source code'
	)!
	src_dir = fs_factory.fs_dir.set(src_dir)!

	mut docs_dir := fs_factory.fs_dir.new(
		name:        'docs'
		fs_id:       my_fs.id
		parent_id:   root_dir.id
		description: 'Documentation'
	)!
	docs_dir = fs_factory.fs_dir.set(docs_dir)!

	mut assets_dir := fs_factory.fs_dir.new(
		name:        'assets'
		fs_id:       my_fs.id
		parent_id:   root_dir.id
		description: 'Project assets'
	)!
	assets_dir = fs_factory.fs_dir.set(assets_dir)!

	// Subdirectories
	mut images_dir := fs_factory.fs_dir.new(
		name:        'images'
		fs_id:       my_fs.id
		parent_id:   assets_dir.id
		description: 'Image assets'
	)!
	images_dir = fs_factory.fs_dir.set(images_dir)!

	mut api_docs_dir := fs_factory.fs_dir.new(
		name:        'api'
		fs_id:       my_fs.id
		parent_id:   docs_dir.id
		description: 'API documentation'
	)!
	api_docs_dir = fs_factory.fs_dir.set(api_docs_dir)!

	// Add directories to their parents
	root_dir.directories << src_dir.id
	root_dir.directories << docs_dir.id
	root_dir.directories << assets_dir.id
	root_dir = fs_factory.fs_dir.set(root_dir)!

	assets_dir.directories << images_dir.id
	assets_dir = fs_factory.fs_dir.set(assets_dir)!

	docs_dir.directories << api_docs_dir.id
	docs_dir = fs_factory.fs_dir.set(docs_dir)!

	println('Directory hierarchy created successfully')

	// Create some files with different content types
	println('\nCreating various files...')

	// Text file for source code
	code_content := 'fn main() {\n    println("Hello, HeroFS!")\n}\n'.bytes()
	mut code_blob := fs_factory.fs_blob.new(data: code_content)!
	code_blob = fs_factory.fs_blob.set(code_blob)!

	mut code_file := fs_factory.fs_file.new(
		name:      'main.v'
		fs_id:     my_fs.id
		blobs:     [code_blob.id]
		mime_type: .txt
		metadata:  {
			'language': 'vlang'
			'version':  '0.3.3'
		}
	)!
	code_file = fs_factory.fs_file.set(code_file)!
	fs_factory.fs_file.add_to_directory(code_file.id, src_dir.id)!

	// Markdown documentation file
	docs_content := '# API Documentation\n\n## Endpoints\n\n- GET /api/v1/users\n- POST /api/v1/users\n'.bytes()
	mut docs_blob := fs_factory.fs_blob.new(data: docs_content)!
	docs_blob = fs_factory.fs_blob.set(docs_blob)!

	mut docs_file := fs_factory.fs_file.new(
		name:      'api.md'
		fs_id:     my_fs.id
		blobs:     [docs_blob.id]
		mime_type: .md
	)!
	docs_file = fs_factory.fs_file.set(docs_file)!
	fs_factory.fs_file.add_to_directory(docs_file.id, api_docs_dir.id)!

	// Create a binary file (sample image)
	// For this example, we'll just create random bytes
	mut image_data := []u8{len: 1024, init: u8(index % 256)}
	mut image_blob := fs_factory.fs_blob.new(data: image_data)!
	image_blob = fs_factory.fs_blob.set(image_blob)!

	mut image_file := fs_factory.fs_file.new(
		name:      'logo.png'
		fs_id:     my_fs.id
		blobs:     [image_blob.id]
		mime_type: .png
		metadata:  {
			'width':  '200'
			'height': '100'
			'format': 'PNG'
		}
	)!
	image_file = fs_factory.fs_file.set(image_file)!
	fs_factory.fs_file.add_to_directory(image_file.id, images_dir.id)!

	println('Files created successfully')

	// Create symlinks
	println('\nCreating symlinks...')

	// Symlink to the API docs from the root directory
	mut api_symlink := fs_factory.fs_symlink.new(
		name:        'api-docs'
		fs_id:       my_fs.id
		parent_id:   root_dir.id
		target_id:   api_docs_dir.id
		target_type: .directory
		description: 'Shortcut to API documentation'
	)!
	api_symlink = fs_factory.fs_symlink.set(api_symlink)!

	// Symlink to the logo from the docs directory
	mut logo_symlink := fs_factory.fs_symlink.new(
		name:        'logo.png'
		fs_id:       my_fs.id
		parent_id:   docs_dir.id
		target_id:   image_file.id
		target_type: .file
		description: 'Shortcut to project logo'
	)!
	logo_symlink = fs_factory.fs_symlink.set(logo_symlink)!

	// Add symlinks to their parent directories
	root_dir.symlinks << api_symlink.id
	root_dir = fs_factory.fs_dir.set(root_dir)!

	docs_dir.symlinks << logo_symlink.id
	docs_dir = fs_factory.fs_dir.set(docs_dir)!

	println('Symlinks created successfully')

	// Demonstrate filesystem navigation using find
	println('\nDemonstrating filesystem navigation...')

	// Get the filesystem instance for navigation
	mut fs := fs_factory.fs.get(my_fs.id)!

	// Find all items in the filesystem
	results := fs.find('/', recursive: true)!
	println('Complete filesystem structure:')
	for result in results {
		type_str := match result.result_type {
			.file { 'FILE' }
			.directory { 'DIR ' }
			.symlink { 'LINK' }
		}
		println('${type_str}: ${result.path} (ID: ${result.id})')
	}

	// Find specific file types
	println('\nFinding specific file types...')
	v_files := fs.find('/', include_patterns: ['*.v'], recursive: true)!
	println('V source files:')
	for file in v_files {
		println('  ${file.path}')
	}

	md_files := fs.find('/', include_patterns: ['*.md'], recursive: true)!
	println('Markdown files:')
	for file in md_files {
		println('  ${file.path}')
	}

	// Find files in specific directories
	println('\nFinding files in specific directories...')
	src_files := fs.find('/src', recursive: true)!
	println('Files in src directory:')
	for file in src_files {
		println('  ${file.path}')
	}

	// Demonstrate advanced file operations
	println('\nDemonstrating advanced file operations...')

	// Update file metadata
	println('Updating file metadata...')
	fs_factory.fs_file.update_metadata(docs_file.id, 'status', 'draft')!
	fs_factory.fs_file.update_metadata(docs_file.id, 'author', 'HeroFS Team')!

	// Update access time
	println('Updating file access time...')
	fs_factory.fs_file.update_accessed(docs_file.id)!

	// Rename a file
	println('Renaming main.v to app.v...')
	fs_factory.fs_file.rename(code_file.id, 'app.v')!

	// Append content to a file
	println('Appending content to API docs...')
	additional_content := '\n## Authentication\n\nUse Bearer token for authentication.\n'.bytes()
	mut additional_blob := fs_factory.fs_blob.new(data: additional_content)!
	additional_blob = fs_factory.fs_blob.set(additional_blob)!
	fs_factory.fs_file.append_blob(docs_file.id, additional_blob.id)!

	// Demonstrate directory operations
	println('\nDemonstrating directory operations...')

	// Create a temporary directory
	mut temp_dir := fs_factory.fs_dir.new(
		name:        'temp'
		fs_id:       my_fs.id
		parent_id:   root_dir.id
		description: 'Temporary directory'
	)!
	temp_dir = fs_factory.fs_dir.set(temp_dir)!

	// Add to parent
	root_dir.directories << temp_dir.id
	root_dir = fs_factory.fs_dir.set(root_dir)!

	// Move temp directory under docs
	println('Moving temp directory under docs...')
	fs_factory.fs_dir.move(temp_dir.id, docs_dir.id)!

	// Rename temp directory to drafts
	println('Renaming temp directory to drafts...')
	fs_factory.fs_dir.rename(temp_dir.id, 'drafts')!

	// Check if docs directory has children
	has_children := fs_factory.fs_dir.has_children(docs_dir.id)!
	println('Does docs directory have children? ${has_children}')

	// Demonstrate listing operations
	println('\nDemonstrating listing operations...')

	// List all files in filesystem
	all_files := fs_factory.fs_file.list_by_filesystem(my_fs.id)!
	println('All files in filesystem (${all_files.len}):')
	for file in all_files {
		println('- ${file.name} (ID: ${file.id})')
	}

	// List files by MIME type
	md_files_by_type := fs_factory.fs_file.list_by_mime_type(.md)!
	println('\nMarkdown files (${md_files_by_type.len}):')
	for file in md_files_by_type {
		println('- ${file.name} (ID: ${file.id})')
	}

	// List all symlinks
	all_symlinks := fs_factory.fs_symlink.list_by_filesystem(my_fs.id)!
	println('\nAll symlinks (${all_symlinks.len}):')
	for symlink in all_symlinks {
		target_type_str := if symlink.target_type == .file { 'file' } else { 'directory' }
		println('- ${symlink.name} -> ${symlink.target_id} (${target_type_str})')
	}

	// Check for broken symlinks
	println('\nChecking for broken symlinks:')
	for symlink in all_symlinks {
		is_broken := fs_factory.fs_symlink.is_broken(symlink.id)!
		println('- ${symlink.name}: ${if is_broken { 'BROKEN' } else { 'OK' }}')
	}

	// Demonstrate file content retrieval
	println('\nDemonstrating file content retrieval:')

	// Get the updated API docs file and print its content
	updated_docs_file := fs_factory.fs_file.get(docs_file.id)!
	println('Content of ${updated_docs_file.name}:')
	mut full_content := ''

	for blob_id in updated_docs_file.blobs {
		blob := fs_factory.fs_blob.get(blob_id)!
		full_content += blob.data.bytestr()
	}

	println('---BEGIN CONTENT---')
	println(full_content)
	println('---END CONTENT---')

	// Print filesystem information
	println('\nFilesystem information:')
	println('Filesystem: ${my_fs.name}')
	println('Description: ${my_fs.description}')
	println('Root directory ID: ${my_fs.root_dir_id}')

	println('\n=== HeroFS Advanced Example Completed Successfully! ===')
	println('This example demonstrated:')
	println('- Creating a complex directory hierarchy')
	println('- Creating files with different content types (text, markdown, binary)')
	println('- Creating symbolic links')
	println('- Using the find functionality to navigate the filesystem')
	println('- Advanced file operations: rename, metadata updates, append content')
	println('- Advanced directory operations: move, rename, check children')
	println('- Listing operations: files by filesystem, files by MIME type, symlinks')
	println('- Symlink validation: checking for broken links')
	println('- Retrieving and displaying file content')

	println('\nAll advanced HeroFS operations are now fully implemented!')
}
