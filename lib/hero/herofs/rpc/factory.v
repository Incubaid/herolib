module rpc

import freeflowuniverse.herolib.schemas.openrpc
import os

const openrpc_path = os.join_path(os.dir(@FILE), 'openrpc.json')

@[params]
pub struct ServerArgs {
pub mut:
	socket_path string = '/tmp/herofs'
	http_port   int // if 0, no http server will be started
}

pub fn start(args ServerArgs) ! {
	mut openrpc_handler := openrpc.new_handler(openrpc_path)!

	// Register fs procedures
	openrpc_handler.register_procedure_handle('fs_get', fs_get)
	openrpc_handler.register_procedure_handle('fs_set', fs_set)
	openrpc_handler.register_procedure_handle('fs_delete', fs_delete)
	openrpc_handler.register_procedure_handle('fs_list', fs_list)

	// Register fs_dir procedures
	openrpc_handler.register_procedure_handle('fs_dir_get', fs_dir_get)
	openrpc_handler.register_procedure_handle('fs_dir_set', fs_dir_set)
	openrpc_handler.register_procedure_handle('fs_dir_delete', fs_dir_delete)
	openrpc_handler.register_procedure_handle('fs_dir_list', fs_dir_list)
	openrpc_handler.register_procedure_handle('fs_dir_move', fs_dir_move)
	openrpc_handler.register_procedure_handle('fs_dir_rename', fs_dir_rename)
	openrpc_handler.register_procedure_handle('fs_dir_list_by_filesystem', fs_dir_list_by_filesystem)
	openrpc_handler.register_procedure_handle('fs_dir_has_children', fs_dir_has_children)
	openrpc_handler.register_procedure_handle('fs_dir_list_contents', fs_dir_list_contents)

	// Register fs_file procedures
	openrpc_handler.register_procedure_handle('fs_file_get', fs_file_get)
	openrpc_handler.register_procedure_handle('fs_file_set', fs_file_set)
	openrpc_handler.register_procedure_handle('fs_file_delete', fs_file_delete)
	openrpc_handler.register_procedure_handle('fs_file_list', fs_file_list)
	openrpc_handler.register_procedure_handle('fs_file_move', fs_file_move)
	openrpc_handler.register_procedure_handle('fs_file_rename', fs_file_rename)
	openrpc_handler.register_procedure_handle('fs_file_update_metadata', fs_file_update_metadata)
	openrpc_handler.register_procedure_handle('fs_file_update_accessed', fs_file_update_accessed)
	openrpc_handler.register_procedure_handle('fs_file_append_blob', fs_file_append_blob)
	openrpc_handler.register_procedure_handle('fs_file_list_by_directory', fs_file_list_by_directory)
	openrpc_handler.register_procedure_handle('fs_file_list_by_filesystem', fs_file_list_by_filesystem)
	openrpc_handler.register_procedure_handle('fs_file_list_by_mime_type', fs_file_list_by_mime_type)

	// Register fs_blob procedures
	openrpc_handler.register_procedure_handle('fs_blob_get', fs_blob_get)
	openrpc_handler.register_procedure_handle('fs_blob_set', fs_blob_set)
	openrpc_handler.register_procedure_handle('fs_blob_delete', fs_blob_delete)
	openrpc_handler.register_procedure_handle('fs_blob_list', fs_blob_list)

	// Register fs_symlink procedures
	openrpc_handler.register_procedure_handle('fs_symlink_get', fs_symlink_get)
	openrpc_handler.register_procedure_handle('fs_symlink_set', fs_symlink_set)
	openrpc_handler.register_procedure_handle('fs_symlink_delete', fs_symlink_delete)
	openrpc_handler.register_procedure_handle('fs_symlink_list', fs_symlink_list)
	openrpc_handler.register_procedure_handle('fs_symlink_is_broken', fs_symlink_is_broken)
	openrpc_handler.register_procedure_handle('fs_symlink_list_by_filesystem', fs_symlink_list_by_filesystem)

	if args.http_port != 0 {
		openrpc.start_http_server(openrpc_handler, port: args.http_port)!
	} else {
		openrpc.start_unix_server(openrpc_handler, socket_path: args.socket_path)!
	}
}
