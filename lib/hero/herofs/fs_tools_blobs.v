module herofs

// Check if a blob is used by other files (excluding the specified file_id)
fn (mut self FsTools) is_blob_used_by_other_files(blob_id u32, exclude_file_id u32) !bool {
	// This is a simple but potentially expensive check
	// In a production system, you might want to maintain reverse indices
	all_files := self.list_all_files()!
	for file in all_files {
		if file.id != exclude_file_id && blob_id in file.blobs {
			return true
		}
	}
	return false
}
