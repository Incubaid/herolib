module openapi

import net.http
import x.json2 { Any }
import incubaid.herolib.schemas.jsonrpc

pub struct Request {
pub:
	path       string // The requested path
	method     string // HTTP method (e.g., GET, POST)
	key        string
	body       string // Request body
	operation  Operation
	arguments  map[string]Any
	parameters map[string]string
	header     http.Header @[json: '-'; omitempty; str: skip] // Request headers
}

pub struct Response {
pub mut:
	status http.Status // HTTP status
	body   string      // Response body
	header http.Header @[json: '-'; omitempty; str: skip] // Response headers
}

pub struct Handler {
pub:
	specification OpenAPI @[required] // The OpenRPC specification
pub mut:
	handler IHandler
}

pub interface IHandler {
mut:
	handle(Request) !Response // Custom handler for other methods
}

@[params]
pub struct HandleParams {
	timeout int = 60 // Timeout in seconds
	retry   int // Number of retries
}

// Handle a JSON-RPC request and return a response
pub fn (mut h Handler) handle(req Request, params HandleParams) !Response {
	// Validate the method exists in the specification
	// if req.method !in h.specification.methods.map(it.name) {
	// 	// Return 404 if no route matches
	// 	return Response{
	// 		status: .not_found
	// 		body: 'Not Found'
	// 		header: http.new_header(
	// 			key: CommonHeader.content_type,
	// 			value: 'text/plain'
	// 		)
	// 	}
	// }

	// Enforce timeout and retries (dummy implementation)
	if params.timeout < 0 || params.retry < 0 {
		panic('implement')
	}

	// Forward the request to the custom handler
	return h.handler.handle(req)
}
