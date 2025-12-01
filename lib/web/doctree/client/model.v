module client

// DocTreeClient provides access to DocTree-exported documentation collections
// It reads from both the exported directory structure and Redis metadata

// List of recognized image file extensions
const image_extensions = ['.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.bmp', '.tiff', '.ico']

// CollectionMetadata represents the metadata stored in meta/{collection}.json
pub struct CollectionMetadata {
pub mut:
	name   string
	path   string
	pages  map[string]PageMetadata
	files  map[string]FileMetadata
	errors []ErrorMetadata
}

pub struct PageMetadata {
pub mut:
	name            string
	path            string
	collection_name string
	links           []LinkMetadata
}

pub struct FileMetadata {
pub mut:
	name string // name WITH extension (e.g., "image.png", "data.csv")
	path string // relative path in export (e.g., "img/image.png" or "files/data.csv")
}

pub struct LinkMetadata {
pub mut:
	src                    string
	text                   string
	target                 string
	line                   int
	target_collection_name string
	target_item_name       string
	status                 LinkStatus
	file_type              LinkFileType
}

pub enum LinkStatus {
	init
	external
	found
	not_found
	anchor
	error
}

pub enum LinkFileType {
	page  // Default: link to another page
	file  // Link to a non-image file
	image // Link to an image file
}

pub struct ErrorMetadata {
pub mut:
	category string
	page_key string
	message  string
	line     int
}
