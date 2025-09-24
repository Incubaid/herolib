#!/usr/bin/env -S v -n -w -cg -d use_openssl -d json_no_inline_sumtypes -enable-globals run

import freeflowuniverse.herolib.mcp
import freeflowuniverse.herolib.mcp.transport
import freeflowuniverse.herolib.schemas.jsonschema
import x.json2
import os
import time

// File operations tool
fn read_file_handler(arguments map[string]json2.Any) !mcp.ToolCallResult {
	path := arguments['path'].str()

	content := os.read_file(path) or {
		return mcp.ToolCallResult{
			is_error: true
			content:  [
				mcp.ToolContent{
					typ:  'text'
					text: 'Error reading file: ${err}'
				},
			]
		}
	}

	return mcp.ToolCallResult{
		is_error: false
		content:  [mcp.ToolContent{
			typ:  'text'
			text: content
		}]
	}
}

// Calculator tool
fn calculator_handler(arguments map[string]json2.Any) !mcp.ToolCallResult {
	operation := arguments['operation'].str()
	num1 := arguments['num1'].f64()
	num2 := arguments['num2'].f64()

	result := match operation {
		'add' {
			num1 + num2
		}
		'subtract' {
			num1 - num2
		}
		'multiply' {
			num1 * num2
		}
		'divide' {
			if num2 == 0 {
				return mcp.ToolCallResult{
					is_error: true
					content:  [
						mcp.ToolContent{
							typ:  'text'
							text: 'Division by zero'
						},
					]
				}
			}
			num1 / num2
		}
		else {
			return mcp.ToolCallResult{
				is_error: true
				content:  [
					mcp.ToolContent{
						typ:  'text'
						text: 'Unknown operation: ${operation}'
					},
				]
			}
		}
	}

	return mcp.ToolCallResult{
		is_error: false
		content:  [
			mcp.ToolContent{
				typ:  'text'
				text: '${num1} ${operation} ${num2} = ${result}'
			},
		]
	}
}

// System info tool
fn system_info_handler(arguments map[string]json2.Any) !mcp.ToolCallResult {
	info_type := arguments['type'].str()

	result := match info_type {
		'os' {
			$if windows {
				'Windows'
			} $else $if macos {
				'macOS'
			} $else {
				'Linux'
			}
		}
		'time' {
			time.now().str()
		}
		'user' {
			os.getenv('USER')
		}
		'home' {
			os.home_dir()
		}
		else {
			'Unknown info type: ${info_type}'
		}
	}

	return mcp.ToolCallResult{
		is_error: false
		content:  [
			mcp.ToolContent{
				typ:  'text'
				text: '${info_type}: ${result}'
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

	// Create backend with multiple useful tools
	backend := mcp.MemoryBackend{
		tools:         {
			'read_file':   mcp.Tool{
				name:         'read_file'
				description:  'Read the contents of a file'
				input_schema: jsonschema.Schema{
					typ:        'object'
					properties: {
						'path': jsonschema.SchemaRef(jsonschema.Schema{
							typ:         'string'
							description: 'Path to the file to read'
						})
					}
					required:   ['path']
				}
			}
			'calculator':  mcp.Tool{
				name:         'calculator'
				description:  'Perform basic mathematical operations'
				input_schema: jsonschema.Schema{
					typ:        'object'
					properties: {
						'operation': jsonschema.SchemaRef(jsonschema.Schema{
							typ:         'string'
							description: 'Operation to perform: add, subtract, multiply, divide'
						})
						'num1':      jsonschema.SchemaRef(jsonschema.Schema{
							typ:         'number'
							description: 'First number'
						})
						'num2':      jsonschema.SchemaRef(jsonschema.Schema{
							typ:         'number'
							description: 'Second number'
						})
					}
					required:   ['operation', 'num1', 'num2']
				}
			}
			'system_info': mcp.Tool{
				name:         'system_info'
				description:  'Get system information'
				input_schema: jsonschema.Schema{
					typ:        'object'
					properties: {
						'type': jsonschema.SchemaRef(jsonschema.Schema{
							typ:         'string'
							description: 'Type of info: os, time, user, home'
						})
					}
					required:   ['type']
				}
			}
		}
		tool_handlers: {
			'read_file':   read_file_handler
			'calculator':  calculator_handler
			'system_info': system_info_handler
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
				name:    'http_demo'
				version: '1.0.0'
			}
		}
		transport: transport_config
	})!

	if mode == .http {
		println('🚀 HTTP MCP Server Demo')
		println('=======================')
		println('')
		println('📡 Server running on: http://localhost:${port}')
		println('')
		println('🔗 Endpoints:')
		println('  • Health:   http://localhost:${port}/health')
		println('  • JSON-RPC: http://localhost:${port}/jsonrpc')
		println('  • Tools:    http://localhost:${port}/api/tools')
		println('')
		println('🧪 Test Commands:')
		println('  # Health check')
		println('  curl http://localhost:${port}/health')
		println('')
		println('  # List available tools')
		println('  curl http://localhost:${port}/api/tools')
		println('')
		println('  # Call calculator tool (REST)')
		println('  curl -X POST http://localhost:${port}/api/tools/calculator/call \\')
		println('    -H "Content-Type: application/json" \\')
		println('    -d \'{"operation":"add","num1":10,"num2":5}\'')
		println('')
		println('  # Get system info (REST)')
		println('  curl -X POST http://localhost:${port}/api/tools/system_info/call \\')
		println('    -H "Content-Type: application/json" \\')
		println('    -d \'{"type":"os"}\'')
		println('')
		println('  # Call via JSON-RPC')
		println('  curl -X POST http://localhost:${port}/jsonrpc \\')
		println('    -H "Content-Type: application/json" \\')
		println('    -d \'{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"calculator","arguments":{"operation":"multiply","num1":7,"num2":8}}}\'')
		println('')
		println('🔌 VS Code Integration:')
		println('  Add to your VS Code MCP settings:')
		println('  {')
		println('    "mcpServers": {')
		println('      "http_demo": {')
		println('        "transport": "http",')
		println('        "url": "http://localhost:${port}/jsonrpc"')
		println('      }')
		println('    }')
		println('  }')
		println('')
	} else {
		println('📟 STDIO MCP Server Demo')
		println('========================')
		println('Ready for JSON-RPC messages on stdin...')
		println('')
		println('💡 Tip: Run with --http --port 8080 for HTTP mode')
	}

	server.start()!
}
