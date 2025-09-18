module rpc

import freeflowuniverse.herolib.schemas.openrpc
import os

const openrpc_path = os.join_path(os.dir(@FILE), 'openrpc.json')

@[params]
pub struct ServerArgs {
pub mut:
	socket_path string = '/tmp/heromodels'
	http_port   int // if 0, no http server will be started
}

pub fn start(args ServerArgs) ! {
	mut openrpc_handler := openrpc.new_handler(openrpc_path)!

	openrpc_handler.register_procedure_handle('message_get', message_get)
	openrpc_handler.register_procedure_handle('message_set', message_set)
	openrpc_handler.register_procedure_handle('message_delete', message_delete)
	openrpc_handler.register_procedure_handle('message_list', message_list)

	openrpc_handler.register_procedure_handle('calendar_get', calendar_get)
	openrpc_handler.register_procedure_handle('calendar_set', calendar_set)
	openrpc_handler.register_procedure_handle('calendar_delete', calendar_delete)
	openrpc_handler.register_procedure_handle('calendar_list', calendar_list)

	openrpc_handler.register_procedure_handle('calendar_event_get', calendar_event_get)
	openrpc_handler.register_procedure_handle('calendar_event_set', calendar_event_set)
	openrpc_handler.register_procedure_handle('calendar_event_delete', calendar_event_delete)
	openrpc_handler.register_procedure_handle('calendar_event_list', calendar_event_list)

	openrpc_handler.register_procedure_handle('chat_group_get', chat_group_get)
	openrpc_handler.register_procedure_handle('chat_group_set', chat_group_set)
	openrpc_handler.register_procedure_handle('chat_group_delete', chat_group_delete)
	openrpc_handler.register_procedure_handle('chat_group_list', chat_group_list)

	openrpc_handler.register_procedure_handle('chat_message_get', chat_message_get)
	openrpc_handler.register_procedure_handle('chat_message_set', chat_message_set)
	openrpc_handler.register_procedure_handle('chat_message_delete', chat_message_delete)
	openrpc_handler.register_procedure_handle('chat_message_list', chat_message_list)

	openrpc_handler.register_procedure_handle('group_get', group_get)
	openrpc_handler.register_procedure_handle('group_set', group_set)
	openrpc_handler.register_procedure_handle('group_delete', group_delete)
	openrpc_handler.register_procedure_handle('group_list', group_list)

	openrpc_handler.register_procedure_handle('project_issue_get', project_issue_get)
	openrpc_handler.register_procedure_handle('project_issue_set', project_issue_set)
	openrpc_handler.register_procedure_handle('project_issue_delete', project_issue_delete)
	openrpc_handler.register_procedure_handle('project_issue_list', project_issue_list)

	openrpc_handler.register_procedure_handle('project_get', project_get)
	openrpc_handler.register_procedure_handle('project_set', project_set)
	openrpc_handler.register_procedure_handle('project_delete', project_delete)
	openrpc_handler.register_procedure_handle('project_list', project_list)

	openrpc_handler.register_procedure_handle('user_get', user_get)
	openrpc_handler.register_procedure_handle('user_set', user_set)
	openrpc_handler.register_procedure_handle('user_delete', user_delete)
	openrpc_handler.register_procedure_handle('user_list', user_list)

	if args.http_port != 0 {
		openrpc.start_http_server(openrpc_handler, port: args.http_port)!
	} else {
		openrpc.start_unix_server(openrpc_handler, socket_path: args.socket_path)!
	}
}
