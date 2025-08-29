module interfaces

import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.baobab.stage { Action }

pub fn action_from_jsonrpc_request(request jsonrpc.Request) Action {
	return Action{
		id:     request.id
		name:   request.method
		params: request.params
	}
}

pub fn action_to_jsonrpc_response(action Action) jsonrpc.Response {
	return jsonrpc.new_response(action.id, action.result)
}
