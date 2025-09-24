#!/usr/bin/env -S v -n -w -cg -d use_openssl -d json_no_inline_sumtypes -enable-globals run

import freeflowuniverse.herolib.mcp
import freeflowuniverse.herolib.mcp.transport
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.schemas.jsonschema
import x.json2
import os

// Simple tool handler using json2.Any (required by MCP framework)
fn simple_echo_handler(arguments map[string]json2.Any) !mcp.ToolCallResult {
	// Extract message from arguments
	message := if 'message' in arguments {
		arguments['message'].str()
	} else {
		'No message provided'
	}

	return mcp.ToolCallResult{
		is_error: false
		content:  [
			mcp.ToolContent{
				typ:  'text'
				text: 'Echo: ${message}'
			},
		]
	}
}

// Simple math handler using json2.Any
fn simple_add_handler(arguments map[string]json2.Any) !mcp.ToolCallResult {
	// Extract numbers
	num1 := if 'num1' in arguments {
		arguments['num1'].f64()
	} else {
		return mcp.ToolCallResult{
			is_error: true
			content:  [mcp.ToolContent{
				typ:  'text'
				text: 'Missing num1'
			}]
		}
	}

	num2 := if 'num2' in arguments {
		arguments['num2'].f64()
	} else {
		return mcp.ToolCallResult{
			is_error: true
			content:  [mcp.ToolContent{
				typ:  'text'
				text: 'Missing num2'
			}]
		}
	}

	result := num1 + num2
	return mcp.ToolCallResult{
		is_error: false
		content:  [
			mcp.ToolContent{
				typ:  'text'
				text: 'Result: ${result}'
			},
		]
	}
}

// Parse command line arguments
fn parse_args() (transport.TransportMode, int) {
	args := os.args[1..]
	mut mode := transport.TransportMode.stdio
	mut port := 8080

	for i, arg in args {
		match arg {
			'--http' {
				mode = .http
			}
			'--port' {
				if i + 1 < args.len {
					port = args[i + 1].int()
				}
			}
			else {}
		}
	}

	return mode, port
}

fn main() {
	// Parse command line arguments
	mode, port := parse_args()

	// Create a simple backend with basic tools
	backend := mcp.MemoryBackend{
		tools:         {
			'echo': mcp.Tool{
				name:         'echo'
				description:  'Echo back a message'
				input_schema: jsonschema.Schema{
					typ:        'object'
					properties: {
						'message': jsonschema.SchemaRef(jsonschema.Schema{
							typ:         'string'
							description: 'Message to echo back'
						})
					}
					required:   ['message']
				}
			}
			'add':  mcp.Tool{
				name:         'add'
				description:  'Add two numbers'
				input_schema: jsonschema.Schema{
					typ:        'object'
					properties: {
						'num1': jsonschema.SchemaRef(jsonschema.Schema{
							typ:         'number'
							description: 'First number'
						})
						'num2': jsonschema.SchemaRef(jsonschema.Schema{
							typ:         'number'
							description: 'Second number'
						})
					}
					required:   ['num1', 'num2']
				}
			}
		}
		tool_handlers: {
			'echo': simple_echo_handler
			'add':  simple_add_handler
		}
	}

	// Create transport configuration
	transport_config := transport.TransportConfig{
		mode: mode
		http: transport.HttpConfig{
			port:     port
			protocol: .both // Support both JSON-RPC and REST
		}
	}

	// Create and start the server
	mut server := mcp.new_server(backend, mcp.ServerParams{
		config:    mcp.ServerConfiguration{
			server_info: mcp.ServerInfo{
				name:    'simple_http_example'
				version: '1.0.0'
			}
		}
		transport: transport_config
	})!

	if mode == .http {
		println('🚀 Starting HTTP MCP server on port ${port}')
		println('')
		println('📡 Endpoints:')
		println('  JSON-RPC: http://localhost:${port}/jsonrpc')
		println('  Health:   http://localhost:${port}/health')
		println('  Tools:    http://localhost:${port}/api/tools')
		println('')
		println('🧪 Test commands:')
		println('  curl http://localhost:${port}/health')
		println('  curl http://localhost:${port}/api/tools')
		println('  curl -X POST http://localhost:${port}/api/tools/echo/call -H "Content-Type: application/json" -d \'{"message":"Hello World"}\'')
		println('  curl -X POST http://localhost:${port}/api/tools/add/call -H "Content-Type: application/json" -d \'{"num1":5,"num2":3}\'')
		println('')
	} else {
		println('📟 Starting STDIO MCP server')
		println('Ready for JSON-RPC messages on stdin...')
	}

	server.start()!
}
