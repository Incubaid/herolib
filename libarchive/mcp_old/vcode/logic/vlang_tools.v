module vcode

import freeflowuniverse.herolib.mcp
import freeflowuniverse.herolib.core.code
import freeflowuniverse.herolib.schemas.jsonschema
import x.json2 { Any }

const get_function_from_file_tool = mcp.Tool{
	name:         'get_function_from_file'
	description:  'get_function_from_file parses a V file and extracts a specific function block including its comments
ARGS:
file_path string - path to the V file
function_name string - name of the function to extract
RETURNS: string - the function block including comments, or empty string if not found'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'file_path':     jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
			'function_name': jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
		}
		required:   ['file_path', 'function_name']
	}
}

pub fn (d &VCode) get_function_from_file_tool_handler(arguments map[string]Any) !mcp.ToolCallResult {
	file_path := arguments['file_path'].str()
	function_name := arguments['function_name'].str()
	result := code.get_function_from_file(file_path, function_name) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result.vgen())
	}
}
