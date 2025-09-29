module rust

import freeflowuniverse.herolib.ai.mcp
import freeflowuniverse.herolib.lang.rust
import freeflowuniverse.herolib.schemas.jsonschema
import x.json2 as json { Any }

// Tool specification for listing functions in a Rust file
const list_functions_in_file_spec = mcp.Tool{
	name:         'list_functions_in_file'
	description:  'Lists all function definitions in a Rust file'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'file_path': jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to the Rust file'
			})
		}
		required:   ['file_path']
	}
}

// Handler for list_functions_in_file
pub fn list_functions_in_file_handler(arguments map[string]Any) !mcp.ToolCallResult {
	file_path := arguments['file_path'].str()
	result := rust.list_functions_in_file(file_path) or { return mcp.error_tool_call_result(err) }
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.array_to_mcp_tool_contents[string](result)
	}
}

// Tool specification for listing structs in a Rust file
const list_structs_in_file_spec = mcp.Tool{
	name:         'list_structs_in_file'
	description:  'Lists all struct definitions in a Rust file'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'file_path': jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to the Rust file'
			})
		}
		required:   ['file_path']
	}
}

// Handler for list_structs_in_file
pub fn list_structs_in_file_handler(arguments map[string]Any) !mcp.ToolCallResult {
	file_path := arguments['file_path'].str()
	result := rust.list_structs_in_file(file_path) or { return mcp.error_tool_call_result(err) }
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.array_to_mcp_tool_contents[string](result)
	}
}

// Tool specification for listing modules in a directory
const list_modules_in_dir_spec = mcp.Tool{
	name:         'list_modules_in_dir'
	description:  'Lists all Rust modules in a directory'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'dir_path': jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to the directory'
			})
		}
		required:   ['dir_path']
	}
}

// Handler for list_modules_in_dir
pub fn list_modules_in_dir_handler(arguments map[string]Any) !mcp.ToolCallResult {
	dir_path := arguments['dir_path'].str()
	result := rust.list_modules_in_directory(dir_path) or { return mcp.error_tool_call_result(err) }
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.array_to_mcp_tool_contents[string](result)
	}
}

// Tool specification for getting an import statement
const get_import_statement_spec = mcp.Tool{
	name:         'get_import_statement'
	description:  'Generates appropriate Rust import statement for a module based on file paths'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'current_file':  jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to the file where the import will be added'
			})
			'target_module': jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to the target module to be imported'
			})
		}
		required:   ['current_file', 'target_module']
	}
}

// Handler for get_import_statement
pub fn get_import_statement_handler(arguments map[string]Any) !mcp.ToolCallResult {
	current_file := arguments['current_file'].str()
	target_module := arguments['target_module'].str()
	result := rust.generate_import_statement(current_file, target_module) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result)
	}
}

// Tool specification for getting module dependency information
const get_module_dependency_spec = mcp.Tool{
	name:         'get_module_dependency'
	description:  'Gets dependency information for adding a Rust module to a project'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'importer_path': jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to the file that will import the module'
			})
			'module_path':   jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to the module that will be imported'
			})
		}
		required:   ['importer_path', 'module_path']
	}
}

struct Tester {
	import_statement string
	module_path      string
}

// Handler for get_module_dependency
pub fn get_module_dependency_handler(arguments map[string]Any) !mcp.ToolCallResult {
	importer_path := arguments['importer_path'].str()
	module_path := arguments['module_path'].str()
	dependency := rust.get_module_dependency(importer_path, module_path) or {
		return mcp.error_tool_call_result(err)
	}

	return mcp.ToolCallResult{
		is_error: false
		content:  result_to_mcp_tool_contents[Tester](Tester{
			import_statement: dependency.import_statement
			module_path:      dependency.module_path
		}) // Return JSON string
	}
}

// --- Get Function from File Tool ---

// Specification for get_function_from_file tool
const get_function_from_file_spec = mcp.Tool{
	name:         'get_function_from_file'
	description:  'Get the declaration of a Rust function from a specified file path.'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'file_path':     jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to the Rust file.'
			})
			'function_name': jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: "Name of the function to retrieve (e.g., 'my_function' or 'MyStruct::my_method')."
			})
		}
		required:   ['file_path', 'function_name']
	}
}

// Handler for get_function_from_file
pub fn get_function_from_file_handler(arguments map[string]Any) !mcp.ToolCallResult {
	file_path := arguments['file_path'].str()
	function_name := arguments['function_name'].str()
	result := rust.get_function_from_file(file_path, function_name) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result)
	}
}

// --- Get Function from Module Tool ---

// Specification for get_function_from_module tool
const get_function_from_module_spec = mcp.Tool{
	name:         'get_function_from_module'
	description:  'Get the declaration of a Rust function from a specified module path (directory or file).'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'module_path':   jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to the Rust module directory or file.'
			})
			'function_name': jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: "Name of the function to retrieve (e.g., 'my_function' or 'MyStruct::my_method')."
			})
		}
		required:   ['module_path', 'function_name']
	}
}

// Handler for get_function_from_module
pub fn get_function_from_module_handler(arguments map[string]Any) !mcp.ToolCallResult {
	module_path := arguments['module_path'].str()
	function_name := arguments['function_name'].str()
	result := rust.get_function_from_module(module_path, function_name) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result)
	}
}

// --- Get Struct from File Tool ---

// Specification for get_struct_from_file tool
const get_struct_from_file_spec = mcp.Tool{
	name:         'get_struct_from_file'
	description:  'Get the declaration of a Rust struct from a specified file path.'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'file_path':   jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to the Rust file.'
			})
			'struct_name': jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: "Name of the struct to retrieve (e.g., 'MyStruct')."
			})
		}
		required:   ['file_path', 'struct_name']
	}
}

// Handler for get_struct_from_file
pub fn get_struct_from_file_handler(arguments map[string]Any) !mcp.ToolCallResult {
	file_path := arguments['file_path'].str()
	struct_name := arguments['struct_name'].str()
	result := rust.get_struct_from_file(file_path, struct_name) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result)
	}
}

// --- Get Struct from Module Tool ---

// Specification for get_struct_from_module tool
const get_struct_from_module_spec = mcp.Tool{
	name:         'get_struct_from_module'
	description:  'Get the declaration of a Rust struct from a specified module path (directory or file).'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'module_path': jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to the Rust module directory or file.'
			})
			'struct_name': jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: "Name of the struct to retrieve (e.g., 'MyStruct')."
			})
		}
		required:   ['module_path', 'struct_name']
	}
}

// Handler for get_struct_from_module
pub fn get_struct_from_module_handler(arguments map[string]Any) !mcp.ToolCallResult {
	module_path := arguments['module_path'].str()
	struct_name := arguments['struct_name'].str()
	result := rust.get_struct_from_module(module_path, struct_name) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result)
	}
}
