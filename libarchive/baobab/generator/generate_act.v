module generator

import freeflowuniverse.herolib.core.code { CodeItem, CustomCode, Function, Import, Object, Param, Result, VFile }
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.schemas.openrpc { ContentDescriptor, Example }
import freeflowuniverse.herolib.schemas.jsonschema.codegen { schemaref_to_type }
import freeflowuniverse.herolib.baobab.specification { ActorMethod, ActorSpecification }

fn generate_handle_file(spec ActorSpecification) !VFile {
	mut items := []CodeItem{}
	items << CustomCode{generate_handle_function(spec)}
	for method in spec.methods {
		items << generate_method_handle(spec.name, method)!
	}
	return VFile{
		name:    'act'
		imports: [
			Import{
				mod:   'freeflowuniverse.herolib.baobab.stage'
				types: ['Action']
			},
			Import{
				mod: 'freeflowuniverse.herolib.core.texttools'
			},
			Import{
				mod: 'x.json2 as json'
			},
		]
		items:   items
	}
}

pub fn generate_handle_function(spec ActorSpecification) string {
	actor_name_pascal := texttools.pascal_case(spec.name)
	mut operation_handlers := []string{}
	mut routes := []string{}

	// Iterate over OpenAPI paths and operations
	for method in spec.methods {
		operation_id := method.name
		params := method.parameters.map(it.name).join(', ')

		// Generate route case
		route := generate_route_case(operation_id, 'handle_${operation_id}')
		routes << route
	}

	// Combine the generated handlers and main router into a single file
	return [
		'// AUTO-GENERATED FILE - DO NOT EDIT MANUALLY',
		'',
		'pub fn (mut actor ${actor_name_pascal}Actor) act(action Action) !Action {',
		'    return match texttools.snake_case(action.name) {',
		routes.join('\n'),
		'        else {',
		'            return error("Unknown operation: \${action.name}")',
		'        }',
		'    }',
		'}',
	].join('\n')
}

pub fn generate_method_handle(actor_name string, method ActorMethod) !Function {
	actor_name_pascal := texttools.pascal_case(actor_name)
	name_fixed := texttools.snake_case(method.name)
	mut body := ''
	if method.parameters.len == 1 {
		param := method.parameters[0]
		param_name := texttools.snake_case(param.name)
		decode_stmt := generate_decode_stmt('action.params', param)!
		body += '${param_name} := ${decode_stmt}\n'
	}
	if method.parameters.len > 1 {
		body += 'params_arr := json.raw_decode(action.params)!.arr()\n'
		for i, param in method.parameters {
			param_name := texttools.snake_case(param.name)
			decode_stmt := generate_decode_stmt('params_arr[${i}].str()', param)!
			body += '${param_name} := ${decode_stmt}'
		}
	}
	call_stmt := generate_call_stmt(actor_name, method)!
	body += '${call_stmt}\n'
	body += '${generate_return_stmt(method)!}\n'
	return Function{
		name:        'handle_${name_fixed}'
		description: '// Handler for ${name_fixed}\n'
		receiver:    Param{
			name:    'actor'
			mutable: true
			typ:     Object{'${actor_name_pascal}Actor'}
		}
		params:      [Param{
			name: 'action'
			typ:  Object{'Action'}
		}]
		result:      Param{
			typ: Result{Object{'Action'}}
		}
		body:        body
	}
}

fn method_is_void(method ActorMethod) !bool {
	return schemaref_to_type(method.result.schema).vgen().trim_space() == ''
}

pub fn generate_example_method_handle(actor_name string, method ActorMethod) !Function {
	actor_name_pascal := texttools.pascal_case(actor_name)
	name_fixed := texttools.snake_case(method.name)
	body := if !method_is_void(method)! {
		if method.example.result is Example {
			'return Action{...action, result: json.encode(\'${method.example.result.value}\')}'
		} else {
			'return action'
		}
	} else {
		'return action'
	}
	return Function{
		name:        'handle_${name_fixed}_example'
		description: '// Handler for ${name_fixed}\n'
		receiver:    Param{
			name:    'actor'
			mutable: true
			typ:     Object{'${actor_name_pascal}Actor'}
		}
		params:      [Param{
			name: 'action'
			typ:  Object{'Action'}
		}]
		result:      Param{
			typ: Result{Object{'Action'}}
		}
		body:        body
	}
}

fn generate_call_stmt(name string, method ActorMethod) !string {
	mut call_stmt := if schemaref_to_type(method.result.schema).vgen().trim_space() != '' {
		'${texttools.snake_case(method.result.name)} := '
	} else {
		''
	}
	method_name := texttools.snake_case(method.name)
	snake_name := texttools.snake_case(name)

	param_names := method.parameters.map(texttools.snake_case(it.name))
	call_stmt += 'actor.${snake_name}.${method_name}(${param_names.join(', ')})!'
	return call_stmt
}

fn generate_return_stmt(method ActorMethod) !string {
	if schemaref_to_type(method.result.schema).vgen().trim_space() != '' {
		return 'return Action{...action, result: json.encode(${texttools.snake_case(method.result.name)})}'
	}
	return 'return action'
}

// Helper function to generate a case block for the main router
fn generate_route_case(case string, handler_name string) string {
	name_fixed := texttools.snake_case(handler_name)
	return "'${texttools.snake_case(case)}' {actor.${name_fixed}(action)}"
}

// generates decode statement for variable with given name
fn generate_decode_stmt(name string, param ContentDescriptor) !string {
	param_type := schemaref_to_type(param.schema)
	if param_type is Object {
		return 'json.decode[${schemaref_to_type(param.schema).vgen()}](${name})!'
	} else if param_type is code.Array {
		return 'json.decode[${schemaref_to_type(param.schema).vgen()}](${name})'
	}
	param_symbol := param_type.vgen()
	return if param_symbol == 'string' {
		'${name}.str()'
	} else {
		'${name}.${param_type.vgen()}()'
	}
}
