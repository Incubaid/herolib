module openrpc

import freeflowuniverse.herolib.core.redisclient
import json

// Start the server and listen for requests
pub fn (mut s OpenRPCServer) start() ! {
	println('Starting OpenRPC server.')

	for {
		// Get message from queue
		msg := s.queue.get(5000)!

		if msg.len == 0 {
			println("queue '${rpc_queue}' empty")
			continue
		}

		println("process '${msg}'")

		// Parse OpenRPC request
		request := json.decode(OpenRPCRequest, msg) or {
			println('Error decoding request: ${err}')
			continue
		}

		// Process request with appropriate handler
		response := s.handle_request(request)!

		// Send response back to Redis using response queue
		response_json := json.encode(response)
		key := '${rpc_queue}:${request.id}'
		println('response: \n${response}\n put on return queue ${key} ')
		mut response_queue := &redisclient.RedisQueue{
			key:   key
			redis: s.redis
		}
		response_queue.add(response_json)!
	}
}

// Get the handler for a specific method based on its prefix
fn (mut s OpenRPCServer) handle_request(request OpenRPCRequest) !OpenRPCResponse {
	method := request.method.to_lower()
	println("process: method:  '${method}'")
	if method.starts_with('job.') {
		return s.handle_request_job(request) or {
			return rpc_response_error(request.id, 'error in request job:\n${err}')
		}
	}
	if method.starts_with('agent.') {
		return s.handle_request_agent(request) or {
			return rpc_response_error(request.id, 'error in request agent:\n${err}')
		}
	}
	if method.starts_with('group.') {
		return s.handle_request_group(request) or {
			return rpc_response_error(request.id, 'error in request group:\n${err}')
		}
	}
	if method.starts_with('service.') {
		return s.handle_request_service(request) or {
			return rpc_response_error(request.id, 'error in request service:\n${err}')
		}
	}

	return rpc_response_error(request.id, 'Could not find handler for ${method}')
}
