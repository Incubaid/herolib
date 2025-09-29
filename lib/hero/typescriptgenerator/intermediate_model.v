module typescriptgenerator

import freeflowuniverse.herolib.schemas.openrpc
import freeflowuniverse.herolib.schemas.jsonschema

// IntermediateSpec is the main object passed to the typescript generator.
pub struct IntermediateSpec {
pub mut:
	info      openrpc.Info
	methods   []IntermediateMethod
	schemas   map[string]IntermediateSchema
	base_url  string 
}

// IntermediateSchema represents a schema in a format that's easy to consume for generation.
pub struct IntermediateSchema {
pub mut:
	name        string
	description string
	properties  []IntermediateProperty
}

// IntermediateMethod holds the information for a single method to be displayed.
pub struct IntermediateMethod {
pub mut:
	name             string
	summary          string
	description      string
	params           []IntermediateParam
	result           IntermediateParam
	endpoint_url     string
}

// IntermediateParam represents a parameter or result in the documentation
pub struct IntermediateParam {
pub mut:
	name        string
	description string
	type_info   string
	required    bool
}

// IntermediateProperty represents a property of a schema
pub struct IntermediateProperty {
pub mut:
    name string
    description string
    type_info string
    required bool
}

// IntermediateConfig holds configuration for documentation generation
pub struct IntermediateConfig {
pub mut:
	base_url     string = 'http://localhost:8080'
	handler_type string = 'heromodels'
}

pub fn from_openrpc(openrpc_spec openrpc.OpenRPC, config IntermediateConfig) !IntermediateSpec {
	if config.handler_type.trim_space() == '' {
		return error('handler_type cannot be empty')
	}

	mut intermediate_spec := IntermediateSpec{
		info:      openrpc_spec.info
		base_url:  config.base_url
		schemas:   process_schemas(openrpc_spec.components.schemas)!
	}

	// Process all methods
	for method in openrpc_spec.methods {
		intermediate_method := process_method(method, config)!
		intermediate_spec.methods << intermediate_method
	}

	return intermediate_spec
}

fn process_method(method openrpc.Method, config IntermediateConfig) !IntermediateMethod {
	// Convert parameters
	intermediate_params := process_parameters(method.params)!

	// Convert result
	intermediate_result := process_result(method.result)!

	intermediate_method := IntermediateMethod{
		name:             method.name
		summary:          method.summary
		description:      method.description
		params:           intermediate_params
		result:           intermediate_result
		endpoint_url:     '${config.base_url}/api/${config.handler_type}'
	}

	return intermediate_method
}

fn process_parameters(params []openrpc.ContentDescriptorRef) ![]IntermediateParam {
	mut intermediate_params := []IntermediateParam{}

	for param in params {
		if param is openrpc.ContentDescriptor {
			type_info := extract_type_from_schema(param.schema)

			intermediate_params << IntermediateParam{
				name:        param.name
				description: param.description
				type_info:   type_info
				required:    param.required
			}
		} else if param is jsonschema.Reference {
			//TODO: handle reference
		}
	}

	return intermediate_params
}

fn process_result(result openrpc.ContentDescriptorRef) !IntermediateParam {
	mut intermediate_result := IntermediateParam{}

	if result is openrpc.ContentDescriptor {
		type_info := extract_type_from_schema(result.schema)

		intermediate_result = IntermediateParam{
			name:        result.name
			description: result.description
			type_info:   type_info
			required:    false // Results are never required
		}
	} else if result is jsonschema.Reference {
		// handle reference
        ref := result as jsonschema.Reference
        type_info := ref.ref.all_after_last('/')
        intermediate_result = IntermediateParam{
			name:       type_info.to_lower()
			type_info:   type_info
		}

	}

	return intermediate_result
}

fn extract_type_from_schema(schema_ref jsonschema.SchemaRef) string {
	schema := match schema_ref {
		jsonschema.Schema {
			schema_ref
		}
		jsonschema.Reference {
            ref := schema_ref as jsonschema.Reference
			return ref.ref.all_after_last('/')
		}
	}

	if schema.typ.len > 0 {
		return schema.typ
	}
	return 'unknown'
}


fn process_schemas(schemas map[string]jsonschema.SchemaRef) !map[string]IntermediateSchema {
    mut intermediate_schemas := map[string]IntermediateSchema{}
    for name, schema_ref in schemas {
        if schema_ref is jsonschema.Schema {
            schema := schema_ref as jsonschema.Schema
            mut properties := []IntermediateProperty{}
            for prop_name, prop_schema_ref in schema.properties {
                prop_type := extract_type_from_schema(prop_schema_ref)
                properties << IntermediateProperty {
                    name: prop_name
                    description: "" // TODO
                    type_info: prop_type
                    required: prop_name in schema.required
                }
            }
            intermediate_schemas[name] = IntermediateSchema {
                name: name
                description: schema.description
                properties: properties
            }
        }
    }
    return intermediate_schemas
}