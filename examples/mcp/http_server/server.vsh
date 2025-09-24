#!/usr/bin/env -S v -n -w -cg -d use_openssl -d json_no_inline_sumtypes -enable-globals run

import freeflowuniverse.herolib.mcp
import freeflowuniverse.herolib.mcp.transport
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.schemas.jsonschema
import x.json2
import os

// Example custom tool handler function
fn my_custom_handler(arguments map[string]json2.Any) !mcp.ToolCallResult {
	return mcp.ToolCallResult{
		is_error: false
		content:  [
			mcp.ToolContent{
				typ:  'text'
				text: 'Hello from HTTP MCP server! Arguments: ${arguments}'
			},
		]
	}
}

// Example of calculating 2 numbers
fn calculate(arguments map[string]json2.Any) !mcp.ToolCallResult {
	// Check if num1 exists and can be converted to a number
	if 'num1' !in arguments {
		return mcp.ToolCallResult{
			is_error: true
			content:  [
				mcp.ToolContent{
					typ:  'text'
					text: 'Missing num1 parameter'
				},
			]
		}
	}

	// Try to get num1 as a number (JSON numbers can be int, i64, or f64)
	num1 := arguments['num1'].f64()

	// Check if num2 exists and can be converted to a number
	if 'num2' !in arguments {
		return mcp.ToolCallResult{
			is_error: true
			content:  [
				mcp.ToolContent{
					typ:  'text'
					text: 'Missing num2 parameter'
				},
			]
		}
	}

	// Try to get num2 as a number
	num2 := arguments['num2'].f64()

	// Calculate the result
	result := num1 + num2
	// Return the result
	return mcp.ToolCallResult{
		is_error: false
		content:  [
			mcp.ToolContent{
				typ:  'text'
				text: 'Result: ${result} (${num1} + ${num2})'
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

	// Create a backend with custom tools and handlers
	backend := mcp.MemoryBackend{
		tools:         {
			'custom_method': mcp.Tool{
				name:         'custom_method'
				description:  'A custom example tool'
				input_schema: jsonschema.Schema{
					typ:        'object'
					properties: {
						'message': jsonschema.SchemaRef(jsonschema.Schema{
							typ:         'string'
							description: 'A message to process'
						})
					}
					required:   ['message']
				}
			}
			'calculate':     mcp.Tool{
				name:         'calculate'
				description:  'Calculates the sum of two numbers'
				input_schema: jsonschema.Schema{
					typ:        'object'
					properties: {
						'num1': jsonschema.SchemaRef(jsonschema.Schema{
							typ:         'number'
							description: 'The first number'
						})
						'num2': jsonschema.SchemaRef(jsonschema.Schema{
							typ:         'number'
							description: 'The second number'
						})
					}
					required:   ['num1', 'num2']
				}
			}
		}
		tool_handlers: {
			'custom_method': my_custom_handler
			'calculate':     calculate
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
				name:    'http_example'
				version: '1.0.0'
			}
		}
		transport: transport_config
	})!

	if mode == .http {
		println('Starting HTTP MCP server on port ${port}')
		println('JSON-RPC endpoint: http://localhost:${port}/jsonrpc')
		println('REST API endpoints:')
		println('  GET  http://localhost:${port}/api/tools')
		println('  POST http://localhost:${port}/api/tools/calculate/call')
		println('  POST http://localhost:${port}/api/tools/custom_method/call')
		println('  GET  http://localhost:${port}/health')
	} else {
		println('Starting STDIO MCP server')
	}

	server.start()!
}
