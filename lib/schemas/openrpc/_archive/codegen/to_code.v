module codegen

import freeflowuniverse.herolib.core.code { Function, Struct }
import freeflowuniverse.herolib.schemas.jsonschema.codegen as jsonschema_codegen { schema_to_struct, schemaref_to_type }
import freeflowuniverse.herolib.schemas.jsonschema { Schema }
import freeflowuniverse.herolib.schemas.openrpc { ContentDescriptor, Method }
import freeflowuniverse.herolib.core.texttools

// converts OpenRPC Method to Code Function
pub fn method_to_function(method Method) !Function {
	mut params := []code.Param{}
	for param in method.params {
		if param is ContentDescriptor {
			params << content_descriptor_to_parameter(param)!
		}
	}
	result := if method.result is ContentDescriptor {
		content_descriptor_to_parameter(method.result)!
	} else {
		panic('Method must be inflated')
	}

	return Function{
		name:   texttools.snake_case(method.name)
		params: params
		result: result
	}
}

pub fn content_descriptor_to_struct(cd ContentDescriptor) Struct {
	if cd.schema is Schema {
		mut struct_ := schema_to_struct(cd.schema)
		if struct_.name == '' || struct_.name == 'Unknown' {
			struct_.name = cd.name
		}
		return struct_
	} else {
		panic('Struct code can be generated only from content descriptor with non-reference schema')
	}
}

pub fn content_descriptor_to_parameter(cd ContentDescriptor) !code.Param {
	return code.Param{
		name: cd.name
		typ:  schemaref_to_type(cd.schema)
	}
}

// //
// pub fn (s Schema) to_struct() code.Struct {
// 	mut attributes := []Attribute{}
// 	if c.depracated {
// 		attributes << Attribute {name: 'deprecated'}
// 	}
// 	if !c.required {
// 		attributes << Attribute {name: 'params'}
// 	}

// 	return code.Struct {
// 		name: name
// 		description: summary
// 		required: required
// 		schema: Schema {

// 		}
// 		attrs: attributes
// 	}
// }
