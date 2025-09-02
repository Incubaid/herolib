module openrpc

// processes the JSON-RPC request
pub fn (mut server RPCServer) process(r string, params_str string)! string {

	// Route to appropriate method
	result := match r {
		'comment_get' {
			comment_get(params_str)!
		}
		'comment_set' {
			comment_set(params_str)!
		}
		'comment_delete' {
			comment_delete(params_str)!
		}
		'comment_list' {
			comment_list()!
		}
		'rpc.discover' {
			server.discover()!
		}
		else {
			return server.create_error_response(-32601, 'Method not found', r)
		}
	}

	return result
}	