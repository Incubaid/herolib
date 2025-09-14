module codegen

import freeflowuniverse.herolib.core.code { Function, Module, Struct }
import freeflowuniverse.herolib.schemas.openrpc { OpenRPC }

// pub struct OpenRPCCode {
// pub mut:
// 	openrpc_json File
// 	handler      VFile
// 	handler_test VFile
// 	client       VFile
// 	client_test  VFile
// 	server       VFile
// 	server_test  VFile
// }

pub fn generate_module(o OpenRPC, receiver Struct, methods_map map[string]Function, objects_map map[string]Struct) !Module {
	// openrpc_json := o.encode()!
	// openrpc_file := File{
	// 	name: 'openrpc'
	// 	extension: 'json'
	// 	content: openrpc_json
	// }

	client_file := generate_client_file(o, objects_map)!
	client_test_file := generate_client_test_file(o, methods_map, objects_map)!

	handler_file := generate_handler_file(o, receiver, methods_map, objects_map)!
	handler_test_file := generate_handler_test_file(o, receiver, methods_map, objects_map)!

	interface_file := generate_interface_file(o)!
	interface_test_file := generate_interface_test_file(o)!

	return Module{
		files: [
			client_file,
			client_test_file,
			handler_file,
			handler_test_file,
			interface_file,
			interface_test_file,
		]
	}
}
