#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.hero.herofs
import time
import os

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

	// Save the filesystem to get an ID
	fs_id := fs_factory.fs.set(my_fs)!
	println('Created filesystem: ${my_fs.name} with ID: ${fs_id}')

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:        'root'
		fs_id:       fs_id
		parent_id:   0 // Root has no parent
		description: 'Root directory'
	)!

	// Save the root directory
	root_dir_id := fs_factory.fs_dir.set(root_dir)!
	println('Created root directory with ID: ${root_dir_id}')

	// Update the filesystem with the root directory ID
	my_fs.root_dir_id = root_dir_id
	fs_factory.fs.set(my_fs)!

	// Create a directory hierarchy
	println('\nCreating directory hierarchy...')

	// Main project directories
	mut src_dir := fs_factory.fs_dir.new(
		name:        'src'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Source code'
	)!
	src_dir_id := fs_factory.fs_dir.set(src_dir)!

	mut docs_dir := fs_factory.fs_dir.new(
		name:        'docs'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Documentation'
	)!
	docs_dir_id := fs_factory.fs_dir.set(docs_dir)!

	mut assets_dir := fs_factory.fs_dir.new(
		name:        'assets'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Project assets'
	)!
	assets_dir_id := fs_factory.fs_dir.set(assets_dir)!

	// Subdirectories
	mut images_dir := fs_factory.fs_dir.new(
		name:        'images'
		fs_id:       fs_id
		parent_id:   assets_dir_id
		description: 'Image assets'
	)!
	images_dir_id := fs_factory.fs_dir.set(images_dir)!

	mut api_docs_dir := fs_factory.fs_dir.new(
		name:        'api'
		fs_id:       fs_id
		parent_id:   docs_dir_id
		description: 'API documentation'
	)!
	api_docs_dir_id := fs_factory.fs_dir.set(api_docs_dir)!

	println('Directory hierarchy created successfully')

	// Create some files with different content types
	println('\nCreating various files...')

	// Text file for source code
	code_content := 'fn main() {\n    println("Hello, HeroFS!")\n}\n'.bytes()
	mut code_blob := fs_factory.fs_blob.new(
		data:      code_content
		mime_type: 'text/plain'
		name:      'main.v blob'
	)!
	code_blob_id := fs_factory.fs_blob.set(code_blob)!

	mut code_file := fs_factory.fs_file.new(
		name:        'main.v'
		fs_id:       fs_id
		directories: [src_dir_id]
		blobs:       [code_blob_id]
		mime_type:   'text/plain'
		metadata:    {
			'language': 'vlang'
			'version':  '0.3.3'
		}
	)!
	code_file_id := fs_factory.fs_file.set(code_file)!

	// Markdown documentation file
	docs_content := '# API Documentation\n\n## Endpoints\n\n- GET /api/v1/users\n- POST /api/v1/users\n'.bytes()
	mut docs_blob := fs_factory.fs_blob.new(
		data:      docs_content
		mime_type: 'text/markdown'
		name:      'api.md blob'
	)!
	docs_blob_id := fs_factory.fs_blob.set(docs_blob)!

	mut docs_file := fs_factory.fs_file.new(
		name:        'api.md'
		fs_id:       fs_id
		directories: [api_docs_dir_id]
		blobs:       [docs_blob_id]
		mime_type:   'text/markdown'
	)!
	docs_file_id := fs_factory.fs_file.set(docs_file)!

	// Create a binary file (sample image)
	// For this example, we'll just create random bytes
	mut image_data := []u8{len: 1024, init: u8(index % 256)}
	mut image_blob := fs_factory.fs_blob.new(
		data:      image_data
		mime_type: 'image/png'
		name:      'logo.png blob'
	)!
	image_blob_id := fs_factory.fs_blob.set(image_blob)!

	mut image_file := fs_factory.fs_file.new(
		name:        'logo.png'
		fs_id:       fs_id
		directories: [images_dir_id]
		blobs:       [image_blob_id]
		mime_type:   'image/png'
		metadata:    {
			'width':  '200'
			'height': '100'
			'format': 'PNG'
		}
	)!
	image_file_id := fs_factory.fs_file.set(image_file)!

	println('Files created successfully')

	// Create symlinks
	println('\nCreating symlinks...')

	// Symlink to the API docs from the root directory
	mut api_symlink := fs_factory.fs_symlink.new(
		name:        'api-docs'
		fs_id:       fs_id
		parent_id:   root_dir_id
		target_id:   api_docs_dir_id
		target_type: .directory
		description: 'Shortcut to API documentation'
	)!
	api_symlink_id := fs_factory.fs_symlink.set(api_symlink)!

	// Symlink to the logo from the docs directory
	mut logo_symlink := fs_factory.fs_symlink.new(
		name:        'logo.png'
		fs_id:       fs_id
		parent_id:   docs_dir_id
		target_id:   image_file_id
		target_type: .file
		description: 'Shortcut to project logo'
	)!
	logo_symlink_id := fs_factory.fs_symlink.set(logo_symlink)!

	println('Symlinks created successfully')

	// Demonstrate file operations
	println('\nDemonstrating file operations...')

	// 1. Move a file to multiple directories (hard link-like behavior)
	println('Moving logo.png to both images and docs directories...')
	image_file = fs_factory.fs_file.get(image_file_id)!
	fs_factory.fs_file.move(image_file_id, [images_dir_id, docs_dir_id])!
	image_file = fs_factory.fs_file.get(image_file_id)!

	// 2. Rename a file
	println('Renaming main.v to app.v...')
	fs_factory.fs_file.rename(code_file_id, 'app.v')!
	code_file = fs_factory.fs_file.get(code_file_id)!

	// 3. Update file metadata
	println('Updating file metadata...')
	fs_factory.fs_file.update_metadata(docs_file_id, 'status', 'draft')!
	fs_factory.fs_file.update_metadata(docs_file_id, 'author', 'HeroFS Team')!

	// 4. Update file access time when "reading" it
	println('Updating file access time...')
	fs_factory.fs_file.update_accessed(docs_file_id)!

	// 5. Add additional content to a file (append a blob)
	println('Appending content to API docs...')
	additional_content := '\n## Authentication\n\nUse Bearer token for authentication.\n'.bytes()
	mut additional_blob := fs_factory.fs_blob.new(
		data:      additional_content
		mime_type: 'text/markdown'
		name:      'api_append.md blob'
	)!
	additional_blob_id := fs_factory.fs_blob.set(additional_blob)!
	fs_factory.fs_file.append_blob(docs_file_id, additional_blob_id)!

	// Demonstrate directory operations
	println('\nDemonstrating directory operations...')

	// 1. Create a new directory and move it
	mut temp_dir := fs_factory.fs_dir.new(
		name:        'temp'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Temporary directory'
	)!
	temp_dir_id := fs_factory.fs_dir.set(temp_dir)!

	println('Moving temp directory to be under docs...')
	fs_factory.fs_dir.move(temp_dir_id, docs_dir_id)!

	// 2. Rename a directory
	println('Renaming temp directory to drafts...')
	fs_factory.fs_dir.rename(temp_dir_id, 'drafts')!

	// 3. Check if a directory has children
	has_children := fs_factory.fs_dir.has_children(docs_dir_id)!
	println('Does docs directory have children? ${has_children}')

	// Demonstrate searching and filtering
	println('\nDemonstrating searching and filtering...')

	// 1. List all files in the filesystem
	all_files := fs_factory.fs_file.list_by_filesystem(fs_id)!
	println('All files in filesystem (${all_files.len}):')
	for file in all_files {
		println('- ${file.name} (ID: ${file.id})')
	}

	// 2. List files by MIME type
	markdown_files := fs_factory.fs_file.list_by_mime_type('text/markdown')!
	println('\nMarkdown files (${markdown_files.len}):')
	for file in markdown_files {
		println('- ${file.name} (ID: ${file.id})')
	}

	// 3. List all symlinks
	all_symlinks := fs_factory.fs_symlink.list_by_filesystem(fs_id)!
	println('\nAll symlinks (${all_symlinks.len}):')
	for symlink in all_symlinks {
		target_type_str := if symlink.target_type == .file { 'file' } else { 'directory' }
		println('- ${symlink.name} -> ${symlink.target_id} (${target_type_str})')
	}

	// 4. Check for broken symlinks
	println('\nChecking for broken symlinks:')
	for symlink in all_symlinks {
		is_broken := fs_factory.fs_symlink.is_broken(symlink.id)!
		println('- ${symlink.name}: ${if is_broken { 'BROKEN' } else { 'OK' }}')
	}

	// Demonstrate file content retrieval
	println('\nDemonstrating file content retrieval:')

	// Get the updated API docs file and print its content
	docs_file = fs_factory.fs_file.get(docs_file_id)!
	println('Content of ${docs_file.name}:')
	mut full_content := ''

	for blob_id in docs_file.blobs {
		blob := fs_factory.fs_blob.get(blob_id)!
		full_content += blob.data.bytestr()
	}

	println('---BEGIN CONTENT---')
	println(full_content)
	println('---END CONTENT---')

	// Print filesystem usage
	println('\nFilesystem usage:')
	my_fs = fs_factory.fs.get(fs_id)!
	println('Used: ${my_fs.used_bytes} bytes')
	println('Quota: ${my_fs.quota_bytes} bytes')
	println('Available: ${my_fs.quota_bytes - my_fs.used_bytes} bytes')

	println('\nHeroFS advanced example completed successfully!')
}
