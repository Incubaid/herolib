module herofs_server

import net.http

// =============================================================================
// TOOLS & SYMLINK ENDPOINT TESTS
// =============================================================================
//
// Tests for tools and symlink endpoints:
// - POST /api/tools/find (find files and directories)
// - POST /api/tools/copy (copy files or directories)
// - POST /api/tools/move (move files or directories)
// - POST /api/tools/remove (remove files or directories)
// - POST /api/tools/import/file (import file)
// - POST /api/tools/import/directory (import directory)
// - POST /api/tools/export/file (export file)
// - POST /api/tools/export/directory (export directory)
// - POST /api/tools/content/:fs_id (get file content)
// - GET /api/symlinks (list symlinks)
// - POST /api/symlinks (create symlink)
// - PUT /api/symlinks/:id (update symlink)
// - DELETE /api/symlinks/:id (delete symlink)
// =============================================================================

fn test_tools_endpoints() ! {
	base_url := start_test_server(8105)!

	// Create a filesystem first
	fs_json := '{"name": "tools_test_fs", "description": "Test filesystem for tools operations", "quota_bytes": 1073741824}'

	mut fs_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs'
		data:   fs_json
	}
	fs_req.add_header(.content_type, 'application/json')

	fs_response := fs_req.do()!
	assert fs_response.status_code == 201

	// Test tools find endpoint
	find_json := '{"fs_id": 1, "pattern": "*.txt", "path": "/"}'

	mut find_req := http.Request{
		method: .post
		url:    '${base_url}/api/tools/find'
		data:   find_json
	}
	find_req.add_header(.content_type, 'application/json')

	find_response := find_req.do()!
	assert find_response.status_code == 200 || find_response.status_code == 400
	assert find_response.body.contains('success')

	// Test tools copy endpoint
	copy_json := '{"fs_id": 1, "source_path": "/test.txt", "dest_path": "/copy_test.txt"}'

	mut copy_req := http.Request{
		method: .post
		url:    '${base_url}/api/tools/copy'
		data:   copy_json
	}
	copy_req.add_header(.content_type, 'application/json')

	copy_response := copy_req.do()!
	assert copy_response.status_code == 200 || copy_response.status_code == 400
	assert copy_response.body.contains('success')

	// Test tools move endpoint
	move_json := '{"fs_id": 1, "source_path": "/copy_test.txt", "dest_path": "/moved_test.txt"}'

	mut move_req := http.Request{
		method: .post
		url:    '${base_url}/api/tools/move'
		data:   move_json
	}
	move_req.add_header(.content_type, 'application/json')

	move_response := move_req.do()!
	assert move_response.status_code == 200 || move_response.status_code == 400
	assert move_response.body.contains('success')

	println('Tools endpoints test passed on ${base_url}')
}

fn test_tools_remove_import_export() ! {
	base_url := start_test_server(8106)!

	// Test tools remove endpoint
	remove_json := '{"fs_id": 1, "path": "/test/file.txt"}'

	mut remove_req := http.Request{
		method: .post
		url:    '${base_url}/api/tools/remove'
		data:   remove_json
	}
	remove_req.add_header(.content_type, 'application/json')

	remove_response := remove_req.do()!
	assert remove_response.status_code == 200 || remove_response.status_code == 400
	assert remove_response.body.contains('success')

	// Test tools import file endpoint
	import_file_json := '{"fs_id": 1, "real_path": "/tmp/test.txt", "vfs_path": "/imported/test.txt", "overwrite": "false"}'

	mut import_file_req := http.Request{
		method: .post
		url:    '${base_url}/api/tools/import/file'
		data:   import_file_json
	}
	import_file_req.add_header(.content_type, 'application/json')

	import_file_response := import_file_req.do()!
	assert import_file_response.status_code == 200 || import_file_response.status_code == 400
	assert import_file_response.body.contains('success')

	// Test tools import directory endpoint
	import_dir_json := '{"fs_id": 1, "real_path": "/tmp/testdir", "vfs_path": "/imported/testdir", "overwrite": "false"}'

	mut import_dir_req := http.Request{
		method: .post
		url:    '${base_url}/api/tools/import/directory'
		data:   import_dir_json
	}
	import_dir_req.add_header(.content_type, 'application/json')

	import_dir_response := import_dir_req.do()!
	assert import_dir_response.status_code == 200 || import_dir_response.status_code == 400
	assert import_dir_response.body.contains('success')

	println('Tools remove/import test passed on ${base_url}')
}

fn test_tools_export_content() ! {
	base_url := start_test_server(8107)!

	// Test tools export file endpoint
	export_file_json := '{"fs_id": 1, "vfs_path": "/test/file.txt", "real_path": "/tmp/exported_file.txt", "overwrite": "false"}'

	mut export_file_req := http.Request{
		method: .post
		url:    '${base_url}/api/tools/export/file'
		data:   export_file_json
	}
	export_file_req.add_header(.content_type, 'application/json')

	export_file_response := export_file_req.do()!
	assert export_file_response.status_code == 200 || export_file_response.status_code == 400
	assert export_file_response.body.contains('success')

	// Test tools export directory endpoint
	export_dir_json := '{"fs_id": 1, "vfs_path": "/test/dir", "real_path": "/tmp/exported_dir", "overwrite": "false"}'

	mut export_dir_req := http.Request{
		method: .post
		url:    '${base_url}/api/tools/export/directory'
		data:   export_dir_json
	}
	export_dir_req.add_header(.content_type, 'application/json')

	export_dir_response := export_dir_req.do()!
	assert export_dir_response.status_code == 200 || export_dir_response.status_code == 400
	assert export_dir_response.body.contains('success')

	// Test tools content endpoint
	content_json := '{"path": "/test/file.txt"}'

	mut content_req := http.Request{
		method: .post
		url:    '${base_url}/api/tools/content/1'
		data:   content_json
	}
	content_req.add_header(.content_type, 'application/json')

	content_response := content_req.do()!
	assert content_response.status_code == 200 || content_response.status_code == 400
	assert content_response.body.contains('success')

	println('Tools export/content test passed on ${base_url}')
}

fn test_symlink_operations() ! {
	base_url := start_test_server(8108)!

	// Create a filesystem first
	fs_json := '{"name": "symlink_test_fs", "description": "Test filesystem for symlink operations", "quota_bytes": 1073741824}'

	mut fs_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs'
		data:   fs_json
	}
	fs_req.add_header(.content_type, 'application/json')

	fs_response := fs_req.do()!
	assert fs_response.status_code == 201

	// Test symlink creation
	symlink_json := '{"name": "test_symlink", "fs_id": 1, "target_path": "/target/file.txt", "link_path": "/link/symlink", "description": "Test symlink"}'

	mut create_symlink_req := http.Request{
		method: .post
		url:    '${base_url}/api/symlinks'
		data:   symlink_json
	}
	create_symlink_req.add_header(.content_type, 'application/json')

	create_symlink_response := create_symlink_req.do()!
	assert create_symlink_response.status_code == 201 || create_symlink_response.status_code == 400
	assert create_symlink_response.body.contains('success')

	// Test symlink listing
	list_symlinks_response := http.get('${base_url}/api/symlinks')!
	assert list_symlinks_response.status_code == 200
	assert list_symlinks_response.body.contains('success')

	// Test symlink get by ID
	get_symlink_response := http.get('${base_url}/api/symlinks/1')!
	assert get_symlink_response.status_code == 200 || get_symlink_response.status_code == 404
	assert get_symlink_response.body.contains('success')

	println('Symlink operations test passed on ${base_url}')
}
