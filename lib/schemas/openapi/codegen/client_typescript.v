module codegen

import freeflowuniverse.herolib.develop.codetools as code { File, Folder }
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.schemas.jsonschema { Reference, Schema }
import freeflowuniverse.herolib.schemas.jsonschema.codegen { schema_to_struct }
import freeflowuniverse.herolib.schemas.openrpc.codegen as openrpc_codegen
import freeflowuniverse.herolib.schemas.openapi { OpenAPI, Operation }
import freeflowuniverse.herolib.baobab.specification
import net.http

// the body_generator is a function that takes an OpenAPI operation, its path, and its method
// and returns a client function's body. This is used for custom client generation.
pub type BodyGenerator = fn (op Operation, path string, method http.Method) string

fn generate_empty_body(op Operation, path string, method http.Method) string {
	return ''
}

@[params]
pub struct GenerationParams {
pub:
	// by default the TS Client Genrator generates empty bodies
	// for client methods
	custom_client_code string // custom code to be injected into client class
	body_generator     BodyGenerator = generate_empty_body
}

pub fn ts_client_folder(spec OpenAPI, params GenerationParams) !Folder {
	schemas := spec.components.schemas.values()
		.map(if it is Reference { spec.dereference_schema(it)! } else { it as Schema })

	return Folder{
		name:  'client_typescript'
		files: [
			ts_client_model_file(schemas),
			ts_client_methods_file(spec, params),
		]
	}
}

// generates a model.ts file for given base objects
pub fn ts_client_model_file(schemas []Schema) File {
	return File{
		name:      'model'
		extension: 'ts'
		content:   schemas.map(schema_to_struct(it))
			.map(it.typescript())
			.join_lines()
	}
}

// generates a methods.ts file for given actor methods
pub fn ts_client_methods_file(spec OpenAPI, params GenerationParams) File {
	// spec := spec_.validate()
	mut files := []File{}
	mut methods := []string{}

	// for each base object generate ts client methods
	// for the objects existing CRUD+LF methods
	for path, item in spec.paths {
		if item.get.responses.len > 0 {
			methods << ts_client_fn(item.get, path, .get, params)
		}
		if item.put.responses.len > 0 {
			methods << ts_client_fn(item.put, path, .put, params)
		}
		if item.post.responses.len > 0 {
			methods << ts_client_fn(item.post, path, .post, params)
		}
		if item.delete.responses.len > 0 {
			methods << ts_client_fn(item.delete, path, .delete, params)
		}
	}

	client_code := 'export class ${texttools.pascal_case(spec.info.title)}Client {\n${params.custom_client_code}\n${methods.join_lines()}\n}'

	return File{
		name:      'methods'
		extension: 'ts'
		content:   client_code
	}
}

@[params]
pub struct TSClientFunctionParams {
	endpoint string // prefix for the Rest API endpoint
}

// generates a function prototype given an `ActorMethod`
fn ts_client_fn(op Operation, path string, method http.Method, gen GenerationParams) string {
	name := texttools.camel_case(op.operation_id)

	mut params := []code.Param{}
	if op.request_body is openapi.RequestBody {
		if content := op.request_body.content['application/json'] {
			params << media_type_to_param(op.request_body.content['application/json'])
		}
	}
	params << op.parameters.map(parameter_to_param(it))
	params_str := params.map(it.typescript()).join(', ')

	body := gen.body_generator(op, path, method)
	return_type := responses_to_param(op.responses).typ.typescript()
	return 'async ${name}(${params_str}): Promise<${return_type}> {${body}}'
}
