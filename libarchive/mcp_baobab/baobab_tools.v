module baobab

import freeflowuniverse.herolib.ai.mcp
import freeflowuniverse.herolib.schemas.jsonschema
import freeflowuniverse.herolib.core.code
import x.json2 as json { Any }
import freeflowuniverse.herolib.baobab.generator
import freeflowuniverse.herolib.baobab.specification

// generate_methods_file MCP Tool
//

const generate_methods_file_tool = mcp.Tool{
	name:         'generate_methods_file'
	description:  'Generates a methods file with methods for a backend corresponding to thos specified in an OpenAPI or OpenRPC specification'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'source': jsonschema.SchemaRef(jsonschema.Schema{
				typ:        'object'
				properties: {
					'openapi_path': jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'string'
					})
					'openrpc_path': jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'string'
					})
				}
			})
		}
		required:   ['source']
	}
}

pub fn (d &Baobab) generate_methods_file_tool_handler(arguments map[string]Any) !mcp.ToolCallResult {
	source := json.decode[generator.Source](arguments['source'].str())!
	result := generator.generate_methods_file_str(source) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result)
	}
}

// generate_module_from_openapi MCP Tool
const generate_module_from_openapi_tool = mcp.Tool{
	name:         'generate_module_from_openapi'
	description:  ''
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'openapi_path': jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
		}
		required:   ['openapi_path']
	}
}

pub fn (d &Baobab) generate_module_from_openapi_tool_handler(arguments map[string]Any) !mcp.ToolCallResult {
	openapi_path := arguments['openapi_path'].str()
	result := generator.generate_module_from_openapi(openapi_path) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result)
	}
}

// generate_methods_interface_file MCP Tool
const generate_methods_interface_file_tool = mcp.Tool{
	name:         'generate_methods_interface_file'
	description:  'Generates a methods interface file with method interfaces for a backend corresponding to those specified in an OpenAPI or OpenRPC specification'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'source': jsonschema.SchemaRef(jsonschema.Schema{
				typ:        'object'
				properties: {
					'openapi_path': jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'string'
					})
					'openrpc_path': jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'string'
					})
				}
			})
		}
		required:   ['source']
	}
}

pub fn (d &Baobab) generate_methods_interface_file_tool_handler(arguments map[string]Any) !mcp.ToolCallResult {
	source := json.decode[generator.Source](arguments['source'].str())!
	result := generator.generate_methods_interface_file_str(source) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result)
	}
}

// generate_model_file MCP Tool
const generate_model_file_tool = mcp.Tool{
	name:         'generate_model_file'
	description:  'Generates a model file with data structures for a backend corresponding to those specified in an OpenAPI or OpenRPC specification'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'source': jsonschema.SchemaRef(jsonschema.Schema{
				typ:        'object'
				properties: {
					'openapi_path': jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'string'
					})
					'openrpc_path': jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'string'
					})
				}
			})
		}
		required:   ['source']
	}
}

pub fn (d &Baobab) generate_model_file_tool_handler(arguments map[string]Any) !mcp.ToolCallResult {
	source := json.decode[generator.Source](arguments['source'].str())!
	result := generator.generate_model_file_str(source) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result)
	}
}

// generate_methods_example_file MCP Tool
const generate_methods_example_file_tool = mcp.Tool{
	name:         'generate_methods_example_file'
	description:  'Generates a methods example file with example implementations for a backend corresponding to those specified in an OpenAPI or OpenRPC specification'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'source': jsonschema.SchemaRef(jsonschema.Schema{
				typ:        'object'
				properties: {
					'openapi_path': jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'string'
					})
					'openrpc_path': jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'string'
					})
				}
			})
		}
		required:   ['source']
	}
}

pub fn (d &Baobab) generate_methods_example_file_tool_handler(arguments map[string]Any) !mcp.ToolCallResult {
	source := json.decode[generator.Source](arguments['source'].str())!
	result := generator.generate_methods_example_file_str(source) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result)
	}
}
