module heroserver

import veb
import freeflowuniverse.herolib.schemas.openrpc
import freeflowuniverse.herolib.schemas.jsonschema

// Home page handler - returns HTML homepage
@['/']
pub fn (mut server HeroServer) home_handler(mut ctx Context) veb.Result {
	// Create a simple server info structure for the template
	server_info := HomePageData{
		base_url:     get_base_url_from_context(ctx)
		handlers:     server.handlers
		auth_enabled: server.auth_enabled
		host:         server.host
		port:         server.port
	}

	// Load and process the HTML template
	html_content := $tmpl('templates/home.html')

	return ctx.html(html_content)
}

// JSON server info handler
@['/json/:handler_type']
pub fn (mut server HeroServer) json_handler(mut ctx Context, handler_type string) veb.Result {
	// Get the OpenRPC handler for the specified handler type
	handler := server.handlers[handler_type] or { return ctx.not_found() }

	// Create server info structure focused on this handler
	server_info := create_handler_json_info(server, handler_type, handler, get_base_url_from_context(ctx))

	return ctx.json(server_info)
}

@['/doc/:handler_type']
pub fn (mut server HeroServer) doc_handler(mut ctx Context, handler_type string) veb.Result {
	// Get the OpenRPC handler for the specified handler type
	handler := server.handlers[handler_type] or { return ctx.not_found() }

	// Create dynamic configuration based on request
	config := DocConfig{
		base_url:     get_base_url_from_context(ctx)
		handler_type: handler_type
		auth_enabled: server.auth_enabled
	}

	// Convert the OpenRPC specification to a DocSpec with dynamic configuration
	spec := doc_spec_from_openrpc_with_config(handler.specification, config) or {
		return ctx.server_error('Failed to generate documentation: ${err}')
	}

	// Load and process the HTML template using the literal path
	html_content := $tmpl('templates/doc.html')

	return ctx.html(html_content)
}

@['/md/:handler_type']
pub fn (mut server HeroServer) md_handler(mut ctx Context, handler_type string) veb.Result {
	// Get the OpenRPC handler for the specified handler type
	handler := server.handlers[handler_type] or { return ctx.not_found() }

	// Generate markdown content from the OpenRPC specification
	markdown_content := generate_markdown_from_openrpc(handler.specification, handler_type,
		get_base_url_from_context(ctx)) or {
		return ctx.server_error('Failed to generate markdown documentation: ${err}')
	}

	// Set content type to text/plain for markdown
	ctx.set_content_type('text/plain; charset=utf-8')
	return ctx.text(markdown_content)
}

// get_base_url_from_context extracts the base URL from the VEB context
fn get_base_url_from_context(ctx Context) string {
	scheme := if ctx.get_header(.x_forwarded_proto) or { '' } == 'https' { 'https' } else { 'http' }
	host := ctx.get_header(.host) or { 'localhost:8080' }
	return '${scheme}://${host}'
}

// generate_markdown_from_openrpc generates markdown documentation from OpenRPC specification
fn generate_markdown_from_openrpc(spec openrpc.OpenRPC, handler_type string, base_url string) !string {
	mut md := ''

	// Title and description
	md += '# ${spec.info.title}\n\n'
	if spec.info.description.len > 0 {
		md += '${spec.info.description}\n\n'
	}

	// Basic info
	md += '**Version:** ${spec.info.version}\n'
	md += '**Handler Type:** ${handler_type}\n'
	md += '**Base URL:** ${base_url}\n\n'

	// Overview
	md += '## Overview\n\n'
	md += 'This API provides JSON-RPC 2.0 endpoints for ${handler_type} operations.\n\n'
	md += '**API Endpoint:** `${base_url}/api/${handler_type}`\n\n'

	// Table of Contents
	if spec.methods.len > 0 {
		md += '## Table of Contents\n\n'
		for method in spec.methods {
			md += '- [${method.name}](#${method.name.to_lower().replace('_', '-')})\n'
		}
		md += '\n'
	}

	// Methods
	if spec.methods.len > 0 {
		md += '## API Methods\n\n'
		for method in spec.methods {
			md += generate_method_markdown(method, base_url, handler_type)
		}
	}

	// Authentication section
	md += '## Authentication\n\n'
	md += 'All API requests use JSON-RPC 2.0 format and may require authentication depending on server configuration.\n\n'
	md += '### Request Format\n\n'
	md += '```json\n'
	md += '{\n'
	md += '  "jsonrpc": "2.0",\n'
	md += '  "method": "method_name",\n'
	md += '  "params": {\n'
	md += '    "param1": "value1",\n'
	md += '    "param2": "value2"\n'
	md += '  },\n'
	md += '  "id": 1\n'
	md += '}\n'
	md += '```\n\n'

	// Error handling
	md += '## Error Handling\n\n'
	md += 'The API uses standard JSON-RPC 2.0 error codes:\n\n'
	md += '- `-32700`: Parse error\n'
	md += '- `-32600`: Invalid Request\n'
	md += '- `-32601`: Method not found\n'
	md += '- `-32602`: Invalid params\n'
	md += '- `-32603`: Internal error\n\n'

	return md
}

// generate_method_markdown generates markdown documentation for a single method
fn generate_method_markdown(method openrpc.Method, base_url string, handler_type string) string {
	mut md := ''

	// Method header
	md += '### ${method.name}\n\n'

	if method.summary.len > 0 {
		md += '**Summary:** ${method.summary}\n\n'
	}

	if method.description.len > 0 {
		md += '${method.description}\n\n'
	}

	// Parameters
	if method.params.len > 0 {
		md += '#### Parameters\n\n'
		md += '| Name | Type | Required | Description |\n'
		md += '|------|------|----------|-------------|\n'

		for param in method.params {
			if param is openrpc.ContentDescriptor {
				param_desc := param as openrpc.ContentDescriptor
				param_type := if param_desc.schema is jsonschema.Schema {
					schema := param_desc.schema as jsonschema.Schema
					schema.typ
				} else {
					'unknown'
				}
				required := if param_desc.required { 'Yes' } else { 'No' }
				md += '| ${param_desc.name} | ${param_type} | ${required} | ${param_desc.description} |\n'
			}
		}
		md += '\n'
	}

	// Result
	if method.result is openrpc.ContentDescriptor {
		result := method.result as openrpc.ContentDescriptor
		md += '#### Returns\n\n'
		md += '${result.description}\n\n'
	}

	// Example request
	md += '#### Example Request\n\n'
	md += '```bash\n'
	md += 'curl -X POST ${base_url}/api/${handler_type} \\\n'
	md += '  -H "Content-Type: application/json" \\\n'
	md += "  -d '{\n"
	md += '    "jsonrpc": "2.0",\n'
	md += '    "method": "${method.name}",\n'
	md += '    "params": {\n'

	// Add example parameters
	if method.params.len > 0 {
		for i, param in method.params {
			if param is openrpc.ContentDescriptor {
				param_desc := param as openrpc.ContentDescriptor
				example_value := get_example_value_for_param(param_desc)
				comma := if i < method.params.len - 1 { ',' } else { '' }
				md += '      "${param_desc.name}": ${example_value}${comma}\n'
			}
		}
	}

	md += '    },\n'
	md += '    "id": 1\n'
	md += "  }'\n"
	md += '```\n\n'

	return md
}

// get_example_value_for_param returns an example value for a parameter based on its type
fn get_example_value_for_param(param openrpc.ContentDescriptor) string {
	if param.schema is jsonschema.Schema {
		schema := param.schema as jsonschema.Schema
		match schema.typ {
			'string' { return '"example_string"' }
			'integer', 'number' { return '123' }
			'boolean' { return 'true' }
			'array' { return '[]' }
			'object' { return '{}' }
			else { return '"example_value"' }
		}
	}
	return '"example_value"'
}

// create_server_info_json creates a comprehensive JSON response about the server
fn create_server_info_json(server HeroServer, base_url string) ServerInfoJSON {
	mut handlers := []HandlerInfoJSON{}

	// Process each registered handler
	for handler_name, handler in server.handlers {
		mut methods := []MethodInfoJSON{}

		// Extract methods from the OpenRPC specification
		for method in handler.specification.methods {
			methods << MethodInfoJSON{
				name:        method.name
				summary:     method.summary
				description: method.description
			}
		}

		handlers << HandlerInfoJSON{
			name:         handler_name
			title:        handler.specification.info.title
			description:  handler.specification.info.description
			version:      handler.specification.info.version
			api_endpoint: '${base_url}/api/${handler_name}'
			doc_endpoint: '${base_url}/doc/${handler_name}'
			md_endpoint:  '${base_url}/md/${handler_name}'
			methods:      methods
		}
	}

	// Define server features
	features := [
		FeatureJSON{
			title:       'JSON-RPC 2.0'
			description: 'Full compliance with JSON-RPC 2.0 specification for reliable API communication'
			icon:        '🔗'
		},
		FeatureJSON{
			title:       'Dynamic Documentation'
			description: 'Auto-generated interactive documentation with curl examples and copy buttons'
			icon:        '📚'
		},
		FeatureJSON{
			title:       'Secure Authentication'
			description: 'Built-in cryptographic authentication with public key infrastructure'
			icon:        '🔐'
		},
		FeatureJSON{
			title:       'Markdown Export'
			description: 'Export API documentation as clean markdown for integration with other tools'
			icon:        '📝'
		},
	]

	// Create endpoints information
	endpoints := EndpointsJSON{
		api_pattern:           '/api/{handler_name}'
		documentation_pattern: '/doc/{handler_name}'
		markdown_pattern:      '/md/{handler_name}'
		home_json:             '/'
		home_html:             '/home'
	}

	// Create quick start example
	example_handler := if handlers.len > 0 { handlers[0].name } else { 'handler_name' }
	quick_start := QuickStartJSON{
		description: "All API endpoints use JSON-RPC 2.0 format. Here's a basic example:"
		example:     ExampleRequestJSON{
			method:      'POST'
			url:         '${base_url}/api/${example_handler}'
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{\n  "jsonrpc": "2.0",\n  "method": "method_name",\n  "params": {\n    "param1": "value1",\n    "param2": "value2"\n  },\n  "id": 1\n}'
			description: 'Replace method_name and params with actual values from the API documentation'
		}
	}

	return ServerInfoJSON{
		server_name:  'HeroServer'
		version:      '1.0.0'
		description:  'Modern JSON-RPC 2.0 API Gateway with Dynamic Documentation'
		base_url:     base_url
		host:         server.host
		port:         server.port
		auth_enabled: server.auth_enabled
		handlers:     handlers
		endpoints:    endpoints
		features:     features
		quick_start:  quick_start
	}
}

// create_handler_json_info creates JSON response focused on a specific handler
fn create_handler_json_info(server HeroServer, handler_name string, handler &openrpc.Handler, base_url string) HandlerInfoJSON {
	mut methods := []MethodInfoJSON{}

	// Extract methods from the OpenRPC specification
	for method in handler.specification.methods {
		methods << MethodInfoJSON{
			name:        method.name
			summary:     method.summary
			description: method.description
		}
	}

	return HandlerInfoJSON{
		name:         handler_name
		title:        handler.specification.info.title
		description:  handler.specification.info.description
		version:      handler.specification.info.version
		api_endpoint: '${base_url}/api/${handler_name}'
		doc_endpoint: '${base_url}/doc/${handler_name}'
		md_endpoint:  '${base_url}/md/${handler_name}'
		methods:      methods
	}
}
