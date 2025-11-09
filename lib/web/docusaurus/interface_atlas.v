module docusaurus

import incubaid.herolib.core.pathlib
import incubaid.herolib.data.atlas.client as atlas_client
import incubaid.herolib.web.site
import incubaid.herolib.data.markdown.tools as markdowntools
import incubaid.herolib.ui.console

pub interface IDocClient {
mut:
	// Path methods - get absolute paths to resources
	get_page_path(collection_name string, page_name string) !string
	get_file_path(collection_name string, file_name string) !string
	get_image_path(collection_name string, image_name string) !string

	// Existence checks - verify if resources exist
	page_exists(collection_name string, page_name string) bool
	file_exists(collection_name string, file_name string) bool
	image_exists(collection_name string, image_name string) bool

	// Content retrieval
	get_page_content(collection_name string, page_name string) !string

	// Listing methods - enumerate resources
	list_collections() ![]string
	list_pages(collection_name string) ![]string
	list_files(collection_name string) ![]string
	list_images(collection_name string) ![]string
	list_pages_map() !map[string][]string
	list_markdown() !string

	// Image operations
	// get_page_paths(collection_name string, page_name string) !(string, []string)
	copy_images(collection_name string, page_name string, destination_path string) !
}
