module rust

import freeflowuniverse.herolib.ai.mcp
import freeflowuniverse.herolib.schemas.jsonrpc
import log

pub fn new_mcp_server() !&mcp.Server {
	log.info('Creating new Rust MCP server')

	// Initialize the server with tools and prompts
	mut server := mcp.new_server(mcp.MemoryBackend{
		tools:           {
			'list_functions_in_file': list_functions_in_file_spec
			'list_structs_in_file':   list_structs_in_file_spec
			'list_modules_in_dir':    list_modules_in_dir_spec
			'get_import_statement':   get_import_statement_spec
			// 'get_module_dependency': get_module_dependency_spec
		}
		tool_handlers:   {
			'list_functions_in_file': list_functions_in_file_handler
			'list_structs_in_file':   list_structs_in_file_handler
			'list_modules_in_dir':    list_modules_in_dir_handler
			'get_import_statement':   get_import_statement_handler
			// 'get_module_dependency': get_module_dependency_handler
		}
		prompts:         {
			'rust_functions':    rust_functions_prompt_spec
			'rust_structs':      rust_structs_prompt_spec
			'rust_modules':      rust_modules_prompt_spec
			'rust_imports':      rust_imports_prompt_spec
			'rust_dependencies': rust_dependencies_prompt_spec
			'rust_tools_guide':  rust_tools_guide_prompt_spec
		}
		prompt_handlers: {
			'rust_functions':    rust_functions_prompt_handler
			'rust_structs':      rust_structs_prompt_handler
			'rust_modules':      rust_modules_prompt_handler
			'rust_imports':      rust_imports_prompt_handler
			'rust_dependencies': rust_dependencies_prompt_handler
			'rust_tools_guide':  rust_tools_guide_prompt_handler
		}
	}, mcp.ServerParams{
		config: mcp.ServerConfiguration{
			server_info: mcp.ServerInfo{
				name:    'rust'
				version: '1.0.0'
			}
		}
	})!

	return server
}
