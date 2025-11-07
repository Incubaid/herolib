module doctreeclient

import incubaid.herolib.data.doctree
import incubaid.herolib.core.base
import incubaid.herolib.core.pathlib
import os

fn test_doctree_client() ! {
	println('Setting up doctree data in Redis...')

	// First, populate Redis with doctree data
	mut tree := doctree.new(name: 'test')!

	tree.scan(
		git_url:  'https://git.threefold.info/tfgrid/docs_tfgrid4/src/branch/main/collections'
		git_pull: false
	)!

	tree.export(
		destination:    '/tmp/mdexport'
		reset:          true
		exclude_errors: false
	)!

	println('Doctree data populated in Redis')

	// Create a DocTreeClient instance
	mut client := new()!

	// Test listing collections
	println('\nListing collections:')
	collections := client.list_collections()!
	println('Found ${collections.len} collections')

	if collections.len == 0 {
		println('No collections found. Test cannot continue.')
		panic('No collections found')
	}

	// Use the first collection for testing
	collection_name := collections[0]
	println('\nUsing collection: ${collection_name}')

	// Test listing pages
	println('\nListing pages:')
	pages := client.list_pages(collection_name)!
	println('Found ${pages.len} pages')

	if pages.len > 0 {
		// Test getting page path and content
		page_name := pages[0]
		println('\nTesting page: ${page_name}')

		// Test page existence
		exists := client.page_exists(collection_name, page_name)
		println('Page exists: ${exists}')

		// Test getting page path
		page_path := client.get_page_path(collection_name, page_name)!
		println('Page path: ${page_path}')

		// Test getting page content
		content := client.get_page_content(collection_name, page_name)!
		println('Page content length: ${content.len} characters')
	} else {
		println('No pages found for testing')
	}

	// Test listing images
	println('\nListing images:')
	images := client.list_images(collection_name)!
	println('Found ${images.len} images')

	if images.len > 0 {
		// Test getting image path
		image_name := images[0]
		println('\nTesting image: ${image_name}')

		// Test image existence
		exists := client.image_exists(collection_name, image_name)
		println('Image exists: ${exists}')

		// Test getting image path
		image_path := client.get_image_path(collection_name, image_name)!
		println('Image path: ${image_path}')

		// Check if the image file exists on disk
		println('Image file exists on disk: ${os.exists(image_path)}')
	} else {
		println('No images found for testing')
	}

	// Test listing files
	println('\nListing files:')
	files := client.list_files(collection_name)!
	println('Found ${files.len} files')

	if files.len > 0 {
		// Test getting file path
		file_name := files[0]
		println('\nTesting file: ${file_name}')

		// Test file existence
		exists := client.file_exists(collection_name, file_name)
		println('File exists: ${exists}')

		// Test getting file path
		file_path := client.get_file_path(collection_name, file_name)!
		println('File path: ${file_path}')

		// Check if the file exists on disk
		println('File exists on disk: ${os.exists(file_path)}')
	} else {
		println('No files found for testing')
	}

	// Test error handling
	println('\nTesting error handling:')

	// Test with non-existent collection
	non_existent_collection := 'non_existent_collection'
	println('Testing with non-existent collection: ${non_existent_collection}')

	exists := client.page_exists(non_existent_collection, 'any_page')
	println('Page exists in non-existent collection: ${exists} (should be false)')

	// Test with non-existent page
	non_existent_page := 'non_existent_page'
	println('Testing with non-existent page: ${non_existent_page}')

	exists2 := client.page_exists(collection_name, non_existent_page)
	println('Non-existent page exists: ${exists2} (should be false)')

	println('\nTest completed successfully!')
}
