module rpc

import freeflowuniverse.herolib.schemas.openrpc
import os

const openrpc_path = os.join_path(os.dir(@FILE), 'openrpc.json')

@[params]
pub struct ServerArgs {
pub mut:
	socket_path string = '/tmp/heromodels'
}

pub fn start(args ServerArgs) ! {
	mut openrpc_handler := openrpc.new_handler(openrpc_path)!

	openrpc_handler.register_procedure_handle('comment_get', comment_get)
	openrpc_handler.register_procedure_handle('comment_set', comment_set)
	openrpc_handler.register_procedure_handle('comment_delete', comment_delete)
	openrpc_handler.register_procedure_handle('comment_list', comment_list)

	openrpc_handler.register_procedure_handle('calendar_get', calendar_get)
	openrpc_handler.register_procedure_handle('calendar_set', calendar_set)
	openrpc_handler.register_procedure_handle('calendar_delete', calendar_delete)
	openrpc_handler.register_procedure_handle('calendar_list', calendar_list)

	openrpc.start_unix_server(openrpc_handler, socket_path: args.socket_path)!
}
