module mcp

import freeflowuniverse.herolib.schemas.jsonrpc
import json

// This file contains tests for the MCP initialize handler implementation.
// It tests the handler's ability to process initialize requests according to the MCP specification.

// test_initialize_handler tests the initialize handler with a sample initialize request
fn test_initialize_handler() {
	mut server := Server{}

	// Sample initialize request from the MCP specification
	initialize_request := '{"jsonrpc":"2.0","id":0,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{"sampling":{},"roots":{"listChanged":true}},"clientInfo":{"name":"mcp-inspector","version":"0.0.1"}}}'

	// Call the initialize handler directly
	response := server.initialize_handler(initialize_request) or {
		assert false, 'Initialize handler failed: ${err}'
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
	result := json.decode(ServerConfiguration, result_json) or {
		assert false, 'Failed to decode result: ${err}'
		return
	}

	// Verify the protocol version matches what was requested
	assert result.protocol_version == '2024-11-05', 'Protocol version should match the request'

	// Verify server capabilities
	assert result.capabilities.prompts.list_changed == true, 'Prompts capability should have list_changed set to true'
	assert result.capabilities.resources.subscribe == true, 'Resources capability should have subscribe set to true'
	assert result.capabilities.resources.list_changed == true, 'Resources capability should have list_changed set to true'
	assert result.capabilities.tools.list_changed == true, 'Tools capability should have list_changed set to true'

	// Verify server info
	assert result.server_info.name == 'HeroLibMCPServer', 'Server name should be HeroLibMCPServer'
	assert result.server_info.version == '1.0.0', 'Server version should be 1.0.0'
}

// test_initialize_handler_with_handler tests the initialize handler through the JSONRPC handler
fn test_initialize_handler_with_handler() {
	mut server := Server{}

	// Create a handler with just the initialize procedure
	handler := jsonrpc.new_handler(jsonrpc.Handler{
		procedures: {
			'initialize': server.initialize_handler
		}
	}) or {
		assert false, 'Failed to create handler: ${err}'
		return
	}

	// Sample initialize request from the MCP specification
	initialize_request := '{"jsonrpc":"2.0","id":0,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{"sampling":{},"roots":{"listChanged":true}},"clientInfo":{"name":"mcp-inspector","version":"0.0.1"}}}'

	// Process the request through the handler
	response := handler.handle(initialize_request) or {
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
	result := json.decode(ServerConfiguration, result_json) or {
		assert false, 'Failed to decode result: ${err}'
		return
	}

	// Verify the protocol version matches what was requested
	assert result.protocol_version == '2024-11-05', 'Protocol version should match the request'
}
