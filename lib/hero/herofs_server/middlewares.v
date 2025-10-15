module herofs_server

import net.http
import incubaid.herolib.ui.console

// Request logging middleware
pub fn (mut server FSServer) middleware_log_request(mut ctx Context) {
	console.print_debug('${ctx.req.method} ${ctx.req.url} from ${ctx.ip()}')
}

// Response logging middleware
pub fn (mut server FSServer) middleware_log_response(mut ctx Context) {
	console.print_debug('Response: ${ctx.res.status_code}')
}

// Error handling middleware
pub fn (mut server FSServer) middleware_error_handler(mut ctx Context) {
	// This will be called for unhandled errors
	console.print_debug('Error handling middleware called')
}

// Content type middleware for JSON APIs
pub fn (mut server FSServer) middleware_json_content_type(mut ctx Context) {
	if ctx.req.url.starts_with('/api/') {
		ctx.set_content_type('application/json')
	}
}

// Request validation middleware
pub fn (mut server FSServer) middleware_validate_request(mut ctx Context) {
	// Validate request size
	if ctx.req.data.len > 10 * 1024 * 1024 { // 10MB limit
		console.print_debug('Request too large: ${ctx.req.data.len} bytes')
	}

	// Validate content type for POST/PUT requests
	if ctx.req.method in [http.Method.post, http.Method.put] {
		content_type := ctx.get_header(.content_type) or { '' }
		if !content_type.contains('application/json') && ctx.req.url.starts_with('/api/') {
			console.print_debug('Invalid content type for API request: ${content_type}')
		}
	}
}
