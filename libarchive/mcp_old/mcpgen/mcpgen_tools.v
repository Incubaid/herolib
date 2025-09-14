module mcpgen

import freeflowuniverse.herolib.mcp
import freeflowuniverse.herolib.core.code
import freeflowuniverse.herolib.schemas.jsonschema
import x.json2 as json { Any }
// import json

// create_mcp_tools_code MCP Tool
// create_mcp_tool_code receives the name of a V language function string, and the path to the module in which it exists.
// returns an MCP Tool code in v for attaching the function to the mcp server
// function_pointers: A list of function pointers to generate tools for

const create_mcp_tools_code_tool = mcp.Tool{
	name:         'create_mcp_tools_code'
	description:  'create_mcp_tool_code receives the name of a V language function string, and the path to the module in which it exists.
returns an MCP Tool code in v for attaching the function to the mcp server
function_pointers: A list of function pointers to generate tools for'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'function_pointers': jsonschema.SchemaRef(jsonschema.Schema{
				typ:   'array'
				items: jsonschema.Items(jsonschema.SchemaRef(jsonschema.Schema{
					typ:        'object'
					properties: {
						'name':        jsonschema.SchemaRef(jsonschema.Schema{
							typ: 'string'
						})
						'module_path': jsonschema.SchemaRef(jsonschema.Schema{
							typ: 'string'
						})
					}
					required:   ['name', 'module_path']
				}))
			})
		}
		required:   ['function_pointers']
	}
}

pub fn (d &MCPGen) create_mcp_tools_code_tool_handler(arguments map[string]Any) !mcp.ToolCallResult {
	function_pointers := json.decode[[]FunctionPointer](arguments['function_pointers'].str())!
	result := d.create_mcp_tools_code(function_pointers) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result)
	}
}

const create_mcp_tool_code_tool = mcp.Tool{
	name:         'create_mcp_tool_code'
	description:  'create_mcp_tool_code receives the name of a V language function string, and the path to the module in which it exists.
returns an MCP Tool code in v for attaching the function to the mcp server'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'function_name': jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
			'module_path':   jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
		}
		required:   ['function_name', 'module_path']
	}
}

pub fn (d &MCPGen) create_mcp_tool_code_tool_handler(arguments map[string]Any) !mcp.ToolCallResult {
	function_name := arguments['function_name'].str()
	module_path := arguments['module_path'].str()
	result := d.create_mcp_tool_code(function_name, module_path) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  result_to_mcp_tool_contents[string](result)
	}
}

// Tool definition for the create_mcp_tool function
const create_mcp_tool_const_tool = mcp.Tool{
	name:         'create_mcp_tool_const'
	description:  'Parses a V language function string and returns an MCP Tool struct. This tool analyzes function signatures, extracts parameters, and generates the appropriate MCP Tool representation.'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'function': jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
			'types':    jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'object'
			})
		}
		required:   ['function']
	}
}

pub fn (d &MCPGen) create_mcp_tool_const_tool_handler(arguments map[string]Any) !mcp.ToolCallResult {
	function := json.decode[code.Function](arguments['function'].str())!
	types := json.decode[map[string]string](arguments['types'].str())!
	result := d.create_mcp_tool(function, types) or { return mcp.error_tool_call_result(err) }
	return mcp.ToolCallResult{
		is_error: false
		content:  result_to_mcp_tool_contents[string](result.str())
	}
}

// Tool definition for the create_mcp_tool_handler function
const create_mcp_tool_handler_tool = mcp.Tool{
	name:         'create_mcp_tool_handler'
	description:  'Generates a tool handler for the create_mcp_tool function. This tool handler accepts function string and types map and returns an MCP ToolCallResult.'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'function': jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
			'types':    jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'object'
			})
			'result':   jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
		}
		required:   ['function', 'result']
	}
}

// Tool handler for the create_mcp_tool_handler function
pub fn (d &MCPGen) create_mcp_tool_handler_tool_handler(arguments map[string]Any) !mcp.ToolCallResult {
	function := json.decode[code.Function](arguments['function'].str())!
	types := json.decode[map[string]string](arguments['types'].str())!
	result_ := arguments['result'].str()
	result := d.create_mcp_tool_handler(function, types, result_) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  result_to_mcp_tool_contents[string](result)
	}
}
