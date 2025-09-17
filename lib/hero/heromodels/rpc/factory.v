module rpc

import freeflowuniverse.herolib.schemas.openrpc
import freeflowuniverse.herolib.hero.heroserver
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.ui.console
import os

const openrpc_path = os.join_path(os.dir(@FILE), 'openrpc.json')

// Create a new heromodels handler for heroserver
pub fn new_heromodels_handler() !&openrpc.Handler {
	mut handler := openrpc.new_handler(openrpc_path)!

	// Register all comment methods
	handler.register_procedure_handle('comment_get', comment_get)
	handler.register_procedure_handle('comment_set', comment_set)
	handler.register_procedure_handle('comment_delete', comment_delete)
	handler.register_procedure_handle('comment_list', comment_list)

	// Register all calendar methods
	handler.register_procedure_handle('calendar_get', calendar_get)
	handler.register_procedure_handle('calendar_set', calendar_set)
	handler.register_procedure_handle('calendar_delete', calendar_delete)
	handler.register_procedure_handle('calendar_list', calendar_list)

	// Register all calendar event methods
	handler.register_procedure_handle('calendar_event_get', calendar_event_get)
	handler.register_procedure_handle('calendar_event_set', calendar_event_set)
	handler.register_procedure_handle('calendar_event_delete', calendar_event_delete)
	handler.register_procedure_handle('calendar_event_list', calendar_event_list)

	// Register all chat group methods
	handler.register_procedure_handle('chat_group_get', chat_group_get)
	handler.register_procedure_handle('chat_group_set', chat_group_set)
	handler.register_procedure_handle('chat_group_delete', chat_group_delete)
	handler.register_procedure_handle('chat_group_list', chat_group_list)

	// Register all chat message methods
	handler.register_procedure_handle('chat_message_get', chat_message_get)
	handler.register_procedure_handle('chat_message_set', chat_message_set)
	handler.register_procedure_handle('chat_message_delete', chat_message_delete)
	handler.register_procedure_handle('chat_message_list', chat_message_list)

	// Register all group methods
	handler.register_procedure_handle('group_get', group_get)
	handler.register_procedure_handle('group_set', group_set)
	handler.register_procedure_handle('group_delete', group_delete)
	handler.register_procedure_handle('group_list', group_list)

	// Register all project issue methods
	handler.register_procedure_handle('project_issue_get', project_issue_get)
	handler.register_procedure_handle('project_issue_set', project_issue_set)
	handler.register_procedure_handle('project_issue_delete', project_issue_delete)
	handler.register_procedure_handle('project_issue_list', project_issue_list)

	// Register all project methods
	handler.register_procedure_handle('project_get', project_get)
	handler.register_procedure_handle('project_set', project_set)
	handler.register_procedure_handle('project_delete', project_delete)
	handler.register_procedure_handle('project_list', project_list)

	// Register all user methods
	handler.register_procedure_handle('user_get', user_get)
	handler.register_procedure_handle('user_set', user_set)
	handler.register_procedure_handle('user_delete', user_delete)
	handler.register_procedure_handle('user_list', user_list)

	return &handler
}

// Start heromodels server using heroserver
@[params]
pub struct ServerArgs {
pub mut:
	port int    = 8080
	host string = 'localhost'
}

pub fn start(args ServerArgs) ! {
	// Create a new heroserver instance
	mut server := heroserver.new(port: args.port, host: args.host)!

	// Create and register the heromodels handler
	handler := new_heromodels_handler()!
	server.register_handler('heromodels', handler)!

	console.print_green('Documentation available at: http://${args.host}:${args.port}/doc/heromodels/')
	console.print_green('HeroModels API available at: http://${args.host}:${args.port}/api/heromodels')

	// Start the server
	server.start()!
}
