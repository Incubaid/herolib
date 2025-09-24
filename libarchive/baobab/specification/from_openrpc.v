module specification

import freeflowuniverse.herolib.schemas.openrpc { ContentDescriptor, ErrorSpec, Method, OpenRPC }
import freeflowuniverse.herolib.schemas.jsonschema { Reference, Schema }
import freeflowuniverse.herolib.core.texttools

// Helper function: Convert OpenRPC Method to ActorMethod
fn openrpc_method_to_actor_method(method Method) ActorMethod {
	mut parameters := []ContentDescriptor{}
	mut errors := []ErrorSpec{}

	// Process parameters
	for param in method.params {
		if param is ContentDescriptor {
			parameters << param
		} else {
			panic('Method param should be inflated')
		}
	}

	// Process errors
	for err in method.errors {
		if err is ErrorSpec {
			errors << err
		} else {
			panic('Method error should be inflated')
		}
	}

	if method.result is Reference {
		panic('Method result should be inflated')
	}

	return ActorMethod{
		name:        method.name
		description: method.description
		summary:     method.summary
		parameters:  parameters
		result:      method.result as ContentDescriptor
		errors:      errors
	}
}

// // Helper function: Extract Structs from OpenRPC Components
// fn extract_structs_from_openrpc(openrpc OpenRPC) []Struct {
// 	mut structs := []Struct{}

// 	for schema_name, schema in openrpc.components.schemas {
// 		if schema is Schema {
// 			mut fields := []Struct.Field{}
// 			for field_name, field_schema in schema.properties {
// 				if field_schema is Schema {
// 					fields << Struct.Field{
// 						name: field_name
// 						typ: field_schema.to_code() or { panic(err) }
// 						description: field_schema.description
// 						required: field_name in schema.required
// 					}
// 				}
// 			}

// 			structs << Struct{
// 				name: schema_name
// 				description: schema.description
// 				fields: fields
// 			}
// 		}
// 	}

// 	return structs
// }

// Converts OpenRPC to ActorSpecification
pub fn from_openrpc(spec OpenRPC) !ActorSpecification {
	mut methods := []ActorMethod{}
	mut objects := []BaseObject{}

	// Process methods
	for method in spec.methods {
		methods << openrpc_method_to_actor_method(spec.inflate_method(method))
	}

	// Process objects (schemas)
	// structs := extract_structs_from_openrpc(spec)
	for key, schema in spec.components.schemas {
		if schema is Schema {
			if schema.typ == 'object' {
				objects << BaseObject{
					schema: Schema{
						...schema
						title: texttools.pascal_case(key)
						id:    texttools.snake_case(key)
					}
				}
			}
		}
	}

	return ActorSpecification{
		name:        spec.info.title
		description: spec.info.description
		interfaces:  [.openrpc]
		methods:     methods
		objects:     objects
	}
}
