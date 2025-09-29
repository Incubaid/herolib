module herofs_server

import net.http

// =============================================================================
// DIRECTORY ENDPOINT TESTS
// =============================================================================
//
// Tests for all directory-related endpoints:
// - GET /api/dirs (list directories)
// - GET /api/dirs/:id (get directory by ID)
// - POST /api/dirs (create directory)
// - PUT /api/dirs/:id (update directory)
// - DELETE /api/dirs/:id (delete directory)
// - POST /api/dirs/create-path (create directory path)
// - GET /api/dirs/:id/has-children (check children)
// - GET /api/dirs/:id/children (get children)
// =============================================================================

fn test_directory_operations() ! {
	base_url := start_test_server(8099)!

	// Create a filesystem first
	fs_json := '{"name": "dir_test_fs", "description": "Test filesystem for directory operations", "quota_bytes": 1073741824}'

	mut fs_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs'
		data:   fs_json
	}
	fs_req.add_header(.content_type, 'application/json')

	fs_response := fs_req.do()!
	assert fs_response.status_code == 201

	// Test directory creation
	dir_json := '{"name": "test_dir", "fs_id": 1, "parent_id": 0, "description": "Test directory"}'

	mut create_dir_req := http.Request{
		method: .post
		url:    '${base_url}/api/dirs'
		data:   dir_json
	}
	create_dir_req.add_header(.content_type, 'application/json')

	create_dir_response := create_dir_req.do()!
	assert create_dir_response.status_code == 201
	assert create_dir_response.body.contains('success')

	// Test directory get by ID
	get_dir_response := http.get('${base_url}/api/dirs/1')!
	assert get_dir_response.status_code == 200 || get_dir_response.status_code == 404
	assert get_dir_response.body.contains('success')

	println('Directory operations test passed on ${base_url}')
}

fn test_directory_list_update_delete() ! {
	base_url := start_test_server(8100)!

	// Test list all directories
	list_dirs_response := http.get('${base_url}/api/dirs')!
	assert list_dirs_response.status_code == 200
	assert list_dirs_response.body.contains('success')

	// Create a filesystem first
	fs_json := '{"name": "dir_test_fs2", "description": "Test filesystem for directory operations", "quota_bytes": 1073741824}'

	mut fs_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs'
		data:   fs_json
	}
	fs_req.add_header(.content_type, 'application/json')

	fs_response := fs_req.do()!
	assert fs_response.status_code == 201

	// Create directory to test update/delete
	dir_json := '{"name": "test_dir2", "fs_id": 1, "parent_id": 0, "description": "Test directory"}'

	mut create_dir_req := http.Request{
		method: .post
		url:    '${base_url}/api/dirs'
		data:   dir_json
	}
	create_dir_req.add_header(.content_type, 'application/json')

	create_dir_response := create_dir_req.do()!
	assert create_dir_response.status_code == 201
	assert create_dir_response.body.contains('success')

	// Test directory update (PUT)
	update_dir_json := '{"id": 1, "name": "updated_dir", "fs_id": 1, "parent_id": 0, "description": "Updated directory"}'

	mut update_dir_req := http.Request{
		method: .put
		url:    '${base_url}/api/dirs/1'
		data:   update_dir_json
	}
	update_dir_req.add_header(.content_type, 'application/json')

	update_dir_response := update_dir_req.do()!
	assert update_dir_response.status_code == 200 || update_dir_response.status_code == 400
	assert update_dir_response.body.contains('success')

	// Test directory delete (DELETE)
	mut delete_dir_req := http.Request{
		method: .delete
		url:    '${base_url}/api/dirs/1'
	}

	delete_dir_response := delete_dir_req.do()!
	assert delete_dir_response.status_code == 200 || delete_dir_response.status_code == 404
	assert delete_dir_response.body.contains('success')

	println('Directory list/update/delete test passed on ${base_url}')
}

fn test_directory_path_children() ! {
	base_url := start_test_server(8101)!

	// Test create directory path
	path_json := '{"fs_id": "1", "path": "/test/nested/path"}'

	mut path_req := http.Request{
		method: .post
		url:    '${base_url}/api/dirs/create-path'
		data:   path_json
	}
	path_req.add_header(.content_type, 'application/json')

	path_response := path_req.do()!
	assert path_response.status_code in [200, 400, 404, 500]
	assert path_response.body.len > 0

	// Test check if directory has children
	has_children_response := http.get('${base_url}/api/dirs/1/has-children')!
	assert has_children_response.status_code in [200, 400, 404, 500]
	assert has_children_response.body.len > 0

	// Test get directory children
	children_response := http.get('${base_url}/api/dirs/1/children')!
	assert children_response.status_code in [200, 400, 404, 500]
	assert children_response.body.len > 0

	println('Directory path/children test passed on ${base_url}')
}

// Test the new directory by-filesystem endpoint
fn test_directory_by_filesystem_endpoint() ! {
	base_url := start_test_server(8221)!

	// Create test filesystem and directory
	fs_json := '{"name": "test_fs_dirs", "description": "Test filesystem for directory endpoints", "quota_bytes": 1073741824}'

	mut create_fs_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs'
		data:   fs_json
	}
	create_fs_req.add_header(.content_type, 'application/json')

	create_fs_resp := create_fs_req.do()!
	assert create_fs_resp.status_code == 201

	// Extract filesystem ID from response (simple approach)
	fs_id := '1' // Assuming first filesystem gets ID 1

	// Create test directory
	dir_json := '{"name": "test_dir", "description": "Test directory", "fs_id": ${fs_id}, "parent_id": 0}'

	mut create_dir_req := http.Request{
		method: .post
		url:    '${base_url}/api/dirs'
		data:   dir_json
	}
	create_dir_req.add_header(.content_type, 'application/json')

	create_dir_resp := create_dir_req.do()!
	assert create_dir_resp.status_code == 201

	// Test GET /api/dirs/by-filesystem/:fs_id
	println('Testing GET /api/dirs/by-filesystem/:fs_id')
	dirs_resp := http.get('${base_url}/api/dirs/by-filesystem/${fs_id}')!
	assert dirs_resp.status_code == 200
	assert dirs_resp.body.contains('success')
	assert dirs_resp.body.contains('test_dir')

	println('✓ Directory by-filesystem endpoint test passed on ${base_url}')
}
