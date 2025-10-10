module openrpc

// Generic OpenRPC request/response structures
pub struct OpenRPCRequest {
pub mut:
	jsonrpc string @[required]
	method  string @[required]
	params  []string
	id      int @[required]
}

pub struct OpenRPCResponse {
pub mut:
	jsonrpc string @[required]
	result  string
	error   string
	id      int @[required]
}

fn rpc_response_new(id int) OpenRPCResponse {
	mut response := OpenRPCResponse{
		jsonrpc: '2.0'
		id:      id
	}
	return response
}

fn rpc_response_error(id int, errormsg string) OpenRPCResponse {
	mut response := OpenRPCResponse{
		jsonrpc: '2.0'
		id:      id
		error:   errormsg
	}
	return response
}

const rpc_queue = 'herorunner:q:rpc'
