module herofs

import os
import freeflowuniverse.herolib.data.ourtime

// ImportOptions provides options for import operations
@[params]
pub struct ImportOptions {
pub mut:
	recursive     bool = true // Import directories recursively
	overwrite     bool // Overwrite existing files in VFS
	preserve_meta bool = true // Preserve file metadata (timestamps, etc.)
}

// ExportOptions provides options for export operations
@[params]
pub struct ExportOptions {
pub mut:
	recursive     bool = true // Export directories recursively
	overwrite     bool // Overwrite existing files on real filesystem
	preserve_meta bool = true // Preserve file metadata (timestamps, etc.)
}

// import copies data from the real filesystem into the VFS
//
// Parameters:
// - src: Source path on real filesystem
// - dest: Destination path in VFS
// - opts: ImportOptions for import behavior
//
// Example:
// ```
// fs.import('/home/user/documents', '/imported', ImportOptions{recursive: true, overwrite: true})!
// ```
pub fn (mut self Fs) import(src string, dest string, opts ImportOptions) ! {
	// Check if source exists on real filesystem
	if !os.exists(src) {
		return error('Source path does not exist: ${src}')
	}

	// Determine if source is file or directory
	if os.is_file(src) {
		self.import_file(src, dest, opts)!
	} else if os.is_dir(src) {
		self.import_directory(src, dest, opts)!
	} else {
		return error('Source path is neither file nor directory: ${src}')
	}
}

// export copies data from VFS to the real filesystem
//
// Parameters:
// - src: Source path in VFS
// - dest: Destination path on real filesystem
// - opts: ExportOptions for export behavior
//
// Example:
// ```
// fs.export('/documents', '/home/user/backup', ExportOptions{recursive: true, overwrite: true})!
// ```
pub fn (mut self Fs) export(src string, dest string, opts ExportOptions) ! {
	// Find the source in VFS
	results := self.find(src, recursive: false)!
	if results.len == 0 {
		return error('Source path not found in VFS: ${src}')
	}

	result := results[0]
	match result.result_type {
		.file {
			self.export_file(result.id, dest, opts)!
		}
		.directory {
			self.export_directory(result.id, dest, opts)!
		}
		.symlink {
			self.export_symlink(result.id, dest, opts)!
		}
	}
}

// import_file imports a single file from real filesystem to VFS
fn (mut self Fs) import_file(src_path string, dest_path string, opts ImportOptions) ! {
	// Read file content from real filesystem
	file_data := os.read_bytes(src_path) or {
		return error('Failed to read file ${src_path}: ${err}')
	}

	// Get file info for metadata
	file_info := os.stat(src_path) or {
		return error('Failed to get file info for ${src_path}: ${err}')
	}

	// Extract filename from destination path
	dest_dir_path := os.dir(dest_path)
	filename := os.base(dest_path)

	// Ensure destination directory exists in VFS
	dest_dir_id := self.factory.fs_dir.create_path(self.id, dest_dir_path)!

	// Check if file already exists
	if !opts.overwrite {
		if _ := self.get_file_by_absolute_path(dest_path) {
			return error('File already exists at ${dest_path} and overwrite is false')
		}
	}

	// Create blob for file content
	mut blob := self.factory.fs_blob.new(data: file_data)!
	self.factory.fs_blob.set(mut blob)!

	// Determine MIME type based on file extension
	mime_type := extension_to_mime_type(os.file_ext(filename))

	// Create file in VFS
	mut vfs_file := self.factory.fs_file.new(
		name:      filename
		fs_id:     self.id
		blobs:     [blob.id]
		mime_type: mime_type
		metadata:  if opts.preserve_meta {
			{
				'original_path': src_path
				'imported_at':   '${ourtime.now().unix()}'
				'size':          '${file_info.size}'
				'modified':      '${file_info.mtime}'
			}
		} else {
			map[string]string{}
		}
	)!

	// If file exists and overwrite is true, remove the old one
	if opts.overwrite {
		if existing_file := self.get_file_by_absolute_path(dest_path) {
			self.factory.fs_file.delete(existing_file.id)!
		}
	}

	self.factory.fs_file.set(mut vfs_file)!
	self.factory.fs_file.add_to_directory(vfs_file.id, dest_dir_id)!
}

// extension_to_mime_type converts file extension to MimeType enum
pub fn extension_to_mime_type(ext string) MimeType {
	// Remove leading dot if present
	clean_ext := ext.trim_left('.')

	return match clean_ext.to_lower() {
		'v' { .txt } // V source files as text
		'txt', 'text' { .txt }
		'md', 'markdown' { .md }
		'html', 'htm' { .html }
		'css' { .css }
		'js', 'javascript' { .js }
		'json' { .json }
		'xml' { .xml }
		'csv' { .csv }
		'pdf' { .pdf }
		'png' { .png }
		'jpg', 'jpeg' { .jpg }
		'gif' { .gif }
		'svg' { .svg }
		'mp3' { .mp3 }
		'mp4' { .mp4 }
		'zip' { .zip }
		'tar' { .tar }
		'gz' { .gz }
		'sh', 'bash' { .sh }
		'php' { .php }
		'doc' { .doc }
		'docx' { .docx }
		'xls' { .xls }
		'xlsx' { .xlsx }
		'ppt' { .ppt }
		'pptx' { .pptx }
		else { .bin } // Default to binary for unknown extensions
	}
}

// import_directory imports a directory recursively from real filesystem to VFS
fn (mut self Fs) import_directory(src_path string, dest_path string, opts ImportOptions) ! {
	// Create the destination directory in VFS
	_ := self.factory.fs_dir.create_path(self.id, dest_path)!

	// Read directory contents
	entries := os.ls(src_path) or { return error('Failed to list directory ${src_path}: ${err}') }

	for entry in entries {
		src_entry_path := os.join_path(src_path, entry)
		dest_entry_path := os.join_path(dest_path, entry)

		if os.is_file(src_entry_path) {
			self.import_file(src_entry_path, dest_entry_path, opts)!
		} else if os.is_dir(src_entry_path) && opts.recursive {
			self.import_directory(src_entry_path, dest_entry_path, opts)!
		}
	}
}

// export_file exports a single file from VFS to real filesystem
fn (mut self Fs) export_file(file_id u32, dest_path string, opts ExportOptions) ! {
	// Get file from VFS
	vfs_file := self.factory.fs_file.get(file_id)!

	// Check if destination exists and handle overwrite
	if os.exists(dest_path) && !opts.overwrite {
		return error('File already exists at ${dest_path} and overwrite is false')
	}

	// Ensure destination directory exists
	dest_dir := os.dir(dest_path)
	if !os.exists(dest_dir) {
		os.mkdir_all(dest_dir) or { return error('Failed to create directory ${dest_dir}: ${err}') }
	}

	// Collect all blob data
	mut file_data := []u8{}
	for blob_id in vfs_file.blobs {
		blob := self.factory.fs_blob.get(blob_id)!
		file_data << blob.data
	}

	// Write file to real filesystem
	os.write_file_array(dest_path, file_data) or {
		return error('Failed to write file ${dest_path}: ${err}')
	}

	// Preserve metadata if requested
	if opts.preserve_meta {
		// Set file modification time if available in metadata
		if _ := vfs_file.metadata['modified'] {
			// Note: V doesn't have built-in utime, but we could add this later
			// For now, just preserve the metadata in a comment or separate file
		}
	}
}

// export_directory exports a directory recursively from VFS to real filesystem
fn (mut self Fs) export_directory(dir_id u32, dest_path string, opts ExportOptions) ! {
	// Get directory from VFS
	vfs_dir := self.factory.fs_dir.get(dir_id)!

	// Create destination directory on real filesystem
	if !os.exists(dest_path) {
		os.mkdir_all(dest_path) or {
			return error('Failed to create directory ${dest_path}: ${err}')
		}
	}

	// Export all files in the directory
	for file_id in vfs_dir.files {
		file := self.factory.fs_file.get(file_id)!
		file_dest_path := os.join_path(dest_path, file.name)
		self.export_file(file_id, file_dest_path, opts)!
	}

	// Export all subdirectories if recursive
	if opts.recursive {
		for subdir_id in vfs_dir.directories {
			subdir := self.factory.fs_dir.get(subdir_id)!
			subdir_dest_path := os.join_path(dest_path, subdir.name)
			self.export_directory(subdir_id, subdir_dest_path, opts)!
		}
	}

	// Export all symlinks in the directory
	for symlink_id in vfs_dir.symlinks {
		symlink := self.factory.fs_symlink.get(symlink_id)!
		symlink_dest_path := os.join_path(dest_path, symlink.name)
		self.export_symlink(symlink_id, symlink_dest_path, opts)!
	}
}

// export_symlink exports a symlink from VFS to real filesystem
fn (mut self Fs) export_symlink(symlink_id u32, dest_path string, opts ExportOptions) ! {
	// Get symlink from VFS
	vfs_symlink := self.factory.fs_symlink.get(symlink_id)!

	// Check if destination exists and handle overwrite
	if os.exists(dest_path) && !opts.overwrite {
		return error('Symlink already exists at ${dest_path} and overwrite is false')
	}

	// Create symlink on real filesystem
	// Note: V's os.symlink might not be available on all platforms
	// For now, we'll create a text file with the target path
	// Get target path by resolving the target_id
	target_path := if vfs_symlink.target_type == .file {
		target_file := self.factory.fs_file.get(vfs_symlink.target_id)!
		'FILE:${target_file.name}'
	} else {
		target_dir := self.factory.fs_dir.get(vfs_symlink.target_id)!
		'DIR:${target_dir.name}'
	}
	symlink_content := 'SYMLINK_TARGET: ${target_path}'
	os.write_file(dest_path + '.symlink', symlink_content) or {
		return error('Failed to create symlink file ${dest_path}.symlink: ${err}')
	}
}
