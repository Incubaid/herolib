module generator

import freeflowuniverse.herolib.core.code { CodeItem, CustomCode, Function, Import, Param, Result, VFile }
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.schemas.jsonschema.codegen as jsonschema_codegen { schemaref_to_type }
import freeflowuniverse.herolib.schemas.openrpc.codegen { content_descriptor_to_parameter }
import freeflowuniverse.herolib.baobab.specification { ActorMethod, ActorSpecification }

pub fn generate_client_file(spec ActorSpecification) !VFile {
	actor_name_snake := texttools.snake_case(spec.name)
	actor_name_pascal := texttools.pascal_case(spec.name)

	mut items := []CodeItem{}

	items << CustomCode{'
	pub struct Client {
		stage.Client
	}

	fn new_client(config stage.ActorConfig) !Client {
		return Client {
			Client: stage.new_client(config)!
		}
	}'}

	for method in spec.methods {
		items << generate_client_method(method)!
	}

	return VFile{
		imports: [
			Import{
				mod: 'freeflowuniverse.herolib.baobab.stage'
			},
			Import{
				mod: 'freeflowuniverse.herolib.core.redisclient'
			},
			Import{
				mod:   'x.json2 as json'
				types: ['Any']
			},
		]
		name:    'client_actor'
		items:   items
	}
}

pub fn generate_example_client_file(spec ActorSpecification) !VFile {
	actor_name_snake := texttools.snake_case(spec.name)
	actor_name_pascal := texttools.pascal_case(spec.name)

	mut items := []CodeItem{}

	items << CustomCode{"
	pub struct Client {
		stage.Client
	}

	fn new_client() !Client {
		mut redis := redisclient.new('localhost:6379')!
		mut rpc_q := redis.rpc_get('actor_example_\${name}')
		return Client{
			rpc: rpc_q
		}
	}"}

	for method in spec.methods {
		items << generate_client_method(method)!
	}

	return VFile{
		imports: [
			Import{
				mod: 'freeflowuniverse.herolib.baobab.stage'
			},
			Import{
				mod: 'freeflowuniverse.herolib.core.redisclient'
			},
			Import{
				mod:   'x.json2 as json'
				types: ['Any']
			},
		]
		name:    'client'
		items:   items
	}
}

pub fn generate_client_method(method ActorMethod) !Function {
	name_fixed := texttools.snake_case(method.name)

	call_params := if method.parameters.len > 0 {
		method.parameters.map(texttools.snake_case(it.name)).map('Any(${it}.str())').join(', ')
	} else {
		''
	}

	params_stmt := if method.parameters.len == 0 {
		''
	} else if method.parameters.len == 1 {
		'params := json.encode(${texttools.snake_case(method.parameters[0].name)})'
	} else {
		'mut params_arr := []Any{}
		params_arr = [${call_params}]
		params := json.encode(params_arr.str())
		'
	}

	mut client_call_stmt := "action := client.call_to_action(
		name: '${name_fixed}'"

	if params_stmt != '' {
		client_call_stmt += 'params: params'
	}
	client_call_stmt += ')!'

	result_type := schemaref_to_type(method.result.schema).vgen().trim_space()
	result_stmt := if result_type == '' {
		''
	} else {
		'return json.decode[${result_type}](action.result)!'
	}
	result_param := content_descriptor_to_parameter(method.result)!
	return Function{
		receiver:    code.new_param(v: 'mut client Client')!
		result:      Param{
			...result_param
			typ: Result{result_param.typ}
		}
		name:        name_fixed
		body:        '${params_stmt}\n${client_call_stmt}\n${result_stmt}'
		summary:     method.summary
		description: method.description
		params:      method.parameters.map(content_descriptor_to_parameter(it)!)
	}
}
