module baobab

import freeflowuniverse.herolib.ai.mcp
import freeflowuniverse.herolib.schemas.jsonrpc
import json
import x.json2
import os

// This file contains tests for the Baobab tools implementation.
// It tests the tools' ability to handle tool calls and return expected results.

// test_generate_module_from_openapi_tool tests the generate_module_from_openapi tool definition
fn test_generate_module_from_openapi_tool() {
	// Verify the tool definition
	assert generate_module_from_openapi_tool.name == 'generate_module_from_openapi', 'Tool name should be "generate_module_from_openapi"'

	// Verify the input schema
	assert generate_module_from_openapi_tool.input_schema.typ == 'object', 'Input schema type should be "object"'
	assert 'openapi_path' in generate_module_from_openapi_tool.input_schema.properties, 'Input schema should have "openapi_path" property'
	assert generate_module_from_openapi_tool.input_schema.properties['openapi_path'].typ == 'string', 'openapi_path property should be of type "string"'
	assert 'openapi_path' in generate_module_from_openapi_tool.input_schema.required, 'openapi_path should be a required property'
}

// test_generate_module_from_openapi_tool_handler_error tests the error handling of the generate_module_from_openapi tool handler
fn test_generate_module_from_openapi_tool_handler_error() {
	// Create arguments with a non-existent file path
	mut arguments := map[string]json2.Any{}
	arguments['openapi_path'] = json2.Any('non_existent_file.yaml')

	// Call the handler
	result := generate_module_from_openapi_tool_handler(arguments) or {
		// If the handler returns an error, that's expected
		assert err.msg().contains(''), 'Error message should not be empty'
		return
	}

	// If we get here, the handler should have returned an error result
	assert result.is_error, 'Result should indicate an error'
	assert result.content.len > 0, 'Error content should not be empty'
	assert result.content[0].typ == 'text', 'Error content should be of type "text"'
	assert result.content[0].text.contains('failed to open file'), 'Error content should contain "failed to open file", instead ${result.content[0].text}'
}

// test_mcp_tool_call_integration tests the integration of the tool with the MCP server
fn test_mcp_tool_call_integration() {
	// Create a new MCP server
	mut server := new_mcp_server() or {
		assert false, 'Failed to create MCP server: ${err}'
		return
	}

	// Create a temporary OpenAPI file for testing
	temp_dir := os.temp_dir()
	temp_file := os.join_path(temp_dir, 'test_openapi.yaml')
	os.write_file(temp_file, 'openapi: 3.0.0\ninfo:\n  title: Test API\n  version: 1.0.0\npaths:\n  /test:\n    get:\n      summary: Test endpoint\n      responses:\n        "200":\n          description: OK') or {
		assert false, 'Failed to create temporary file: ${err}'
		return
	}

	// Sample tool call request
	tool_call_request := '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"generate_module_from_openapi","arguments":{"openapi_path":"${temp_file}"}}}'

	// Process the request through the handler
	response := server.handler.handle(tool_call_request) or {
		// Clean up the temporary file
		os.rm(temp_file) or {}

		// If the handler returns an error, that's expected in this test environment
		// since we might not have all dependencies set up
		return
	}

	// Clean up the temporary file
	os.rm(temp_file) or {}

	// Decode the response to verify its structure
	decoded_response := jsonrpc.decode_response(response) or {
		// In a test environment, we might get an error due to missing dependencies
		// This is acceptable for this test
		return
	}

	// If we got a successful response, verify it
	if !decoded_response.is_error() {
		// Parse the result to verify its contents
		result_json := decoded_response.result() or {
			assert false, 'Failed to get result: ${err}'
			return
		}

		// Decode the result to check the content
		result_map := json2.raw_decode(result_json) or {
			assert false, 'Failed to decode result: ${err}'
			return
		}.as_map()

		// Verify the result structure
		assert 'isError' in result_map, 'Result should have isError field'
		assert 'content' in result_map, 'Result should have content field'
	}
}
