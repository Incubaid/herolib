module herofs_server

import veb
import json
import incubaid.herolib.hero.herofs

// =============================================================================
// FILESYSTEM TOOLS ENDPOINTS
// =============================================================================

// Find files and directories
@['/api/tools/find'; post]
pub fn (mut server FSServer) find_files(mut ctx Context) veb.Result {
	find_data := json.decode(map[string]string, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for find operation')
	}

	fs_id := find_data['fs_id'] or { return ctx.request_error('Missing fs_id field') }.u32()
	path := find_data['path'] or { return ctx.request_error('Missing path field') }

	// Parse optional parameters
	mut recursive := true
	mut include_patterns := []string{}
	mut exclude_patterns := []string{}

	if 'recursive' in find_data {
		recursive = find_data['recursive'] == 'true'
	}
	if 'include_patterns' in find_data {
		patterns_str := find_data['include_patterns'] or { '' }
		if patterns_str.len > 0 {
			include_patterns = patterns_str.split(',').map(it.trim_space())
		}
	}
	if 'exclude_patterns' in find_data {
		patterns_str := find_data['exclude_patterns'] or { '' }
		if patterns_str.len > 0 {
			exclude_patterns = patterns_str.split(',').map(it.trim_space())
		}
	}

	// Get filesystem instance
	mut fs := server.fs_factory.fs.get(fs_id) or {
		return ctx.request_error('Filesystem not found')
	}

	results := fs.find(path, herofs.FindOptions{
		recursive:        recursive
		include_patterns: include_patterns
		exclude_patterns: exclude_patterns
	}) or { return ctx.server_error('Failed to perform find operation: ${err}') }
	return ctx.success(results, 'Find operation completed successfully')
}

// Copy files or directories
@['/api/tools/copy'; post]
pub fn (mut server FSServer) copy_files(mut ctx Context) veb.Result {
	copy_data := json.decode(map[string]string, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for copy operation')
	}

	fs_id := copy_data['fs_id'] or { return ctx.request_error('Missing fs_id field') }.u32()
	source_path := copy_data['source_path'] or {
		return ctx.request_error('Missing source_path field')
	}
	dest_path := copy_data['dest_path'] or { return ctx.request_error('Missing dest_path field') }

	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	// Get filesystem instance
	mut fs := server.fs_factory.fs.get(fs_id) or {
		return ctx.request_error('Filesystem not found')
	}

	fs.cp(source_path, dest_path, herofs.FindOptions{ recursive: false }, herofs.CopyOptions{
		recursive:  true
		overwrite:  false
		copy_blobs: true
	}) or { return ctx.server_error('Failed to copy: ${err}') }
	return ctx.success('', 'Copy operation completed successfully')
}

// Move files or directories
@['/api/tools/move'; post]
pub fn (mut server FSServer) move_files(mut ctx Context) veb.Result {
	move_data := json.decode(map[string]string, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for move operation')
	}

	fs_id := move_data['fs_id'] or { return ctx.request_error('Missing fs_id field') }.u32()
	source_path := move_data['source_path'] or {
		return ctx.request_error('Missing source_path field')
	}
	dest_path := move_data['dest_path'] or { return ctx.request_error('Missing dest_path field') }

	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	// Get filesystem instance
	mut fs := server.fs_factory.fs.get(fs_id) or {
		return ctx.request_error('Filesystem not found')
	}

	fs.mv(source_path, dest_path) or { return ctx.server_error('Failed to move: ${err}') }
	return ctx.success('', 'Move operation completed successfully')
}

// Remove files or directories
@['/api/tools/remove'; post]
pub fn (mut server FSServer) remove_files(mut ctx Context) veb.Result {
	remove_data := json.decode(map[string]string, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for remove operation')
	}

	fs_id := remove_data['fs_id'] or { return ctx.request_error('Missing fs_id field') }.u32()
	path := remove_data['path'] or { return ctx.request_error('Missing path field') }

	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	// Get filesystem instance
	mut fs := server.fs_factory.fs.get(fs_id) or {
		return ctx.request_error('Filesystem not found')
	}

	fs.rm(path, herofs.FindOptions{ recursive: false }, herofs.RemoveOptions{
		recursive:    true
		delete_blobs: false
		force:        false
	}) or { return ctx.server_error('Failed to remove: ${err}') }
	return ctx.success('', 'Remove operation completed successfully')
}

// List directory contents
@['/api/tools/list'; post]
pub fn (mut server FSServer) list_directory(mut ctx Context) veb.Result {
	list_data := json.decode(map[string]string, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for list operation')
	}

	fs_id := list_data['fs_id'] or { return ctx.request_error('Missing fs_id field') }.u32()
	path := list_data['path'] or { return ctx.request_error('Missing path field') }

	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	// Get filesystem instance
	mut fs := server.fs_factory.fs.get(fs_id) or {
		return ctx.request_error('Filesystem not found')
	}

	// Use find to list directory contents
	contents := fs.find(path, herofs.FindOptions{ recursive: false }) or {
		return ctx.server_error('Failed to list directory: ${err}')
	}
	return ctx.success(contents, 'Directory listing completed successfully')
}

// =============================================================================
// IMPORT/EXPORT ENDPOINTS
// =============================================================================

// Import file from real filesystem
@['/api/tools/import/file'; post]
pub fn (mut server FSServer) import_file(mut ctx Context) veb.Result {
	import_data := json.decode(map[string]string, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for import operation')
	}

	fs_id := import_data['fs_id'] or { return ctx.request_error('Missing fs_id field') }.u32()
	real_path := import_data['real_path'] or { return ctx.request_error('Missing real_path field') }
	vfs_path := import_data['vfs_path'] or { return ctx.request_error('Missing vfs_path field') }
	overwrite := import_data['overwrite'] or { 'false' } == 'true'

	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	// Get filesystem instance
	mut fs := server.fs_factory.fs.get(fs_id) or {
		return ctx.request_error('Filesystem not found')
	}

	fs.import(real_path, vfs_path, herofs.ImportOptions{
		recursive: false
		overwrite: overwrite
	}) or { return ctx.server_error('Failed to import file: ${err}') }
	return ctx.success('', 'File imported successfully')
}

// Import directory from real filesystem
@['/api/tools/import/directory'; post]
pub fn (mut server FSServer) import_directory(mut ctx Context) veb.Result {
	import_data := json.decode(map[string]string, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for import operation')
	}

	fs_id := import_data['fs_id'] or { return ctx.request_error('Missing fs_id field') }.u32()
	real_path := import_data['real_path'] or { return ctx.request_error('Missing real_path field') }
	vfs_path := import_data['vfs_path'] or { return ctx.request_error('Missing vfs_path field') }
	overwrite := import_data['overwrite'] or { 'false' } == 'true'

	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	// Get filesystem instance
	mut fs := server.fs_factory.fs.get(fs_id) or {
		return ctx.request_error('Filesystem not found')
	}

	fs.import(real_path, vfs_path, herofs.ImportOptions{
		recursive: true
		overwrite: overwrite
	}) or { return ctx.server_error('Failed to import directory: ${err}') }
	return ctx.success('', 'Directory imported successfully')
}

// Export file to real filesystem
@['/api/tools/export/file'; post]
pub fn (mut server FSServer) export_file(mut ctx Context) veb.Result {
	export_data := json.decode(map[string]string, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for export operation')
	}

	fs_id := export_data['fs_id'] or { return ctx.request_error('Missing fs_id field') }.u32()
	vfs_path := export_data['vfs_path'] or { return ctx.request_error('Missing vfs_path field') }
	real_path := export_data['real_path'] or { return ctx.request_error('Missing real_path field') }
	overwrite := export_data['overwrite'] or { 'false' } == 'true'

	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	// Get filesystem instance
	mut fs := server.fs_factory.fs.get(fs_id) or {
		return ctx.request_error('Filesystem not found')
	}

	fs.export(vfs_path, real_path, herofs.ExportOptions{
		recursive: false
		overwrite: overwrite
	}) or { return ctx.server_error('Failed to export file: ${err}') }
	return ctx.success('', 'File exported successfully')
}

// Export directory to real filesystem
@['/api/tools/export/directory'; post]
pub fn (mut server FSServer) export_directory(mut ctx Context) veb.Result {
	export_data := json.decode(map[string]string, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for export operation')
	}

	fs_id := export_data['fs_id'] or { return ctx.request_error('Missing fs_id field') }.u32()
	vfs_path := export_data['vfs_path'] or { return ctx.request_error('Missing vfs_path field') }
	real_path := export_data['real_path'] or { return ctx.request_error('Missing real_path field') }
	overwrite := export_data['overwrite'] or { 'false' } == 'true'

	if fs_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	// Get filesystem instance
	mut fs := server.fs_factory.fs.get(fs_id) or {
		return ctx.request_error('Filesystem not found')
	}

	fs.export(vfs_path, real_path, herofs.ExportOptions{
		recursive: true
		overwrite: overwrite
	}) or { return ctx.server_error('Failed to export directory: ${err}') }
	return ctx.success('', 'Directory exported successfully')
}

// Get file content as text
@['/api/tools/content/:fs_id'; post]
pub fn (mut server FSServer) get_file_content(mut ctx Context, fs_id string) veb.Result {
	filesystem_id := fs_id.u32()
	if filesystem_id == 0 {
		return ctx.request_error('Invalid filesystem ID')
	}

	content_data := json.decode(map[string]string, ctx.req.data) or {
		return ctx.request_error('Invalid JSON format for content request')
	}
	path := content_data['path'] or { return ctx.request_error('Missing path field') }

	// Get filesystem instance
	mut fs := server.fs_factory.fs.get(filesystem_id) or {
		return ctx.request_error('Filesystem not found')
	}

	// Find the file by path
	file_results := fs.find(path, herofs.FindOptions{ recursive: false }) or {
		return ctx.server_error('Failed to find file: ${err}')
	}

	if file_results.len == 0 {
		return ctx.request_error('File not found at path: ${path}')
	}

	file_result := file_results[0]
	if file_result.result_type != .file {
		return ctx.request_error('Path does not point to a file: ${path}')
	}

	// Get the file and its content
	file := server.fs_factory.fs_file.get(file_result.id) or {
		return ctx.server_error('Failed to get file: ${err}')
	}

	mut content := ''
	for blob_id in file.blobs {
		blob := server.fs_factory.fs_blob.get(blob_id) or { continue }
		content += blob.data.bytestr()
	}
	return ctx.success(content, 'File content retrieved successfully')
}
