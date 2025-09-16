#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.hero.herofs

// Basic example of using HeroFS - the Hero Filesystem
// Demonstrates creating a filesystem, directories, and files

fn main() {
	// Initialize the HeroFS factory
	mut fs_factory := herofs.new()!
	println('HeroFS factory initialized')

	// Create a new filesystem
	mut my_fs := fs_factory.fs.new(
		name:        'my_documents'
		description: 'Personal documents filesystem'
		quota_bytes: 1024 * 1024 * 1024 // 1GB quota
	)!

	// Save the filesystem
	fs_factory.fs.set(mut my_fs)!
	println('Created filesystem: ${my_fs.name} with ID: ${my_fs.id}')

	// Create root directory
	mut root_dir := fs_factory.fs_dir.new(
		name:        'root'
		fs_id:       my_fs.id
		parent_id:   0 // Root has no parent
		description: 'Root directory'
	)!

	// Save the root directory
	fs_factory.fs_dir.set(mut root_dir)!
	println('Created root directory with ID: ${root_dir.id}')

	// Update the filesystem with the root directory ID
	my_fs.root_dir_id = root_dir.id
	fs_factory.fs.set(mut my_fs)!

	// Create some subdirectories
	mut docs_dir := fs_factory.fs_dir.new(
		name:        'documents'
		fs_id:       my_fs.id
		parent_id:   root_dir.id
		description: 'Documents directory'
	)!

	mut pics_dir := fs_factory.fs_dir.new(
		name:        'pictures'
		fs_id:       my_fs.id
		parent_id:   root_dir.id
		description: 'Pictures directory'
	)!

	// Save the subdirectories
	fs_factory.fs_dir.set(mut docs_dir)!
	fs_factory.fs_dir.set(mut pics_dir)!

	// Add subdirectories to root directory
	root_dir.directories << docs_dir.id
	root_dir.directories << pics_dir.id
	fs_factory.fs_dir.set(mut root_dir)!

	println('Created documents directory with ID: ${docs_dir.id}')
	println('Created pictures directory with ID: ${pics_dir.id}')

	// Create a text file blob
	text_content := 'Hello, world! This is a test file in HeroFS.'.bytes()
	mut text_blob := fs_factory.fs_blob.new(data: text_content)!

	// Save the blob
	fs_factory.fs_blob.set(mut text_blob)!
	println('Created text blob with ID: ${text_blob.id}')

	// Create a file referencing the blob
	mut text_file := fs_factory.fs_file.new(
		name:      'hello.txt'
		fs_id:     my_fs.id
		blobs:     [text_blob.id]
		mime_type: .txt
	)!

	// Save the file
	fs_factory.fs_file.set(mut text_file)!
	// Associate file with documents directory
	fs_factory.fs_file.add_to_directory(text_file.id, docs_dir.id)!
	println('Created text file with ID: ${text_file.id}')

	// Demonstrate filesystem navigation using find
	mut fs := fs_factory.fs.get(my_fs.id)!

	println('\nAll items in filesystem:')
	results := fs.find('/', recursive: true)!
	for result in results {
		type_str := match result.result_type {
			.file { 'FILE' }
			.directory { 'DIR ' }
			.symlink { 'LINK' }
		}
		println('- ${type_str}: ${result.path} (ID: ${result.id})')

		// If it's a file, show its content
		if result.result_type == .file {
			file := fs_factory.fs_file.get(result.id)!
			if file.blobs.len > 0 {
				blob := fs_factory.fs_blob.get(file.blobs[0])!
				content := blob.data.bytestr()
				println('  Content: "${content}"')
			}
		}
	}

	println('\nHeroFS basic example completed successfully!')
}
