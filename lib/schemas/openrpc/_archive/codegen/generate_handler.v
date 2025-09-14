module codegen

import freeflowuniverse.herolib.core.code { CodeItem, CustomCode, Function, Param, Struct, VFile, parse_import }
import freeflowuniverse.herolib.schemas.openrpc { OpenRPC }
import freeflowuniverse.herolib.core.texttools
import rand

pub fn generate_handler_file(o OpenRPC, receiver Struct, method_map map[string]Function, object_map map[string]Struct) !VFile {
	name := texttools.name_fix(o.info.title)

	imports := [
		parse_import('freeflowuniverse.herolib.schemas.jsonrpc'),
		parse_import('json'),
		parse_import('x.json2'),
		parse_import('import freeflowuniverse.herolib.core.texttools'),
	]

	mut file := VFile{
		name:    'handler'
		mod:     name
		imports: imports
		// TODO
		// items: jsonrpc.generate_handler(
		// 	methods: method_map.values()
		// 	receiver: receiver
		// )!
	}

	for key, object in object_map {
		file.add_import(mod: object.mod, types: [object.name])!
	}
	return file
}

pub fn generate_handler_test_file(o OpenRPC, receiver Struct, method_map map[string]Function, object_map map[string]Struct) !VFile {
	name := texttools.name_fix(o.info.title)

	handler_name := texttools.snake_case(receiver.name)

	consts := CustomCode{"const actor_name = '${handler_name}_test_actor'"}
	clean_code := 'mut actor := get(name: actor_name)!\nactor.backend.reset()!'

	testsuite_begin := Function{
		name: 'testsuite_begin'
		body: clean_code
	}

	testsuite_end := Function{
		name: 'testsuite_end'
		body: clean_code
	}

	mut handle_tests := []Function{}
	for key, method in method_map {
		if method.params.len == 0 {
			continue
		}
		if method.params[0].typ.symbol()[0].is_capital() {
			continue
		}
		method_handle_test := Function{
			name:   'test_handle_${method.name}'
			result: Param{
				is_result: true
			}
			body:   "mut handler := ${receiver.name}Handler {${handler_name}.get(name: actor_name)!}
		request := new_jsonrpcrequest[${method.params[0].typ.symbol()}]('${method.name}', ${get_mock_value(method.params[0].typ.symbol())!})
		response_json := handler.handle(request.to_json())!"
		}
		handle_tests << method_handle_test
	}

	mut items := []CodeItem{}

	items = [
		consts,
		testsuite_begin,
		testsuite_end,
	]

	items << handle_tests.map(CodeItem(it))

	imports := parse_import('freeflowuniverse.herolib.schemas.jsonrpc {new_jsonrpcrequest, jsonrpcresponse_decode, jsonrpcerror_decode}')

	mut file := VFile{
		name:    'handler_test'
		mod:     name
		imports: [imports]
		items:   items
	}

	for key, object in object_map {
		file.add_import(mod: object.mod, types: [object.name])!
	}
	return file
}

fn get_mock_value(typ string) !string {
	if typ == 'string' {
		return "'mock_string_${rand.string(3)}'"
	} else if typ == 'int' || typ == 'u32' {
		return '42'
	} else {
		return error('mock values for types other than strings and ints are not yet supported')
	}
}

// pub fn ()
