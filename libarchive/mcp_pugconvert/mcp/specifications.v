module mcp

import freeflowuniverse.herolib.ai.mcp
import x.json2 as json
import freeflowuniverse.herolib.schemas.jsonschema
import freeflowuniverse.herolib.ai.mcp.logger

const specs = mcp.Tool{
	name:         'pugconvert'
	description:  'Convert Pug template files to Jet template files'
	input_schema: jsonschema.Schema{
		typ:        'object'
		properties: {
			'path': jsonschema.SchemaRef(jsonschema.Schema{
				typ:         'string'
				description: 'Path to a .pug file or directory containing .pug files to convert'
			})
		}
		required:   ['path']
	}
}
