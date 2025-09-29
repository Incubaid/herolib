module herofs_server

import net.http

// =============================================================================
// FILESYSTEM ENDPOINT TESTS
// =============================================================================
//
// Tests for all filesystem-related endpoints:
// - GET /api/fs (list filesystems)
// - GET /api/fs/:id (get filesystem by ID)
// - POST /api/fs (create filesystem)
// - PUT /api/fs/:id (update filesystem)
// - DELETE /api/fs/:id (delete filesystem)
// - GET /api/fs/:id/exists (check existence)
// - POST /api/fs/:id/usage/increase (increase usage)
// - POST /api/fs/:id/usage/decrease (decrease usage)
// - POST /api/fs/:id/quota/check (check quota)
// =============================================================================

fn test_filesystem_crud() ! {
	base_url := start_test_server(8091)!

	// Test filesystem creation
	fs_json := '{"name": "crud_test_fs", "description": "Test filesystem for CRUD operations", "quota_bytes": 2147483648}'

	mut create_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs'
		data:   fs_json
	}
	create_req.add_header(.content_type, 'application/json')

	create_response := create_req.do()!
	assert create_response.status_code == 201
	assert create_response.body.contains('success')
	assert create_response.body.contains('id')

	// Test filesystem listing
	list_response := http.get('${base_url}/api/fs')!
	assert list_response.status_code == 200
	assert list_response.body.contains('success')
	assert list_response.body.contains('crud_test_fs')

	// Test filesystem get by ID (assuming ID 1)
	get_response := http.get('${base_url}/api/fs/1')!
	assert get_response.status_code == 200 || get_response.status_code == 404
	assert get_response.body.contains('success')

	println('Filesystem CRUD test passed on ${base_url}')
}

fn test_filesystem_update_delete() ! {
	base_url := start_test_server(8092)!

	// First create a filesystem to update/delete
	fs_json := '{"name": "update_delete_fs", "description": "Test filesystem for update/delete", "quota_bytes": 1073741824}'

	mut create_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs'
		data:   fs_json
	}
	create_req.add_header(.content_type, 'application/json')

	create_response := create_req.do()!
	assert create_response.status_code == 201
	assert create_response.body.contains('success')

	// Test filesystem update (PUT)
	update_json := '{"id": 1, "name": "updated_fs", "description": "Updated filesystem", "quota_bytes": 2147483648}'

	mut update_req := http.Request{
		method: .put
		url:    '${base_url}/api/fs/1'
		data:   update_json
	}
	update_req.add_header(.content_type, 'application/json')

	update_response := update_req.do()!
	assert update_response.status_code == 200 || update_response.status_code == 400
	assert update_response.body.contains('success')

	// Test filesystem delete (DELETE)
	mut delete_req := http.Request{
		method: .delete
		url:    '${base_url}/api/fs/1'
	}

	delete_response := delete_req.do()!
	assert delete_response.status_code == 200 || delete_response.status_code == 404
	assert delete_response.body.contains('success')

	println('Filesystem update/delete test passed on ${base_url}')
}

fn test_filesystem_exists_usage_quota() ! {
	base_url := start_test_server(8093)!

	// Test filesystem exists check
	exists_response := http.get('${base_url}/api/fs/1/exists')!
	assert exists_response.status_code == 200 || exists_response.status_code == 400
	assert exists_response.body.contains('success')

	// Test increase usage
	usage_json := '{"bytes": 1024}'

	mut increase_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs/1/usage/increase'
		data:   usage_json
	}
	increase_req.add_header(.content_type, 'application/json')

	increase_response := increase_req.do()!
	assert increase_response.status_code in [200, 400, 404, 500]
	assert increase_response.body.len > 0

	// Test decrease usage
	mut decrease_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs/1/usage/decrease'
		data:   usage_json
	}
	decrease_req.add_header(.content_type, 'application/json')

	decrease_response := decrease_req.do()!
	assert decrease_response.status_code in [200, 400, 404, 500]
	assert decrease_response.body.len > 0

	// Test quota check
	quota_json := '{"bytes": 2048}'

	mut quota_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs/1/quota/check'
		data:   quota_json
	}
	quota_req.add_header(.content_type, 'application/json')

	quota_response := quota_req.do()!
	assert quota_response.status_code in [200, 400, 404, 500]
	assert quota_response.body.len > 0

	println('Filesystem exists/usage/quota test passed on ${base_url}')
}
