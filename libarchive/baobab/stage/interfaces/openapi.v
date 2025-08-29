module interfaces

import rand
import x.json2 as json { Any }
import freeflowuniverse.herolib.baobab.stage { Action, Client }
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.schemas.openapi

pub struct OpenAPIInterface {
pub mut:
	client Client
}

pub fn new_openapi_interface(client Client) &OpenAPIInterface {
	return &OpenAPIInterface{client}
}

pub fn (mut i OpenAPIInterface) handle(request openapi.Request) !openapi.Response {
	// Convert incoming OpenAPI request to a procedure call
	action := action_from_openapi_request(request)
	response := i.client.call_to_action(action) or { return err }
	return action_to_openapi_response(response)
}

pub fn action_from_openapi_request(request openapi.Request) Action {
	mut params := []Any{}
	if request.arguments.len > 0 {
		params << request.arguments.values()
	}
	if request.body != '' {
		params << request.body
	}
	if request.parameters.len > 0 {
		params << json.encode(request.parameters)
	}

	return Action{
		id:     rand.uuid_v4()
		name:   request.operation.operation_id
		params: json.encode(params.str())
	}
}

pub fn action_to_openapi_response(action Action) openapi.Response {
	return openapi.Response{
		body: action.result
	}
}
