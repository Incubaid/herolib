module openrpc

import os
import json


//path to openrpc.json file
pub fn new_handler(openrpc_path string) !Handler {

	mut openrpc_handler := openrpc.Handler {
		specification: new(path: openrpc_path)!
	}

	return openrpc_handler

}
