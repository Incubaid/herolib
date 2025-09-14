module vcode

import freeflowuniverse.herolib.mcp
import freeflowuniverse.herolib.core.code
import freeflowuniverse.herolib.schemas.jsonschema
import x.json2 { Any }

const write_vfile_tool = mcp.Tool{
	name:         'write_vfile'
	description:  'write_vfile parses a V code string into a VFile and writes it to the specified path
ARGS:
path string - directory path where to write the file
code string - V code content to write
format bool - whether to format the code (optional, default: false)
overwrite bool - whether to overwrite existing file (optional, default: false)
prefix string - prefix to add to the filename (optional, default: "")
RETURNS: string - success message with the path of the written file'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'path':      jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
			'code':      jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
			'format':    jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'boolean'
			})
			'overwrite': jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'boolean'
			})
			'prefix':    jsonschema.SchemaRef(jsonschema.Schema{
				typ: 'string'
			})
		}
		required:   ['path', 'code']
	}
}

pub fn (d &VCode) write_vfile_tool_handler(arguments map[string]Any) !mcp.ToolCallResult {
	path := arguments['path'].str()
	code_str := arguments['code'].str()

	// Parse optional parameters with defaults
	format := if 'format' in arguments { arguments['format'].bool() } else { false }
	overwrite := if 'overwrite' in arguments { arguments['overwrite'].bool() } else { false }
	prefix := if 'prefix' in arguments { arguments['prefix'].str() } else { '' }

	// Create write options
	options := code.WriteOptions{
		format:    format
		overwrite: overwrite
		prefix:    prefix
	}

	// Parse the V code string into a VFile
	vfile := code.parse_vfile(code_str) or { return mcp.error_tool_call_result(err) }

	// Write the VFile to the specified path
	vfile.write(path, options) or { return mcp.error_tool_call_result(err) }

	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string]('Successfully wrote V file to ${path}')
	}
}
