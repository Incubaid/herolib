#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.core.redisclient
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

	// Create some subdirectories
	mut docs_dir := fs_factory.fs_dir.new(
		name:        'documents'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Documents directory'
	)!

	mut pics_dir := fs_factory.fs_dir.new(
		name:        'pictures'
		fs_id:       fs_id
		parent_id:   root_dir_id
		description: 'Pictures directory'
	)!

	// Save the subdirectories
	docs_dir_id := fs_factory.fs_dir.set(docs_dir)!
	pics_dir_id := fs_factory.fs_dir.set(pics_dir)!
	println('Created documents directory with ID: ${docs_dir_id}')
	println('Created pictures directory with ID: ${pics_dir_id}')

	// Create a text file blob
	text_content := 'Hello, world! This is a test file in HeroFS.'.bytes()
	mut text_blob := fs_factory.fs_blob.new(
		data:      text_content
		mime_type: 'text/plain'
		name:      'hello.txt blob'
	)!

	// Save the blob
	blob_id := fs_factory.fs_blob.set(text_blob)!
	println('Created text blob with ID: ${blob_id}')

	// Create a file referencing the blob
	mut text_file := fs_factory.fs_file.new(
		name:        'hello.txt'
		fs_id:       fs_id
		directories: [docs_dir_id]
		blobs:       [blob_id]
		mime_type:   'text/plain'
	)!

	// Save the file
	file_id := fs_factory.fs_file.set(text_file)!
	println('Created text file with ID: ${file_id}')

	// List all directories in the filesystem
	dirs := fs_factory.fs_dir.list_by_filesystem(fs_id)!
	println('\nAll directories in filesystem:')
	for dir in dirs {
		println('- ${dir.name} (ID: ${dir.id})')
	}

	// List all files in the documents directory
	files := fs_factory.fs_file.list_by_directory(docs_dir_id)!
	println('\nFiles in documents directory:')
	for file in files {
		println('- ${file.name} (ID: ${file.id}, Size: ${file.size_bytes} bytes)')

		// Get the file's content from its blobs
		if file.blobs.len > 0 {
			blob := fs_factory.fs_blob.get(file.blobs[0])!
			content := blob.data.bytestr()
			println('  Content: "${content}"')
		}
	}

	println('\nHeroFS basic example completed successfully!')
}
