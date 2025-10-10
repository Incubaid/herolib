module openrpc

// path to openrpc.json file
pub fn new_handler(openrpc_path string) !Handler {
	mut openrpc_handler := Handler{
		specification: new(path: openrpc_path)!
	}

	return openrpc_handler
}
