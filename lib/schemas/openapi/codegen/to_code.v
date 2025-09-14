module codegen

import freeflowuniverse.herolib.develop.codetools as code
import freeflowuniverse.herolib.schemas.jsonschema.codegen as jsonschema_codegen { schemaref_to_type }
import freeflowuniverse.herolib.schemas.openapi { ResponseSpec }

// converts OpenAPI Parameter Specification
// to code param specification
pub fn media_type_to_param(mt openapi.MediaType) code.Param {
	return code.Param{
		name: 'data'
		typ:  schemaref_to_type(mt.schema)
	}
}

// converts OpenAPI Parameter Specification
// to code param specification
pub fn parameter_to_param(parameter openapi.Parameter) code.Param {
	return code.Param{
		name:        parameter.name
		typ:         schemaref_to_type(parameter.schema)
		description: parameter.description
	}
}

// converts OpenAPI map[string]ResponseSpec Specification
// to code param specification
pub fn responses_to_param(responses map[string]ResponseSpec) code.Param {
	response_type := if '200' in responses {
		if 'application/json' in responses['200'].content {
			schemaref_to_type(responses['200'].content['application/json'].schema)
		} else {
			code.Void{}
		}
	} else {
		code.Void{}
	}

	return code.Param{
		name: 'ok'
		typ:  if responses.errors().len > 0 {
			code.Result{response_type}
		} else {
			response_type
		}
	}
}
