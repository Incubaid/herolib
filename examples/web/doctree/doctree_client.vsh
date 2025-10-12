#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.doctree
import incubaid.herolib.web.doctreeclient
import os

println('This example demonstrates how to use the DocTreeClient to interact with doctree data.')
println('First, ensure doctree data is populated in Redis. This step is usually done once.')

// Populate Redis with doctree data (if not already done)
// This example uses a public Git repository for demonstration.
// In a real scenario, you might use your own documentation repository.
mut tree := doctree.new(name: 'tfgrid_docs')! // Using a distinct name for the example
tree.scan(
	git_url:  'https://git.threefold.info/tfgrid/docs_tfgrid4/src/branch/main/collections'
	git_pull: false // Set to true to pull latest changes
)!

tree.export(
	destination: '/tmp/doctree_example_export'
	reset:       true
)!

println('Doctree data setup complete.')

// Create a DocTreeClient instance
mut client := doctreeclient.new()!

// List all available collections
println('\n--- Listing Collections ---')
collections := client.list_collections()!
if collections.len == 0 {
	println('No collections found. Please ensure doctree data is correctly populated.')
	return
}

println('Found ${collections.len} collections:')
for collection in collections {
	println('- ${collection}')
}

// Use the first collection found for further demonstration
collection_name := collections[0]
println('\n--- Using collection: ${collection_name} ---')

// List pages within the selected collection
println('\n--- Listing Pages in ${collection_name} ---')
pages := client.list_pages(collection_name)!
if pages.len == 0 {
	println('No pages found in collection "${collection_name}".')
	return
}

println('Found ${pages.len} pages:')
for page in pages {
	println('- ${page}')
}

// Get content of the first page
page_to_get := pages[0]
println('\n--- Getting content for page: ${page_to_get} ---')
page_content := client.get_page_content(collection_name, page_to_get)!
println('Content of "${page_to_get}" (first 200 chars):\n${page_content[..200]}...')

// Check if a specific page exists
println('\n--- Checking page existence ---')
exists := client.page_exists(collection_name, page_to_get)
println('Page "${page_to_get}" exists: ${exists}')

non_existent_page := 'non_existent_page_123'
exists_non_existent := client.page_exists(collection_name, non_existent_page)
println('Page "${non_existent_page}" exists: ${exists_non_existent}')

// Step 7: List images in the collection
println('\n7. Listing images:')
images := client.list_images(collection_name)!
println('Found ${images.len} images: ${images}')

// Step 8: Get image path
if images.len > 0 {
	image_name := images[0]
	println('\n8. Getting path of image: ${image_name}')

	// Check if image exists
	exists2 := client.image_exists(collection_name, image_name)
	println('Image exists: ${exists2}')

	// Get image path
	image_path := client.get_image_path(collection_name, image_name)!
	println('Image path: ${image_path}')
}

// Step 9: List files in the collection
println('\n9. Listing files:')
files := client.list_files(collection_name)!
println('Found ${files.len} files: ${files}')

// Step 10: Get file path
if files.len > 0 {
	file_name := files[0]
	println('\n10. Getting path of file: ${file_name}')

	// Check if file exists
	exists3 := client.file_exists(collection_name, file_name)
	println('File exists: ${exists3}')

	// Get file path
	file_path := client.get_file_path(collection_name, file_name)!
	println('File path: ${file_path}')
}

// Step 11: Error handling example
println('\n11. Error handling example:')
println('Trying to access a non-existent page...')

non_existent_page2 := 'non_existent_page_2'
content := client.get_page_content(collection_name, non_existent_page2) or {
	println('Error caught: ${err}')
	'Error content'
}

println('\nExample completed successfully!')
