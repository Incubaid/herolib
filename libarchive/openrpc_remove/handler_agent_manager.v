module openrpc

import freeflowuniverse.herolib.core.jobs.model
import json

pub fn (mut h OpenRPCServer) handle_request_agent(request OpenRPCRequest) !OpenRPCResponse {
	mut response := rpc_response_new(request.id)

	method := request.method.all_after_first('agent.')

	println("request agent:'${method}'")

	match method {
		'new' {
			agent := h.runner.agents.new()
			response.result = json.encode(agent)
		}
		'set' {
			if request.params.len < 1 {
				return error('Missing agent parameter')
			}
			agent := json.decode(model.Agent, request.params[0])!
			h.runner.agents.set(agent)!
			response.result = 'true'
		}
		'get' {
			if request.params.len < 1 {
				return error('Missing pubkey parameter')
			}
			agent := h.runner.agents.get(request.params[0])!
			response.result = json.encode(agent)
		}
		'list' {
			agents := h.runner.agents.list()!
			response.result = json.encode(agents)
		}
		'delete' {
			if request.params.len < 1 {
				return error('Missing pubkey parameter')
			}
			h.runner.agents.delete(request.params[0])!
			response.result = 'true'
		}
		'update_status' {
			if request.params.len < 2 {
				return error('Missing pubkey or status parameters')
			}
			status := match request.params[1] {
				'ok' { model.AgentState.ok }
				'down' { model.AgentState.down }
				'error' { model.AgentState.error }
				'halted' { model.AgentState.halted }
				else { return error('Invalid status: ${request.params[1]}') }
			}
			h.runner.agents.update_status(request.params[0], status)!
			response.result = 'true'
		}
		'get_by_service' {
			if request.params.len < 2 {
				return error('Missing actor or action parameters')
			}
			agents := h.runner.agents.get_by_service(request.params[0], request.params[1])!
			response.result = json.encode(agents)
		}
		else {
			return error('Unknown method: ${request.method}')
		}
	}

	return response
}
