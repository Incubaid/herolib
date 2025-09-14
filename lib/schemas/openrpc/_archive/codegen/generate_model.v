module codegen

import freeflowuniverse.herolib.core.code { CodeItem }
import freeflowuniverse.herolib.schemas.jsonschema { Schema }
import freeflowuniverse.herolib.schemas.jsonschema.codegen as jsonschema_codegen { schema_to_code }
import freeflowuniverse.herolib.schemas.openrpc { OpenRPC }
import freeflowuniverse.herolib.core.texttools

// generate_structs geenrates struct codes for schemas defined in an openrpc document
pub fn generate_model(o OpenRPC) ![]CodeItem {
	components := o.components
	mut structs := []CodeItem{}
	for key, schema_ in components.schemas {
		if schema_ is Schema {
			mut schema := schema_
			if schema.title == '' {
				schema.title = texttools.pascal_case(key)
			}
			structs << schema_to_code(schema)
		}
	}
	return structs
}

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
