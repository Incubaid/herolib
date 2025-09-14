module mcp

import time
import os
import log
import x.json2
import json
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.schemas.jsonschema

// Tool related structs

pub struct Tool {
pub:
	name         string
	description  string
	input_schema jsonschema.Schema @[json: 'inputSchema']
}

pub struct ToolProperty {
pub:
	typ   string @[json: 'type']
	items ToolItems
	enum  []string
}

pub struct ToolItems {
pub:
	typ        string @[json: 'type']
	enum       []string
	properties map[string]ToolProperty
}

pub struct ToolContent {
pub:
	typ        string @[json: 'type']
	text       string
	number     int
	boolean    bool
	properties map[string]ToolContent
	items      []ToolContent
}

// Tool List Handler

pub struct ToolListParams {
pub:
	cursor string
}

pub struct ToolListResult {
pub:
	tools       []Tool
	next_cursor string @[json: 'nextCursor']
}

// tools_list_handler handles the tools/list request
// This request is used to retrieve a list of available tools
fn (mut s Server) tools_list_handler(data string) !string {
	// Decode the request with cursor parameter
	request := jsonrpc.decode_request_generic[ToolListParams](data)!
	cursor := request.params.cursor

	// TODO: Implement pagination logic using the cursor
	// For now, return all tools
	encoded := json.encode(ToolListResult{
		tools:       s.backend.tool_list()!
		next_cursor: '' // Empty if no more pages
	})
	// Create a success response with the result
	response := jsonrpc.new_response(request.id, json.encode(ToolListResult{
		tools:       s.backend.tool_list()!
		next_cursor: '' // Empty if no more pages
	}))
	return response.encode()
}

// Tool Call Handler

pub struct ToolCallParams {
pub:
	name      string
	arguments map[string]json2.Any
	meta      map[string]json2.Any @[json: '_meta']
}

pub struct ToolCallResult {
pub:
	is_error bool @[json: 'isError']
	content  []ToolContent
}

// tools_call_handler handles the tools/call request
// This request is used to call a specific tool with arguments
fn (mut s Server) tools_call_handler(data string) !string {
	// Decode the request with name and arguments parameters
	request_map := json2.raw_decode(data)!.as_map()
	params_map := request_map['params'].as_map()
	tool_name := params_map['name'].str()
	if !s.backend.tool_exists(tool_name)! {
		return jsonrpc.new_error_response(request_map['id'].int(), tool_not_found(tool_name)).encode()
	}

	arguments := params_map['arguments'].as_map()
	// Get the tool by name
	tool := s.backend.tool_get(tool_name)!

	// Validate arguments against the input schema
	// TODO: Implement proper JSON Schema validation
	for req in tool.input_schema.required {
		if req !in arguments {
			return jsonrpc.new_error_response(request_map['id'].int(), missing_required_argument(req)).encode()
		}
	}

	log.error('Calling tool: ${tool_name} with arguments: ${arguments}')
	// Call the tool with the provided arguments
	result := s.backend.tool_call(tool_name, arguments)!

	log.error('Received result from tool: ${tool_name} with result: ${result}')
	// Create a success response with the result
	response := jsonrpc.new_response_generic[ToolCallResult](request_map['id'].int(),
		result)
	return response.encode()
}

// Tool Notification Handlers

// send_tools_list_changed_notification sends a notification when the list of tools changes
pub fn (mut s Server) send_tools_list_changed_notification() ! {
	// Check if the client supports this notification
	if !s.client_config.capabilities.roots.list_changed {
		return
	}

	// Create a notification
	notification := jsonrpc.new_blank_notification('notifications/tools/list_changed')
	s.send(json.encode(notification))
	// Send the notification to all connected clients
	log.info('Sending tools list changed notification: ${json.encode(notification)}')
}

pub fn error_tool_call_result(err IError) ToolCallResult {
	return ToolCallResult{
		is_error: true
		content:  [ToolContent{
			typ:  'text'
			text: err.msg()
		}]
	}
}
