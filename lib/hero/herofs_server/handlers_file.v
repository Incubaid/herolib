module herofs_server

import veb
import json
import freeflowuniverse.herolib.hero.herofs

// =============================================================================
// FILE ENDPOINTS
// =============================================================================

// List all files
@['/api/files'; get]
pub fn (mut server FSServer) list_files(mut ctx Context) veb.Result {
	files := server.fs_factory.fs_file.list() or {
		return ctx.server_error('Failed to list files: ${err}')
	}
	return ctx.success(files, 'Files retrieved successfully')
}

// Get file by ID
@['/api/files/:id'; get]
pub fn (mut server FSServer) get_file(mut ctx Context, id string) veb.Result {
	file_id := id.u32()
	if file_id == 0 {
		return ctx.request_error('Invalid file ID')
	}

	file := server.fs_factory.fs_file.get(file_id) or { return ctx.not_found('File not found') }
	return ctx.success(file, 'File retrieved successfully')
}

// Create new file
@['/api/files'; post]
pub fn (mut server FSServer) create_file(mut ctx Context) veb.Result {
	file_args := json.decode(herofs.FsFileArg, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for file creation')
	}

	mut file := server.fs_factory.fs_file.new(file_args) or {
		return ctx.server_error('Failed to create file: ${err}')
	}
	file = server.fs_factory.fs_file.set(file) or {
		return ctx.server_error('Failed to save file: ${err}')
	}

	return ctx.created(file, 'File created successfully')
}

// Update file
@['/api/files/:id'; put]
pub fn (mut server FSServer) update_file(mut ctx Context, id string) veb.Result {
	file_id := id.u32()
	if file_id == 0 {
		return ctx.request_error('Invalid file ID')
	}

	mut file := json.decode(herofs.FsFile, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for file update')
	}
	file.id = file_id

	file = server.fs_factory.fs_file.set(file) or {
		return ctx.server_error('Failed to update file: ${err}')
	}
	return ctx.success(file, 'File updated successfully')
}

// Delete file
@['/api/files/:id'; delete]
pub fn (mut server FSServer) delete_file(mut ctx Context, id string) veb.Result {
	file_id := id.u32()
	if file_id == 0 {
		return ctx.request_error('Invalid file ID')
	}

	server.fs_factory.fs_file.delete(file_id) or {
		return ctx.server_error('Failed to delete file: ${err}')
	}
	return ctx.success('', 'File deleted successfully')
}

// Add file to directory
@['/api/files/:id/add-to-directory'; post]
pub fn (mut server FSServer) add_file_to_directory(mut ctx Context, id string) veb.Result {
	file_id := id.u32()
	if file_id == 0 {
		return ctx.request_error('Invalid file ID')
	}

	dir_data := json.decode(map[string]u32, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for directory data')
	}
	dir_id := dir_data['dir_id'] or { return ctx.request_error('Missing dir_id field') }

	server.fs_factory.fs_file.add_to_directory(file_id, dir_id) or {
		return ctx.server_error('Failed to add file to directory: ${err}')
	}
	return ctx.success('', 'File added to directory successfully')
}

// Remove file from directory
@['/api/files/:id/remove-from-directory'; post]
pub fn (mut server FSServer) remove_file_from_directory(mut ctx Context, id string) veb.Result {
	file_id := id.u32()
	if file_id == 0 {
		return ctx.request_error('Invalid file ID')
	}

	dir_data := json.decode(map[string]u32, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for directory data')
	}
	dir_id := dir_data['dir_id'] or { return ctx.request_error('Missing dir_id field') }

	// Get the file and remove the directory from its directories list
	mut file := server.fs_factory.fs_file.get(file_id) or { return ctx.not_found('File not found') }
	file.directories = file.directories.filter(it != dir_id)
	server.fs_factory.fs_file.set(file) or {
		return ctx.server_error('Failed to update file directories: ${err}')
	}

	// Get the directory and remove the file from its files list
	mut dir := server.fs_factory.fs_dir.get(dir_id) or {
		return ctx.not_found('Directory not found')
	}
	dir.files = dir.files.filter(it != file_id)
	server.fs_factory.fs_dir.set(dir) or {
		return ctx.server_error('Failed to update directory files: ${err}')
	}

	return ctx.success('', 'File removed from directory successfully')
}

// Update file metadata
@['/api/files/:id/metadata'; post]
pub fn (mut server FSServer) update_file_metadata(mut ctx Context, id string) veb.Result {
	file_id := id.u32()
	if file_id == 0 {
		return ctx.request_error('Invalid file ID')
	}

	metadata := json.decode(map[string]string, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for metadata')
	}
	key := metadata['key'] or { return ctx.request_error('Missing key field') }
	value := metadata['value'] or { return ctx.request_error('Missing value field') }

	server.fs_factory.fs_file.update_metadata(file_id, key, value) or {
		return ctx.server_error('Failed to update file metadata: ${err}')
	}
	return ctx.success('', 'File metadata updated successfully')
}

// Update file accessed timestamp
@['/api/files/:id/accessed'; post]
pub fn (mut server FSServer) update_file_accessed(mut ctx Context, id string) veb.Result {
	file_id := id.u32()
	if file_id == 0 {
		return ctx.request_error('Invalid file ID')
	}

	server.fs_factory.fs_file.update_accessed(file_id) or {
		return ctx.server_error('Failed to update file accessed timestamp: ${err}')
	}
	return ctx.success('', 'File accessed timestamp updated successfully')
}

// List files by filesystem
@['/api/files/by-filesystem/:fs_id'; get]
pub fn (mut server FSServer) list_files_by_filesystem(mut ctx Context, fs_id string) veb.Result {
	filesystem_id := fs_id.u32()
	if filesystem_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	files := server.fs_factory.fs_file.list_by_filesystem(filesystem_id) or {
		return ctx.server_error('Failed to list files by filesystem: ${err}')
	}
	return ctx.success(files, 'Files by filesystem retrieved successfully')
}

// List files by directory
@['/api/files/by-directory/:dir_id'; get]
pub fn (mut server FSServer) list_files_by_directory(mut ctx Context, dir_id string) veb.Result {
	directory_id := dir_id.u32()
	if directory_id == 0 {
		return ctx.request_error('Invalid directory ID')
	}

	files := server.fs_factory.fs_file.list_by_directory(directory_id) or {
		return ctx.server_error('Failed to list files by directory: ${err}')
	}
	return ctx.success(files, 'Files retrieved successfully')
}

// List files by MIME type
@['/api/files/by-mime-type/:mime_type'; get]
pub fn (mut server FSServer) list_files_by_mime_type(mut ctx Context, mime_type string) veb.Result {
	if mime_type == '' {
		return ctx.request_error('Invalid MIME type')
	}

	// Convert string to MimeType enum
	mime_enum := match mime_type.to_lower() {
		'txt' { herofs.MimeType.txt }
		'json' { herofs.MimeType.json }
		'bin' { herofs.MimeType.bin }
		'html' { herofs.MimeType.html }
		'css' { herofs.MimeType.css }
		'js' { herofs.MimeType.js }
		'png' { herofs.MimeType.png }
		'jpg' { herofs.MimeType.jpg }
		'gif' { herofs.MimeType.gif }
		'pdf' { herofs.MimeType.pdf }
		'mp3' { herofs.MimeType.mp3 }
		'mp4' { herofs.MimeType.mp4 }
		'zip' { herofs.MimeType.zip }
		'xml' { herofs.MimeType.xml }
		'md' { herofs.MimeType.md }
		else { return ctx.request_error('Invalid MIME type: ${mime_type}') }
	}

	files := server.fs_factory.fs_file.list_by_mime_type(mime_enum) or {
		return ctx.server_error('Failed to list files by MIME type: ${err}')
	}
	return ctx.success(files, 'Files retrieved successfully')
}

// Get file by path
@['/api/files/by-path/:dir_id/:name'; get]
pub fn (mut server FSServer) get_file_by_path(mut ctx Context, dir_id string, name string) veb.Result {
	directory_id := dir_id.u32()
	if directory_id == 0 {
		return ctx.request_error('Invalid directory ID')
	}
	if name == '' {
		return ctx.request_error('Invalid file name')
	}

	file := server.fs_factory.fs_file.get_by_path(directory_id, name) or {
		return ctx.not_found('File not found')
	}
	return ctx.success(file, 'File retrieved successfully')
}
