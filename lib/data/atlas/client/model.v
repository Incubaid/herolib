module client

// AtlasClient provides access to Atlas-exported documentation collections
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
	name string // name with extension
	path string // path in the collection
}

pub struct LinkMetadata {
pub mut:
	src                    string
	text                   string
	target                 string
	line                   int
	target_collection_name string
	target_item_name       string
	status                 string
	file_type              LinkFileType
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
