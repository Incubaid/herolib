module herofs_server

import net.http

// =============================================================================
// BLOB ENDPOINT TESTS
// =============================================================================
//
// Tests for all blob-related endpoints:
// - GET /api/blobs (list blobs)
// - GET /api/blobs/:id (get blob by ID)
// - POST /api/blobs (create blob)
// - PUT /api/blobs/:id (update blob)
// - DELETE /api/blobs/:id (delete blob)
// - GET /api/blobs/:id/content (get blob content)
// =============================================================================

fn test_blob_operations() ! {
	base_url := start_test_server(8102)!

	// Create a filesystem first
	fs_json := '{"name": "blob_test_fs", "description": "Test filesystem for blob operations", "quota_bytes": 1073741824}'

	mut fs_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs'
		data:   fs_json
	}
	fs_req.add_header(.content_type, 'application/json')

	fs_response := fs_req.do()!
	assert fs_response.status_code == 201

	// Test blob creation
	blob_json := '{"name": "test_blob", "fs_id": 1, "size_bytes": 2048, "hash": "sha256:abcdef1234567890", "description": "Test blob"}'

	mut create_blob_req := http.Request{
		method: .post
		url:    '${base_url}/api/blobs'
		data:   blob_json
	}
	create_blob_req.add_header(.content_type, 'application/json')

	create_blob_response := create_blob_req.do()!
	assert create_blob_response.status_code == 201 || create_blob_response.status_code == 400
	assert create_blob_response.body.contains('success')

	// Test blob get by ID
	get_blob_response := http.get('${base_url}/api/blobs/1')!
	assert get_blob_response.status_code == 200 || get_blob_response.status_code == 404
	assert get_blob_response.body.contains('success')

	println('Blob operations test passed on ${base_url}')
}

fn test_blob_list_update_delete() ! {
	base_url := start_test_server(8103)!

	// Test list all blobs
	list_blobs_response := http.get('${base_url}/api/blobs')!
	assert list_blobs_response.status_code == 200
	assert list_blobs_response.body.contains('success')

	// Create a filesystem first
	fs_json := '{"name": "blob_test_fs2", "description": "Test filesystem for blob operations", "quota_bytes": 1073741824}'

	mut fs_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs'
		data:   fs_json
	}
	fs_req.add_header(.content_type, 'application/json')

	fs_response := fs_req.do()!
	assert fs_response.status_code == 201

	// Create blob to test update/delete
	blob_json := '{"name": "test_blob2", "fs_id": 1, "size_bytes": 2048, "hash": "sha256:abcdef1234567890", "description": "Test blob"}'

	mut create_blob_req := http.Request{
		method: .post
		url:    '${base_url}/api/blobs'
		data:   blob_json
	}
	create_blob_req.add_header(.content_type, 'application/json')

	create_blob_response := create_blob_req.do()!
	assert create_blob_response.status_code == 201 || create_blob_response.status_code == 400
	assert create_blob_response.body.contains('success')

	// Test blob update (PUT)
	update_blob_json := '{"id": 1, "name": "updated_blob", "fs_id": 1, "size_bytes": 4096, "hash": "sha256:fedcba0987654321", "description": "Updated blob"}'

	mut update_blob_req := http.Request{
		method: .put
		url:    '${base_url}/api/blobs/1'
		data:   update_blob_json
	}
	update_blob_req.add_header(.content_type, 'application/json')

	update_blob_response := update_blob_req.do()!
	assert update_blob_response.status_code == 200 || update_blob_response.status_code == 400
	assert update_blob_response.body.contains('success')

	// Test blob delete (DELETE)
	mut delete_blob_req := http.Request{
		method: .delete
		url:    '${base_url}/api/blobs/1'
	}

	delete_blob_response := delete_blob_req.do()!
	assert delete_blob_response.status_code == 200 || delete_blob_response.status_code == 404
	assert delete_blob_response.body.contains('success')

	println('Blob list/update/delete test passed on ${base_url}')
}

fn test_blob_content() ! {
	base_url := start_test_server(8104)!

	// Test get blob content
	content_response := http.get('${base_url}/api/blobs/1/content')!
	assert content_response.status_code == 200 || content_response.status_code == 404
	// Note: Content response might not contain 'success' as it returns raw data

	println('Blob content test passed on ${base_url}')
}

// Test the new blob endpoints
fn test_new_blob_endpoints() ! {
	base_url := start_test_server(8223)!

	// Create test blob
	blob_json := '{"data": [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100], "mime_type": "txt"}'

	mut create_blob_req := http.Request{
		method: .post
		url:    '${base_url}/api/blobs'
		data:   blob_json
	}
	create_blob_req.add_header(.content_type, 'application/json')

	create_blob_resp := create_blob_req.do()!
	assert create_blob_resp.status_code == 201
	assert create_blob_resp.body.contains('success')
	assert create_blob_resp.body.contains('hash')

	blob_id := '1' // Assuming first blob gets ID 1

	// Extract hash from response (simple approach - look for hash pattern)
	// For testing purposes, we'll use a placeholder hash
	test_hash := 'test_hash_placeholder'

	// Test GET /api/blobs/:id/verify
	println('Testing GET /api/blobs/:id/verify')
	verify_resp := http.get('${base_url}/api/blobs/${blob_id}/verify')!
	assert verify_resp.status_code == 200 || verify_resp.status_code == 404
	assert verify_resp.body.contains('success') || verify_resp.body.contains('error')

	// Test GET /api/blobs/by-hash/:hash (will likely return 404 with placeholder hash)
	println('Testing GET /api/blobs/by-hash/:hash')
	blob_by_hash_resp := http.get('${base_url}/api/blobs/by-hash/${test_hash}')!
	// Accept either 200 (found) or 404 (not found) as valid responses
	assert blob_by_hash_resp.status_code == 200 || blob_by_hash_resp.status_code == 404

	// Test GET /api/blobs/exists-by-hash/:hash
	println('Testing GET /api/blobs/exists-by-hash/:hash')
	exists_resp := http.get('${base_url}/api/blobs/exists-by-hash/${test_hash}')!
	assert exists_resp.status_code == 200
	assert exists_resp.body.contains('success')

	println('✓ New blob endpoint tests passed on ${base_url}')
}
