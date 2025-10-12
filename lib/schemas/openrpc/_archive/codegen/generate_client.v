module codegen

import incubaid.herolib.develop.codetools as code { CodeItem, CustomCode, Function, Struct, VFile, parse_function }
// import incubaid.herolib.schemas.jsonrpc.codegen {generate_client_struct}
import incubaid.herolib.schemas.openrpc { OpenRPC }
import incubaid.herolib.core.texttools

// generate_structs geenrates struct codes for schemas defined in an openrpc document
pub fn generate_client_file(o OpenRPC, object_map map[string]Struct) !VFile {
	name := texttools.name_fix(o.info.title)
	client_struct_name := '${o.info.title}Client'
	// client_struct := generate_client_struct(client_struct_name)

	mut items := []CodeItem{}
	// code << client_struct
	// code << jsonrpc.generate_ws_factory_code(client_struct_name)!
	// methods := jsonrpc.generate_client_methods(client_struct, o.methods.map(it.to_code()!))!
	// imports := [code.parse_import('incubaid.herolib.schemas.jsonrpc'),
	// 	code.parse_import('incubaid.herolib.schemas.rpcwebsocket'),
	// 	code.parse_import('log')]
	// code << methods.map(CodeItem(it))
	mut file := VFile{
		name: 'client'
		mod:  name
		// imports: imports
		items: items
	}
	for key, object in object_map {
		file.add_import(mod: object.mod, types: [object.name])!
	}
	return file
}

// generate_structs generates struct codes for schemas defined in an openrpc document
pub fn generate_client_test_file(o OpenRPC, methods_map map[string]Function, object_map map[string]Struct) !VFile {
	name := texttools.name_fix(o.info.title)
	// client_struct_name := '${o.info.title}Client'
	// client_struct := jsonrpc.generate_client_struct(client_struct_name)

	// code << client_struct
	// code << jsonrpc.(client_struct_name)
	// methods := jsonrpc.generate_client_methods(client_struct, o.methods.map(Function{name: it.name}))!

	mut fn_test_factory := parse_function('fn test_new_ws_client() !')!
	fn_test_factory.body = "mut client := new_ws_client(address:'ws://127.0.0.1:\${port}')!"

	mut items := []CodeItem{}
	items << CustomCode{'const port = 3100'}
	items << fn_test_factory
	for key, method in methods_map {
		mut func := parse_function('fn test_${method.name}() !')!
		func_call := method.generate_call(receiver: 'client')!
		func.body = "mut client := new_ws_client(address:'ws://127.0.0.1:\${port}')!\n${func_call}"
		items << func
	}
	mut file := VFile{
		name:    'client_test'
		mod:     name
		imports: [
			code.parse_import('incubaid.herolib.schemas.jsonrpc'),
			code.parse_import('incubaid.herolib.schemas.rpcwebsocket'),
			code.parse_import('log'),
		]
		items:   items
	}

	for key, object in object_map {
		file.add_import(mod: object.mod, types: [object.name])!
	}
	return file
}
