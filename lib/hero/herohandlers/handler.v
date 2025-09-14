module openrpc

import json
import freeflowuniverse.herolib.schemas.openrpc
import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.schemas.jsonrpc
import os

const openrpc_path = os.join_path(os.dir(@FILE), 'openrpc.json')

pub fn new_heromodels_handler() !openrpc.Handler {
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


pub fn calendar_set(request jsonrpc.Request) !jsonrpc.Response{
	mut payload := json.decode(heromodels.Calendar, request.params) or { 
		return jsonrpc.invalid_params }
    id := heromodels.set[heromodels.Calendar](mut payload) or { 
		println('error setting calendar $err')
		return jsonrpc.internal_error 
	}
	return jsonrpc.new_response(request.id, id.str())
}

pub fn calendar_delete(request jsonrpc.Request) !jsonrpc.Response {
    payload := jsonrpc.decode_payload[u32](request.params) or { return jsonrpc.invalid_params }
    heromodels.delete[heromodels.Calendar](payload) or { return jsonrpc.internal_error }
    return jsonrpc.new_response(request.id, '')
}

pub fn calendar_list(request jsonrpc.Request) !jsonrpc.Response {
	result := heromodels.list[heromodels.Calendar]() or { return jsonrpc.internal_error }
    return jsonrpc.new_response(request.id, json.encode(result))
}