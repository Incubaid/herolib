module openrpc

import json

// JSON-RPC 2.0 request structure
pub struct JsonRpcRequest {
pub:
	jsonrpc string = '2.0'
	method  string
	params  string
	id      string
}

// JSON-RPC 2.0 response structure
pub struct JsonRpcResponse {
pub:
	jsonrpc string = '2.0'
	result  string
	error   ?JsonRpcError
	id      string
}

// JSON-RPC 2.0 error structure
pub struct JsonRpcError {
pub:
	code    int
	message string
	data    string
}

// Comment-specific argument structures
@[params]
pub struct CommentGetArgs {
pub mut:
	id     ?u32
	author ?u32
	parent ?u32
}

@[params]
pub struct CommentDeleteArgs {
pub mut:
	id u32
}