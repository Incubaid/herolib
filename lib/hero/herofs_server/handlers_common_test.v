module herofs_server

import net.http

// =============================================================================
// COMMON ENDPOINT TESTS
// =============================================================================
//
// Tests for common endpoints and functionality:
// - GET /health (health check)
// - GET /api (API information)
// - OPTIONS /* (CORS preflight)
// - Error handling (404, 400 responses)
// - Directory listing via tools
// =============================================================================

fn test_health_check() ! {
	base_url := start_test_server(8094)!

	health_response := http.get('${base_url}/health')!
	assert health_response.status_code == 200
	assert health_response.body.len > 0
	assert health_response.body.contains('success')

	println('Health check test passed on ${base_url}')
}

fn test_api_info_endpoint() ! {
	base_url := start_test_server(8095)!

	// Test API info endpoint
	api_response := http.get('${base_url}/api')!
	assert api_response.status_code == 200
	assert api_response.body.contains('success')
	assert api_response.body.contains('HeroFS')

	println('API info endpoint test passed on ${base_url}')
}

fn test_cors_functionality() ! {
	base_url := start_test_server(8096)!

	// Test CORS preflight request
	mut cors_req := http.Request{
		method: .options
		url:    '${base_url}/api/fs'
	}
	cors_req.add_header(.origin, 'http://localhost:3000')
	cors_req.add_header(.access_control_request_method, 'POST')

	cors_response := cors_req.do()!
	assert cors_response.status_code == 200 || cors_response.status_code == 204
	// CORS headers should be present in response

	println('CORS functionality test passed on ${base_url}')
}

fn test_error_handling() ! {
	base_url := start_test_server(8097)!

	// Test 404 error for non-existent endpoint
	not_found_response := http.get('${base_url}/api/nonexistent')!
	assert not_found_response.status_code == 404
	assert not_found_response.body.contains('Not Found')

	// Test 404 error for non-existent resource
	not_found_fs_response := http.get('${base_url}/api/fs/99999')!
	assert not_found_fs_response.status_code == 404 || not_found_fs_response.status_code == 400
	assert not_found_fs_response.body.len > 0

	// Test 400 error for invalid JSON
	mut bad_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs'
		data:   'invalid json'
	}
	bad_req.add_header(.content_type, 'application/json')

	bad_response := bad_req.do()!
	assert bad_response.status_code == 400 || bad_response.status_code == 500
	assert bad_response.body.len > 0

	println('Error handling test passed on ${base_url}')
}

fn test_list_directory() ! {
	base_url := start_test_server(8098)!

	// Create a filesystem first
	fs_json := '{"name": "list_test_fs", "description": "Test filesystem for directory listing", "quota_bytes": 1073741824}'

	mut fs_req := http.Request{
		method: .post
		url:    '${base_url}/api/fs'
		data:   fs_json
	}
	fs_req.add_header(.content_type, 'application/json')

	fs_response := fs_req.do()!
	assert fs_response.status_code == 201
	assert fs_response.body.contains('success')

	// Test directory listing via tools endpoint
	list_json := '{"fs_id": 1, "path": "/"}'

	mut list_req := http.Request{
		method: .post
		url:    '${base_url}/api/tools/list'
		data:   list_json
	}
	list_req.add_header(.content_type, 'application/json')

	list_response := list_req.do()!
	assert list_response.status_code == 200 || list_response.status_code == 400
	assert list_response.body.contains('success')

	println('Directory listing test passed on ${base_url}')
}
