module generator

import json
import freeflowuniverse.herolib.core.code { File, Folder }
import freeflowuniverse.herolib.schemas.openapi { OpenAPI, Operation }
import freeflowuniverse.herolib.schemas.openapi.codegen
import freeflowuniverse.herolib.schemas.jsonschema.codegen as jsonschema_codegen { schema_to_type }
import net.http

pub fn generate_openapi_file(specification OpenAPI) !File {
	openapi_json := specification.encode_json()
	return File{
		name:      'openapi'
		extension: 'json'
		content:   openapi_json
	}
}

pub fn generate_openapi_ts_client(specification OpenAPI) !Folder {
	return codegen.ts_client_folder(specification,
		body_generator:     body_generator
		custom_client_code: '    private restClient: HeroRestClient;

    constructor(heroKeysClient: any, debug: boolean = true) {
        this.restClient = new HeroRestClient(heroKeysClient, debug);
    }
'
	)!
}

fn body_generator(op Operation, path_ string, method http.Method) string {
	path := path_.replace('{', '\${')
	return match method {
		.post {
			if schema := op.payload_schema() {
				symbol := schema_to_type(schema).typescript()
				"return this.restClient.post<${symbol}>('${path}', data);"
			} else {
				''
			}
		}
		.get {
			if schema := op.response_schema() {
				// if op.params.len
				symbol := schema_to_type(schema).typescript()
				"return this.restClient.get<${symbol}>('${path}', data);"
			} else {
				''
			}
		}
		else {
			''
		}
	}
	// return if operation_is_base_object_method(op) {
	// 	bo_method := operation_to_base_object_method(op)
	// 	match method_type(op) {
	// 		.new { ts_client_new_body(op, path) }
	// 		.get { ts_client_get_body(op, path) }
	// 		.set { ts_client_set_body(op, path) }
	// 		.delete { ts_client_delete_body(op, path) }
	// 		.list { ts_client_list_body(op, path) }
	// 		else {''}
	// 	}
	// } else {''}
}

// pub fn operation_is_base_object_method(op openapi.Operation, base_objs []string) BaseObjectMethod {
// 	// name := texttools.pascal_case(op.operation_id)

// 	// if op.operation_id.starts_with('new') {
// 	// 	if op.&& operation.params.len == 1

// 	return true
// }

// pub fn operation_to_base_object_method(op openapi.Operation) BaseObjectMethod {
// 	if op.operation_id.starts_with('update')
// }

// pub fn openapi_ts_client_body(op openapi.Operation, path string, method http.Method) string {
// 	match method {
// 		post {
// 			if schema := op.payload_schema() {
// 				symbol := schema_to_type(schema).typescript()
// 				return "return this.restClient.post<${symbol}>('${path}', data);"
// 			}
// 		}
// 	}

// return if operation_is_base_object_method(op) {
// 	bo_method := operation_to_base_object_method(op)
// 	match bo_method. {
// 		.new { ts_client_new_body(op, path) }
// 		.get { ts_client_get_body(op, path) }
// 		.set { ts_client_set_body(op, path) }
// 		.delete { ts_client_delete_body(op, path) }
// 		.list { ts_client_list_body(op, path) }
// 		else {''}
// 	}
// } else {''}
// }

fn get_endpoint(path string) string {
	return if path == '' {
		''
	} else {
		'/${path.trim('/')}'
	}
}

// // generates a Base Object's `create` method
// fn ts_client_new_body(op Operation, path string) string {
// 	// the parameter of a base object new method is always the base object
// 	bo_param := openapi_codegen.parameter_to_param(op.parameters[0])
// 	return "return this.restClient.post<${bo_param.typ.typescript()}>('${get_endpoint(path)}', ${bo_param.name});"
// }

// // generates a Base Object's `create` method
// fn ts_client_get_body(op Operation, path string) string {
// 	// the parameter of a base object get method is always the id
// 	id_param := openapi_codegen.parameter_to_param(op.parameters[0])
// 	return "return this.restClient.get<${id_param.typ.typescript()}>('${get_endpoint(path)}', ${id_param.name});"
// }

// // generates a Base Object's `create` method
// fn ts_client_set_body(op Operation, path string) string {
// 	// the parameter of a base object set method is always the base object
// 	bo_param := openapi_codegen.parameter_to_param(op.parameters[0])
// 	return "return this.restClient.put<${bo_param.typ.typescript()}>('${get_endpoint(path)}', ${bo_param.name});"
// }

// // generates a Base Object's `delete` method
// fn ts_client_delete_body(op Operation, path string) string {
// 	// the parameter of a base object delete method is always the id
// 	id_param := openapi_codegen.parameter_to_param(op.parameters[0])
// 	return "return this.restClient.get<${id_param.typ.typescript()}>('${get_endpoint(path)}', ${id_param.name});"
// }

// // generates a Base Object's `list` method
// fn ts_client_list_body(op Operation, path string) string {
// 	// the result parameter of a base object list method is always the array of bo
// 	result_param := openapi_codegen.parameter_to_param(op.parameters[0])
// 	return "return this.restClient.get<${result_param.typ.typescript()}>('${get_endpoint(path)}');"
// }

// pub enum BaseObjectMethodType {
// 	new
// 	get
// 	set
// 	delete
// 	list
// 	other
// }

// pub struct BaseObjectMethod {
// pub:
// 	typ BaseObjectMethodType
// 	object string // the name of the base object
// }
