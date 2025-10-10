module mcp

import freeflowuniverse.herolib.ai.mcp
import x.json2 as json
import freeflowuniverse.herolib.schemas.jsonschema
import log

const specs = mcp.Tool{
	name:         'rhai_interface'
	description:  'Add Rhai Interface to Rust Code Files'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'path': jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to a .rs file or directory containing .rs files to make rhai interface for'
			})
		}
		required:   ['path']
	}
}
