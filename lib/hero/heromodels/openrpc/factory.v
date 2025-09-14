module openrpc

import json
import freeflowuniverse.herolib.schemas.openrpc
import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.schemas.jsonrpc
import os

const openrpc_path = os.join_path(os.dir(@FILE), 'openrpc.json')

pub fn new() !openrpc.Handler {
	mut openrpc_handler := openrpc.Handler {
		specification: openrpc.new(path: openrpc_path)!
	}

	openrpc_handler.register_procedure_handle('comment_get', comment_get)
	openrpc_handler.register_procedure_handle('comment_set', comment_set)
	openrpc_handler.register_procedure_handle('comment_delete', comment_delete)
	openrpc_handler.register_procedure_handle('comment_list', comment_list)

	openrpc_handler.register_procedure_handle('calendar_get', calendar_get)
	openrpc_handler.register_procedure_handle('calendar_set', calendar_set)
	openrpc_handler.register_procedure_handle('calendar_delete', calendar_delete)
	openrpc_handler.register_procedure_handle('calendar_list', calendar_list)

	return openrpc_handler
}
