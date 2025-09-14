module mcp

import freeflowuniverse.herolib.mcp
import freeflowuniverse.herolib.core.code
import freeflowuniverse.herolib.mcp.rhai.logic
import freeflowuniverse.herolib.schemas.jsonschema
import x.json2 as json { Any }

// Tool definition for the generate_rhai_wrapper function
const generate_rhai_wrapper_spec = mcp.Tool{
	name:         'generate_rhai_wrapper'
	description:  'generate_rhai_wrapper receives the name of a V language function string, and the path to the module in which it exists.'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'name':        jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
			'source_path': jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
		}
		required:   ['name', 'source_path']
	}
}

// Tool handler for the generate_rhai_wrapper function
pub fn generate_rhai_wrapper_handler(arguments map[string]Any) !mcp.ToolCallResult {
	name := arguments['name'].str()
	source_path := arguments['source_path'].str()
	result := logic.generate_rhai_wrapper(name, source_path) or {
		return mcp.error_tool_call_result(err)
	}
	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](result)
	}
}
