module openrpc

import freeflowuniverse.herolib.core.jobs.model
import json

pub fn (mut h OpenRPCServer) handle_request_job(request OpenRPCRequest) !OpenRPCResponse {
	mut response := rpc_response_new(request.id)

	method := request.method.all_after_first('job.')
	println("request job:'${method}'")
	println(request)
	match method {
		'new' {
			job := h.runner.jobs.new()
			response.result = json.encode(job)
		}
		'set' {
			if request.params.len < 1 {
				return error('Missing job parameter')
			}
			job := json.decode(model.Job, request.params[0])!
			h.runner.jobs.set(job)!
			response.result = 'true'
		}
		'get' {
			if request.params.len < 1 {
				return error('Missing guid parameter')
			}
			job := h.runner.jobs.get(request.params[0])!
			response.result = json.encode(job)
		}
		'list' {
			jobs := h.runner.jobs.list()!
			response.result = json.encode(jobs)
		}
		'delete' {
			if request.params.len < 1 {
				return error('Missing guid parameter')
			}
			h.runner.jobs.delete(request.params[0])!
			response.result = 'true'
		}
		'update_status' {
			if request.params.len < 2 {
				return error('Missing guid or status parameters')
			}
			status := match request.params[1] {
				'created' { model.Status.created }
				'scheduled' { model.Status.scheduled }
				'planned' { model.Status.planned }
				'running' { model.Status.running }
				'error' { model.Status.error }
				'ok' { model.Status.ok }
				else { return error('Invalid status: ${request.params[1]}') }
			}
			h.runner.jobs.update_status(request.params[0], status)!
			job := h.runner.jobs.get(request.params[0])! // Get updated job to return
			response.result = json.encode(job)
		}
		else {
			return error('Unknown method: ${request.method}')
		}
	}

	return response
}
