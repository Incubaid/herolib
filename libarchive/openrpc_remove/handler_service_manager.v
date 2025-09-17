module openrpc

import freeflowuniverse.herolib.core.jobs.model
import json

pub fn (mut h OpenRPCServer) handle_request_service(request OpenRPCRequest) !OpenRPCResponse {
	mut response := rpc_response_new(request.id)
	method := request.method.all_after_first('service.')
	println("request service:'${method}'")
	match method {
		'new' {
			service := h.runner.services.new()
			response.result = json.encode(service)
		}
		'set' {
			if request.params.len < 1 {
				return error('Missing service parameter')
			}
			service := json.decode(model.Service, request.params[0])!
			h.runner.services.set(service)!
			response.result = 'true'
		}
		'get' {
			if request.params.len < 1 {
				return error('Missing actor parameter')
			}
			service := h.runner.services.get(request.params[0])!
			response.result = json.encode(service)
		}
		'list' {
			services := h.runner.services.list()!
			response.result = json.encode(services)
		}
		'delete' {
			if request.params.len < 1 {
				return error('Missing actor parameter')
			}
			h.runner.services.delete(request.params[0])!
			response.result = 'true'
		}
		'update_status' {
			if request.params.len < 2 {
				return error('Missing actor or status parameters')
			}
			status := match request.params[1] {
				'ok' { model.ServiceState.ok }
				'down' { model.ServiceState.down }
				'error' { model.ServiceState.error }
				'halted' { model.ServiceState.halted }
				else { return error('Invalid status: ${request.params[1]}') }
			}
			h.runner.services.update_status(request.params[0], status)!
			response.result = 'true'
		}
		'get_by_action' {
			if request.params.len < 1 {
				return error('Missing action parameter')
			}
			services := h.runner.services.get_by_action(request.params[0])!
			response.result = json.encode(services)
		}
		'check_access' {
			if request.params.len < 4 {
				return error('Missing parameters: requires actor, action, user_pubkey, and groups')
			}
			// Parse groups array from JSON string
			groups := json.decode([]string, request.params[3])!
			has_access := h.runner.services.check_access(request.params[0], // actor
			 request.params[1], // action
			 request.params[2], // user_pubkey
			 groups)!
			response.result = json.encode(has_access)
		}
		else {
			return error('Unknown method: ${request.method}')
		}
	}

	return response
}
