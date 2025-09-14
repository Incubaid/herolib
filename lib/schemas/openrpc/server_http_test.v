module openrpc

import os
import veb
import x.json2
import net.http
import freeflowuniverse.herolib.schemas.jsonrpc

const specification_path = os.join_path(os.dir(@FILE), '/testdata/openrpc.json')

pub struct TestHandler {}

// handler for test echoes JSONRPC Request as JSONRPC Response
pub fn (h TestHandler) handle(request jsonrpc.Request) !jsonrpc.Response {
	return jsonrpc.Response{
		jsonrpc: request.jsonrpc
		id:      request.id
		result:  request.params
	}
}

fn test_new_server() {
	new_http_controller(
		Handler: Handler{
			specification: new(path: specification_path)!
			handler:       TestHandler{}
		}
	)
}

fn test_run_server() {
	specification := new(path: specification_path)!
	mut controller := new_http_controller(
		Handler: Handler{
			specification: specification
			handler:       TestHandler{}
		}
	)
	spawn controller.run()
}
