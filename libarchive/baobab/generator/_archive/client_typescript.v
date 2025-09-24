module generator

import freeflowuniverse.herolib.core.code
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.schemas.jsonschema.codegen
import freeflowuniverse.herolib.schemas.openrpc.codegen as openrpc_codegen
import freeflowuniverse.herolib.baobab.specification
import net.http

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

// pub fn ts_client_get_fn(object string, params TSClientFunctionParams) string {
//     name_snake := texttools.snake_case(object)
//     name_pascal := texttools.pascal_case(object)
//     root := get_endpoint_root(params.endpoint)

//     return "async get${name_pascal}(id: string): Promise<${name_pascal}> {\n        return this.restClient.get<${name_pascal}>(`/${root}/${name_snake}/\${id}`);\n    }"
// }

// pub fn ts_client_set_fn(object string, params TSClientFunctionParams) string {
//     name_snake := texttools.snake_case(object)
//     name_pascal := texttools.pascal_case(object)
//     root := get_endpoint_root(params.endpoint)

//     return "async set${name_pascal}(id: string, ${name_snake}: Partial<${name_pascal}>): Promise<${name_pascal}> {\n        return this.restClient.put<${name_pascal}>(`/${root}/${name_snake}/\${id}`, ${name_snake});\n    }"
// }

// pub fn ts_client_delete_fn(object string, params TSClientFunctionParams) string {
//     name_snake := texttools.snake_case(object)
//     name_pascal := texttools.pascal_case(object)
//     root := get_endpoint_root(params.endpoint)

//     return "async delete${name_pascal}(id: string): Promise<void> {\n        return this.restClient.delete<void>(`/${root}/${name_snake}/\${id}`);\n    }"
// }

// pub fn ts_client_list_fn(object string, params TSClientFunctionParams) string {
//     name_snake := texttools.snake_case(object)
//     name_pascal := texttools.pascal_case(object)
//     root := get_endpoint_root(params.endpoint)

//     return "async list${name_pascal}(): Promise<${name_pascal}[]> {\n        return this.restClient.get<${name_pascal}[]>(`/${root}/${name_snake}`);\n    }"
// }

fn get_endpoint_root(root string) string {
	return if root == '' {
		''
	} else {
		'/${root.trim('/')}'
	}
}

// // generates a Base Object's `create` method
// pub fn ts_client_new_fn(object string, params TSClientFunctionParams) string {
// 	name_snake := texttools.snake_case(object)
// 	name_pascal := texttools.pascal_case(object)
// 	root := get_endpoint_root(params.endpoint)

// 	return "async create${name_snake}(object: Omit<${name_pascal}, 'id'>): Promise<${name_pascal}> {
//         return this.restClient.post<${name_pascal}>('${root}/${name_snake}', board);
//     }"
// }

// pub fn ts_client_get_fn(object string, params TSClientFunctionParams) string {
//     name_snake := texttools.snake_case(object)
//     name_pascal := texttools.pascal_case(object)
//     root := get_endpoint_root(params.endpoint)

//     return "async get${name_pascal}(id: string): Promise<${name_pascal}> {\n        return this.restClient.get<${name_pascal}>(`/${root}/${name_snake}/\${id}`);\n    }"
// }

// pub fn ts_client_set_fn(object string, params TSClientFunctionParams) string {
//     name_snake := texttools.snake_case(object)
//     name_pascal := texttools.pascal_case(object)
//     root := get_endpoint_root(params.endpoint)

//     return "async set${name_pascal}(id: string, ${name_snake}: Partial<${name_pascal}>): Promise<${name_pascal}> {\n        return this.restClient.put<${name_pascal}>(`/${root}/${name_snake}/\${id}`, ${name_snake});\n    }"
// }

// pub fn ts_client_delete_fn(object string, params TSClientFunctionParams) string {
//     name_snake := texttools.snake_case(object)
//     name_pascal := texttools.pascal_case(object)
//     root := get_endpoint_root(params.endpoint)

//     return "async delete${name_pascal}(id: string): Promise<void> {\n        return this.restClient.delete<void>(`/${root}/${name_snake}/\${id}`);\n    }"
// }

// pub fn ts_client_list_fn(object string, params TSClientFunctionParams) string {
//     name_snake := texttools.snake_case(object)
//     name_pascal := texttools.pascal_case(object)
//     root := get_endpoint_root(params.endpoint)

//     return "async list${name_pascal}(): Promise<${name_pascal}[]> {\n        return this.restClient.get<${name_pascal}[]>(`/${root}/${name_snake}`);\n    }"
// }

// // generates a function prototype given an `ActorMethod`
// pub fn ts_client_fn_prototype(method ActorMethod) string {
// 	name := texttools.pascal_case(method.name)
// 	params := method.parameters
// 		.map(content_descriptor_to_parameter(it) or {panic(err)})
// 		.map(it.typescript())
// 		.join(', ')

// 	return_type := content_descriptor_to_parameter(method.result) or {panic(err)}.typ.typescript()
// 	return 'async ${name}(${params}): Promise<${return_type}> {}'
// }
