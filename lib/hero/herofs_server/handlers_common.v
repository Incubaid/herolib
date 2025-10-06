module herofs_server

import veb

// Standard API response structure
pub struct APIResponse[T] {
pub:
	success bool
	data    T
	message string
	error   string
}

// Error response structure
pub struct ErrorResponse {
pub:
	success bool
	error   string
	message string
}

// Helper function to create success response
pub fn success_response[T](data T, message string) APIResponse[T] {
	return APIResponse[T]{
		success: true
		data:    data
		message: message
		error:   ''
	}
}

// Helper function to create error response
pub fn error_response(error string, message string) ErrorResponse {
	return ErrorResponse{
		error:   error
		message: message
	}
}

// Context extension methods for common HTTP responses
pub fn (mut ctx Context) success[T](data T, message string) veb.Result {
	return ctx.json(success_response(data, message))
}

pub fn (mut ctx Context) request_error(message string) veb.Result {
	ctx.res.status_code = 400
	return ctx.json(error_response('Bad Request', message))
}

pub fn (mut ctx Context) not_found(message ...string) veb.Result {
	ctx.res.status_code = 404
	msg := if message.len > 0 { message[0] } else { 'Resource not found' }
	return ctx.json(error_response('Not Found', msg))
}

pub fn (mut ctx Context) server_error(message string) veb.Result {
	ctx.res.status_code = 500
	return ctx.json(error_response('Internal Server Error', message))
}

pub fn (mut ctx Context) created[T](data T, message string) veb.Result {
	ctx.res.status_code = 201
	return ctx.json(success_response(data, message))
}

// Health check endpoint
@['/health'; get]
pub fn (mut server FSServer) health_check(mut ctx Context) veb.Result {
	return ctx.success('OK', 'HeroFS Server is running')
}

// API info endpoint
@['/api'; get]
pub fn (mut server FSServer) api_info(mut ctx Context) veb.Result {
	mut endpoints := map[string]string{}
	endpoints['filesystems'] = '/api/fs'
	endpoints['directories'] = '/api/dirs'
	endpoints['files'] = '/api/files'
	endpoints['blobs'] = '/api/blobs'
	endpoints['symlinks'] = '/api/symlinks'
	endpoints['blob_membership'] = '/api/blob-membership'
	endpoints['tools'] = '/api/tools'

	mut info := map[string]string{}
	info['name'] = 'HeroFS REST API'
	info['version'] = '1.0.0'
	info['description'] = 'RESTful API for HeroFS distributed filesystem'

	mut response_data := map[string]map[string]string{}
	response_data['info'] = info.clone()
	response_data['endpoints'] = endpoints.clone()
	return ctx.success(response_data, 'API information')
}

// CORS preflight handler
@['/api/:path...'; options]
pub fn (mut server FSServer) cors_preflight(mut ctx Context, path string) veb.Result {
	ctx.res.header.add(.access_control_allow_origin, '*')
	ctx.res.header.add(.access_control_allow_methods, 'GET, POST, PUT, DELETE, OPTIONS')
	ctx.res.header.add(.access_control_allow_headers, 'Content-Type, Authorization')
	ctx.res.header.add(.access_control_max_age, '86400')
	ctx.res.status_code = 204
	return ctx.text('')
}
