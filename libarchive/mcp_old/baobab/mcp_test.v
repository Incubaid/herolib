module baobab

import freeflowuniverse.herolib.mcp
import freeflowuniverse.herolib.schemas.jsonrpc
import json
import x.json2

// This file contains tests for the Baobab MCP server implementation.
// It tests the server's ability to initialize and handle tool calls.

// test_new_mcp_server tests the creation of a new MCP server for the Baobab module
fn test_new_mcp_server() {
	// Create a new MCP server
	mut server := new_mcp_server() or {
		assert false, 'Failed to create MCP server: ${err}'
		return
	}

	// Verify server info
	assert server.server_info.name == 'developer', 'Server name should be "developer"'
	assert server.server_info.version == '1.0.0', 'Server version should be 1.0.0'

	// Verify server capabilities
	assert server.capabilities.prompts.list_changed == true, 'Prompts capability should have list_changed set to true'
	assert server.capabilities.resources.subscribe == true, 'Resources capability should have subscribe set to true'
	assert server.capabilities.resources.list_changed == true, 'Resources capability should have list_changed set to true'
	assert server.capabilities.tools.list_changed == true, 'Tools capability should have list_changed set to true'
}

// test_mcp_server_initialize tests the initialize handler with a sample initialize request
fn test_mcp_server_initialize() {
	// Create a new MCP server
	mut server := new_mcp_server() or {
		assert false, 'Failed to create MCP server: ${err}'
		return
	}

	// Sample initialize request from the MCP specification
	initialize_request := '{"jsonrpc":"2.0","id":0,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{"sampling":{},"roots":{"listChanged":true}},"clientInfo":{"name":"mcp-inspector","version":"0.0.1"}}}'

	// Process the request through the handler
	response := server.handler.handle(initialize_request) or {
		assert false, 'Handler failed to process request: ${err}'
		return
	}

	// Decode the response to verify its structure
	decoded_response := jsonrpc.decode_response(response) or {
		assert false, 'Failed to decode response: ${err}'
		return
	}

	// Verify that the response is not an error
	assert !decoded_response.is_error(), 'Response should not be an error'

	// Parse the result to verify its contents
	result_json := decoded_response.result() or {
		assert false, 'Failed to get result: ${err}'
		return
	}

	// Decode the result into an ServerConfiguration struct
	result := json.decode(mcp.ServerConfiguration, result_json) or {
		assert false, 'Failed to decode result: ${err}'
		return
	}

	// Verify the protocol version matches what was requested
	assert result.protocol_version == '2024-11-05', 'Protocol version should match the request'

	// Verify server info
	assert result.server_info.name == 'developer', 'Server name should be "developer"'
}

// test_tools_list tests the tools/list handler to verify tool registration
fn test_tools_list() {
	// Create a new MCP server
	mut server := new_mcp_server() or {
		assert false, 'Failed to create MCP server: ${err}'
		return
	}

	// Sample tools/list request
	tools_list_request := '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{"cursor":""}}'

	// Process the request through the handler
	response := server.handler.handle(tools_list_request) or {
		assert false, 'Handler failed to process request: ${err}'
		return
	}

	// Decode the response to verify its structure
	decoded_response := jsonrpc.decode_response(response) or {
		assert false, 'Failed to decode response: ${err}'
		return
	}

	// Verify that the response is not an error
	assert !decoded_response.is_error(), 'Response should not be an error'

	// Parse the result to verify its contents
	result_json := decoded_response.result() or {
		assert false, 'Failed to get result: ${err}'
		return
	}

	// Decode the result into a map to check the tools
	result_map := json2.raw_decode(result_json) or {
		assert false, 'Failed to decode result: ${err}'
		return
	}.as_map()

	// Verify that the tools array exists and contains the expected tool
	tools := result_map['tools'].arr()
	assert tools.len > 0, 'Tools list should not be empty'

	// Find the generate_module_from_openapi tool
	mut found_tool := false
	for tool in tools {
		tool_map := tool.as_map()
		if tool_map['name'].str() == 'generate_module_from_openapi' {
			found_tool = true
			break
		}
	}

	assert found_tool, 'generate_module_from_openapi tool should be registered'
}
