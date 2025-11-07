module client

// AtlasErrors represents different types of errors that can occur in AtlasClient
pub enum AtlasErrors {
	collection_not_found
	page_not_found
	file_not_found
	image_not_found
	export_dir_not_found
	invalid_export_structure
}

// AtlasError represents an error with a message and a reason
struct AtlasError {
pub mut:
	message string      // The error message
	reason  AtlasErrors // The reason for the error
}

@[params]
struct ErrorArgs {
pub mut:
	message string      @[required] // The error message
	reason  AtlasErrors @[required] // The error reason
}

// new_error creates a new AtlasError
pub fn new_error(args ErrorArgs) AtlasError {
	return AtlasError{
		message: args.message
		reason:  args.reason
	}
}

// throw_error throws an error with a message and a reason
fn (err AtlasError) throw_error(args ErrorArgs) IError {
	return error('${args.reason}: ${args.message}')
}

// Error helper methods following the same pattern

@[params]
struct CollectionNotFoundArgs {
pub mut:
	collection_name string @[required] // The collection name
}

// error_collection_not_found returns an error for when a collection is not found
pub fn (err AtlasError) error_collection_not_found(args CollectionNotFoundArgs) IError {
	return err.throw_error(
		message: 'Collection "${args.collection_name}" not found'
		reason:  .collection_not_found
	)
}

@[params]
struct CollectionNotFoundAtArgs {
pub mut:
	collection_name string @[required] // The collection name
	path            string @[required] // The path where metadata was expected
}

// error_collection_not_found_at returns an error for when a collection metadata file is not found
pub fn (err AtlasError) error_collection_not_found_at(args CollectionNotFoundAtArgs) IError {
	return err.throw_error(
		message: 'Metadata file for collection "${args.collection_name}" not found at "${args.path}"'
		reason:  .collection_not_found
	)
}

@[params]
struct PageNotFoundArgs {
pub mut:
	collection_name string @[required] // The collection name
	page_name       string @[required] // The page name
}

// error_page_not_found returns an error for when a page is not found in a collection
pub fn (err AtlasError) error_page_not_found(args PageNotFoundArgs) IError {
	return err.throw_error(
		message: 'Page "${args.page_name}" not found in collection "${args.collection_name}"'
		reason:  .page_not_found
	)
}

// error_page_not_found_in_metadata returns an error for when a page is not found in collection metadata
pub fn (err AtlasError) error_page_not_found_in_metadata(args PageNotFoundArgs) IError {
	return err.throw_error(
		message: 'Page "${args.page_name}" not found in collection metadata'
		reason:  .page_not_found
	)
}

@[params]
struct PageFileNotExistsArgs {
pub mut:
	page_path string @[required] // The page file path
}

// error_page_file_not_exists returns an error for when a page file doesn't exist on disk
pub fn (err AtlasError) error_page_file_not_exists(args PageFileNotExistsArgs) IError {
	return err.throw_error(
		message: 'Page file "${args.page_path}" does not exist on disk'
		reason:  .page_not_found
	)
}

@[params]
struct FileNotFoundArgs {
pub mut:
	collection_name string @[required] // The collection name
	file_name       string @[required] // The file name
}

// error_file_not_found returns an error for when a file is not found in a collection
pub fn (err AtlasError) error_file_not_found(args FileNotFoundArgs) IError {
	return err.throw_error(
		message: 'File "${args.file_name}" not found in collection "${args.collection_name}"'
		reason:  .file_not_found
	)
}

@[params]
struct ImageNotFoundArgs {
pub mut:
	collection_name string @[required] // The collection name
	image_name      string @[required] // The image name
}

// error_image_not_found returns an error for when an image is not found in a collection
pub fn (err AtlasError) error_image_not_found(args ImageNotFoundArgs) IError {
	return err.throw_error(
		message: 'Image "${args.image_name}" not found in collection "${args.collection_name}"'
		reason:  .image_not_found
	)
}

// error_image_not_found_linked returns an error for when a linked image is not found
pub fn (err AtlasError) error_image_not_found_linked(args ImageNotFoundArgs) IError {
	return error('Error: Linked image "${args.image_name}" not found in collection "${args.collection_name}".')
}

@[params]
struct ExportDirNotFoundArgs {
pub mut:
	export_dir string @[required] // The export directory path
}

// error_export_dir_not_found returns an error for when the export directory doesn't exist
pub fn (err AtlasError) error_export_dir_not_found(args ExportDirNotFoundArgs) IError {
	return err.throw_error(
		message: 'Export directory "${args.export_dir}" not found'
		reason:  .export_dir_not_found
	)
}

@[params]
struct InvalidExportStructureArgs {
pub mut:
	content_dir string @[required] // The content directory path
}

// error_invalid_export_structure returns an error for when the export directory structure is invalid
pub fn (err AtlasError) error_invalid_export_structure(args InvalidExportStructureArgs) IError {
	return err.throw_error(
		message: 'Content directory not found at "${args.content_dir}"'
		reason:  .invalid_export_structure
	)
}
