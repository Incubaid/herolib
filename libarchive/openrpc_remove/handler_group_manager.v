module openrpc

import freeflowuniverse.herolib.core.jobs.model
import json

pub fn (mut h OpenRPCServer) handle_request_group(request OpenRPCRequest) !OpenRPCResponse {
	mut response := rpc_response_new(request.id)
	method := request.method.all_after_first('group.')
	println("request group:'${method}'")
	match method {
		'new' {
			group := h.runner.groups.new()
			response.result = json.encode(group)
		}
		'set' {
			if request.params.len < 1 {
				return error('Missing group parameter')
			}
			group := json.decode(model.Group, request.params[0])!
			h.runner.groups.set(group)!
			response.result = 'true'
		}
		'get' {
			if request.params.len < 1 {
				return error('Missing guid parameter')
			}
			group := h.runner.groups.get(request.params[0])!
			response.result = json.encode(group)
		}
		'list' {
			groups := h.runner.groups.list()!
			response.result = json.encode(groups)
		}
		'delete' {
			if request.params.len < 1 {
				return error('Missing guid parameter')
			}
			h.runner.groups.delete(request.params[0])!
			response.result = 'true'
		}
		'add_member' {
			if request.params.len < 2 {
				return error('Missing guid or member parameters')
			}
			h.runner.groups.add_member(request.params[0], request.params[1])!
			response.result = 'true'
		}
		'remove_member' {
			if request.params.len < 2 {
				return error('Missing guid or member parameters')
			}
			h.runner.groups.remove_member(request.params[0], request.params[1])!
			response.result = 'true'
		}
		'get_user_groups' {
			if request.params.len < 1 {
				return error('Missing user_pubkey parameter')
			}
			groups := h.runner.groups.get_user_groups(request.params[0])!
			response.result = json.encode(groups)
		}
		else {
			return error('Unknown method: ${request.method}')
		}
	}

	return response
}
