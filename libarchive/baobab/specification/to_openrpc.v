module specification

import freeflowuniverse.herolib.schemas.openrpc { Components, OpenRPC }
import freeflowuniverse.herolib.schemas.jsonschema { SchemaRef }
import freeflowuniverse.herolib.schemas.jsonschema.codegen

// pub fn from_openrpc(spec openrpc.OpenRPC) !ActorSpecification {
// 	// Extract Actor metadata from OpenRPC info
// 	// actor_name := openrpc_doc.info.title
// 	// actor_description := openrpc_doc.info.description

// 	// // Generate methods
// 	// mut methods := []ActorMethod{}
// 	// for method in openrpc_doc.methods {
// 	// 	method_code := method.to_code()! // Using provided to_code function
// 	// 	methods << ActorMethod{
// 	// 		name: method.name
// 	// 		func: method_code
// 	// 	}
// 	// }

// 	// // Generate BaseObject structs from schemas
// 	// mut objects := []BaseObject{}
// 	// for key, schema_ref in openrpc_doc.components.schemas {
// 	// 	struct_obj := schema_ref.to_code()! // Assuming schema_ref.to_code() converts schema to Struct
// 	// 	// objects << BaseObject{
// 	// 	// 	structure: code.Struct{
// 	// 	// 		name: struct_obj.name
// 	// 	// 	}
// 	// 	// }
// 	// }

// 	// Build the Actor struct
// 	return ActorSpecification{
// 		// name: actor_name
// 		// description: actor_description
// 		// methods: methods
// 		// objects: objects
// 	}
// }

pub fn (specification ActorSpecification) to_openrpc() OpenRPC {
	mut schemas := map[string]SchemaRef{}
	for obj in specification.objects {
		schemas[obj.schema.id] = obj.schema
		// for child in obj.children {
		// 	schemas[child.name] = struct_to_schema(child)
		// }
	}
	return OpenRPC{
		info:       openrpc.Info{
			title:   specification.name.title()
			version: '1.0.0'
		}
		methods:    specification.methods.map(method_to_openrpc_method(it))
		components: Components{
			schemas: schemas
		}
	}
}

pub fn method_to_openrpc_method(method ActorMethod) openrpc.Method {
	return openrpc.Method{
		name:        method.name
		summary:     method.summary
		description: method.description
		params:      method.parameters.map(openrpc.ContentDescriptorRef(it))
		result:      openrpc.ContentDescriptorRef(method.result)
		errors:      method.errors.map(openrpc.ErrorRef(it))
	}
}
