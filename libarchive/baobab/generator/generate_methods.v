module generator

import freeflowuniverse.herolib.core.code { CodeItem, Function, Import, Param, Result, Struct, VFile }
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.schemas.openapi
import freeflowuniverse.herolib.schemas.openrpc
import freeflowuniverse.herolib.schemas.openrpc.codegen { content_descriptor_to_parameter, content_descriptor_to_struct }
import freeflowuniverse.herolib.schemas.jsonschema { Schema }
import freeflowuniverse.herolib.schemas.jsonschema.codegen as jsonschema_codegen
import freeflowuniverse.herolib.baobab.specification { ActorMethod, ActorSpecification }
import log

const crud_prefixes = ['new', 'get', 'set', 'delete', 'list']

pub struct Source {
	openapi_path ?string
	openrpc_path ?string
}

pub fn generate_methods_file_str(source Source) !string {
	actor_spec := if path := source.openapi_path {
		specification.from_openapi(openapi.new(path: path)!)!
	} else if path := source.openrpc_path {
		specification.from_openrpc(openrpc.new(path: path)!)!
	} else {
		panic('No openapi or openrpc path provided')
	}
	return generate_methods_file(actor_spec)!.write_str()!
}

pub fn generate_methods_file(spec ActorSpecification) !VFile {
	name_snake := texttools.snake_case(spec.name)
	actor_name_pascal := texttools.pascal_case(spec.name)

	receiver := generate_methods_receiver(spec.name)
	receiver_param := Param{
		mutable: true
		name:    name_snake[0].ascii_str() // receiver is first letter of domain
		typ:     Result{code.Object{receiver.name}}
	}

	mut items := [CodeItem(receiver), CodeItem(generate_core_factory(receiver_param))]
	for method in spec.methods {
		items << generate_method_code(receiver_param, ActorMethod{
			...method
			category: spec.method_type(method)
		})!
	}

	return VFile{
		name:    'methods'
		imports: [
			Import{
				mod:   'freeflowuniverse.herolib.baobab.osis'
				types: ['OSIS']
			},
		]
		items:   items
	}
}

fn generate_methods_receiver(name string) Struct {
	return Struct{
		is_pub: true
		name:   '${texttools.pascal_case(name)}'
		fields: [
			code.StructField{
				is_mut: true
				name:   'osis'
				typ:    code.Object{'OSIS'}
			},
		]
	}
}

fn generate_core_factory(receiver Param) Function {
	return Function{
		is_pub: true
		name:   'new_${receiver.typ.symbol()}'
		body:   'return ${receiver.typ.symbol().trim_left('!?')}{osis: osis.new()!}'
		result: receiver
	}
}

// returns bodyless method prototype
pub fn generate_method_code(receiver Param, method ActorMethod) ![]CodeItem {
	result_param := content_descriptor_to_parameter(method.result)!

	mut method_code := []CodeItem{}
	// TODO: document assumption
	obj_params := method.parameters.filter(if it.schema is Schema {
		it.schema.typ == 'object'
	} else {
		false
	}).map(content_descriptor_to_struct(it))
	if obj_param := obj_params[0] {
		method_code << obj_param
	}

	// check if method is a Base Object CRUD Method and
	// if so generate the method's body
	// TODO: smart generation of method body using AI
	// body := match method.category {
	// 	.base_object_new { base_object_new_body(receiver, method)! }
	// 	.base_object_get { base_object_get_body(receiver, method)! }
	// 	.base_object_set { base_object_set_body(receiver, method)! }
	// 	.base_object_delete { base_object_delete_body(receiver, method)! }
	// 	.base_object_list { base_object_list_body(receiver, method)! }
	// 	else { "panic('implement')" }
	// }

	body := "panic('implement')"

	fn_prototype := generate_method_prototype(receiver, method)!
	method_code << Function{
		...fn_prototype
		body: body
	}
	return method_code
}

// returns bodyless method prototype
pub fn generate_method_prototype(receiver Param, method ActorMethod) !Function {
	result_param := content_descriptor_to_parameter(method.result)!
	return Function{
		name:        texttools.snake_case(method.name)
		receiver:    receiver
		result:      Param{
			...result_param
			typ: Result{result_param.typ}
		}
		summary:     method.summary
		description: method.description
		params:      method.parameters.map(content_descriptor_to_parameter(it)!)
	}
}

fn base_object_new_body(receiver Param, method ActorMethod) !string {
	parameter := content_descriptor_to_parameter(method.parameters[0])!
	return 'return ${receiver.name}.osis.new[${parameter.typ.vgen()}](${texttools.snake_case(parameter.name)})!'
}

fn base_object_get_body(receiver Param, method ActorMethod) !string {
	parameter := content_descriptor_to_parameter(method.parameters[0])!
	result := content_descriptor_to_parameter(method.result)!
	return 'return ${receiver.name}.osis.get[${result.typ.vgen()}](${texttools.snake_case(parameter.name)})!'
}

fn base_object_set_body(receiver Param, method ActorMethod) !string {
	parameter := content_descriptor_to_parameter(method.parameters[0])!
	return 'return ${receiver.name}.osis.set[${parameter.typ.vgen()}](${parameter.name})!'
}

fn base_object_delete_body(receiver Param, method ActorMethod) !string {
	parameter := content_descriptor_to_parameter(method.parameters[0])!
	return '${receiver.name}.osis.delete(${texttools.snake_case(parameter.name)})!'
}

fn base_object_list_body(receiver Param, method ActorMethod) !string {
	// result := content_descriptor_to_parameter(method.result)!
	// log.error('result typ: ${result.typ}')
	// base_object_type := (result.typ as Array).typ
	// return 'return ${receiver.name}.osis.list[${base_object_type.symbol()}]()!'
	return 'return'
}
