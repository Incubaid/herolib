module codegen

import freeflowuniverse.herolib.core.code { CustomCode, VFile, parse_function, parse_import }
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.schemas.openrpc { OpenRPC }

// pub fn (mut handler AccountantHandler) handle_ws(client &websocket.Client, message string) string {
// 	return handler.handle(message) or { panic(err) }
// }

// pub fn run_wsserver(port int) ! {
// 	mut logger := log.Logger(&log.Log{level: .debug})
// 	mut handler := AccountantHandler{get(name: 'accountant')!}
// 	mut server := rpcwebsocket.new_rpcwsserver(port, handler.handle_ws, logger)!
// 	server.run()!
// }

pub fn generate_interface_file(specification OpenRPC) !VFile {
	name := texttools.name_fix(specification.info.title)

	mut handle_ws_fn := parse_function('pub fn (mut handler ${name.title()}Handler) handle_ws(client &websocket.Client, message string) string ')!
	handle_ws_fn.body = 'return handler.handle(message) or { panic(err) }'

	mut run_wsserver_fn := parse_function('pub fn run_wsserver(port int) !')!
	run_wsserver_fn.body = "
	log_ := log.Log{level: .debug}
	mut logger := log.Logger(&log_)
	mut handler := ${name.title()}Handler{get(name: '${name}')!}
	mut server := rpcwebsocket.new_rpcwsserver(port, handler.handle_ws, logger)!
	server.run()!"
	items := handle_ws_fn

	return VFile{
		mod:     name
		name:    'server'
		imports: [
			parse_import('log'),
			parse_import('net.websocket'),
			parse_import('freeflowuniverse.herolib.schemas.rpcwebsocket {RpcWsServer}'),
		]
		items:   [
			handle_ws_fn,
			run_wsserver_fn,
		]
	}
}

pub fn generate_interface_test_file(specification OpenRPC) !VFile {
	name := texttools.name_fix(specification.info.title)
	// mut handle_ws_fn := parse_function('pub fn (mut handler ${name.title()}Handler) handle_ws(client &websocket.Client, message string) string ')!
	// handle_ws_fn.body = "return handler.handle(message) or { panic(err) }"

	// mut run_wsserver_fn := parse_function('pub fn run_wsserver(port int) !')!
	// run_wsserver_fn.body = "mut logger := log.Logger(&log.Log{level: .debug})
	// mut handler := ${name.title()}Handler{get(name: '${name}')!}
	// mut server := rpcwebsocket.new_rpcwsserver(port, handler.handle_ws, logger)!
	// server.run()!"
	// items := handle_ws_fn

	mut test_fn := parse_function('pub fn test_wsserver() !')!
	test_fn.body = 'spawn run_wsserver(port)'

	return VFile{
		mod:   name
		name:  'server_test'
		items: [
			CustomCode{'const port = 3000'},
			test_fn,
		]
	}
}
