module openrpc

import net.websocket
import freeflowuniverse.herolib.core.redisclient
import json
import rand

// WebSocket server that receives RPC requests
pub struct WSServer {
mut:
	redis &redisclient.Redis
	queue &redisclient.RedisQueue
	port  int = 8080 // Default port, can be configured
}

// Create new WebSocket server
pub fn new_ws_server(port int) !&WSServer {
	mut redis := redisclient.core_get()!
	return &WSServer{
		redis: redis
		queue: &redisclient.RedisQueue{
			key:   rpc_queue
			redis: redis
		}
		port:  port
	}
}

// Start the WebSocket server
pub fn (mut s WSServer) start() ! {
	mut ws_server := websocket.new_server(.ip, s.port, '')

	// Handle new WebSocket connections
	ws_server.on_connect(fn (mut ws websocket.ServerClient) !bool {
		println('New WebSocket client connected')
		return true
	})!

	// Handle client disconnections
	ws_server.on_close(fn (mut ws websocket.Client, code int, reason string) ! {
		println('WebSocket client disconnected (code: ${code}, reason: ${reason})')
	})

	// Handle incoming messages
	ws_server.on_message(fn [mut s] (mut ws websocket.Client, msg &websocket.Message) ! {
		if msg.opcode != .text_frame {
			println('WebSocket unknown msg opcode (code: ${msg.opcode})')
			return
		}

		// Parse request
		request := json.decode(OpenRPCRequest, msg.payload.bytestr()) or {
			error_msg := '{"jsonrpc":"2.0","error":"Invalid JSON-RPC request","id":null}'
			println(error_msg)
			ws.write(error_msg.bytes(), websocket.OPCode.text_frame) or { panic(err) }
			return
		}

		// Generate unique request ID if not provided
		mut req_id := request.id
		if req_id == 0 {
			req_id = rand.i32_in_range(1, 10000000)!
		}

		println('WebSocket put on queue: \'${rpc_queue}\' (msg: ${msg.payload.bytestr()})')
		// Send request to Redis queue
		s.queue.add(msg.payload.bytestr())!

		returnkey := '${rpc_queue}:${req_id}'
		mut queue_return := &redisclient.RedisQueue{
			key:   returnkey
			redis: s.redis
		}

		// Wait for response
		response := queue_return.get(30)!
		if response.len < 2 {
			error_msg := '{"jsonrpc":"2.0","error":"Timeout waiting for response","id":${req_id}}'
			println('WebSocket error response (err: ${response})')
			ws.write(error_msg.bytes(), websocket.OPCode.text_frame) or { panic(err) }
			return
		}

		println('WebSocket ok response (msg: ${response[1]})')
		// Send response back to WebSocket client
		response_str := response[1].str()
		ws.write(response_str.bytes(), websocket.OPCode.text_frame) or { panic(err) }
	})

	// Start server
	println('WebSocket server listening on port ${s.port}')
	ws_server.listen() or { return error('Failed to start WebSocket server: ${err}') }
}
