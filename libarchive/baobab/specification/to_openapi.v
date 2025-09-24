module specification

import freeflowuniverse.herolib.schemas.jsonschema { Schema, SchemaRef }
import freeflowuniverse.herolib.schemas.openapi { Components, Info, MediaType, OpenAPI, Operation, Parameter, PathItem, ResponseSpec, ServerSpec }
import net.http

// Converts ActorSpecification to OpenAPI
pub fn (s ActorSpecification) to_openapi() OpenAPI {
	if openapi_spec := s.openapi {
		return openapi_spec
	}
	mut paths := map[string]PathItem{}

	// Map ActorMethods to paths
	for method in s.methods {
		op := method.to_openapi_operation()
		paths['${method.http_path()}'] = match method.http_method() {
			.get {
				PathItem{
					get: op
				}
			}
			else {
				panic('unsupported http method')
			}
		}
		// Assign operation to corresponding HTTP method
		// TODO: what about other verbs
	}

	mut schemas := map[string]SchemaRef{}
	for object in s.objects {
		schemas[object.schema.id] = object.to_schema()
	}

	return OpenAPI{
		openapi:    '3.0.0'
		info:       Info{
			title:       s.name
			summary:     s.description
			description: s.description
			version:     '1.0.0'
		}
		servers:    [
			ServerSpec{
				url:         'http://localhost:8080'
				description: 'Default server'
			},
		]
		paths:      paths
		components: Components{
			schemas: schemas
		}
	}
}

fn (bo BaseObject) to_schema() Schema {
	return Schema{}
}

fn (m ActorMethod) http_path() string {
	return m.name
}

fn (m ActorMethod) http_method() http.Method {
	return .get
}

fn (method ActorMethod) to_openapi_operation() Operation {
	mut op := Operation{
		summary:      method.summary
		description:  method.description
		operation_id: method.name
	}

	// Convert parameters to OpenAPI format
	for param in method.parameters {
		op.parameters << Parameter{
			name:        param.name
			in_:         'query' // Default to query parameters; adjust based on function context
			description: param.description
			required:    param.required
			schema:      param.schema
		}
	}

	// if method.is_void()
	op.responses['200'] = ResponseSpec{
		description: method.description
		content:     {
			'application/json': MediaType{
				schema: method.result.schema
			}
		}
	}
	return op
}
