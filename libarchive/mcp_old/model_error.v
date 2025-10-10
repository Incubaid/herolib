module mcp

import freeflowuniverse.herolib.schemas.jsonrpc

// resource_not_found indicates that the requested resource doesn't exist.
// This error is returned when the resource specified in the request is not found.
// Error code: -32002
pub fn resource_not_found(uri string) jsonrpc.RPCError {
	return jsonrpc.RPCError{
		code:    -32002
		message: 'Resource not found'
		data:    'The requested resource ${uri} was not found.'
	}
}

fn prompt_not_found(name string) jsonrpc.RPCError {
	return jsonrpc.RPCError{
		code:    -32602 // Invalid params
		message: 'Prompt not found: ${name}'
	}
}

fn missing_required_argument(arg_name string) jsonrpc.RPCError {
	return jsonrpc.RPCError{
		code:    -32602 // Invalid params
		message: 'Missing required argument: ${arg_name}'
	}
}

fn tool_not_found(name string) jsonrpc.RPCError {
	return jsonrpc.RPCError{
		code:    -32602 // Invalid params
		message: 'Tool not found: ${name}'
	}
}
