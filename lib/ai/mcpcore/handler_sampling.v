module mcp

import time
import os
import log
import x.json2
import json
import freeflowuniverse.herolib.schemas.jsonrpc

// Sampling related structs

pub struct MessageContent {
pub:
	typ      string @[json: 'type']
	text     string
	data     string
	mimetype string @[json: 'mimeType']
}

pub struct Message {
pub:
	role    string
	content MessageContent
}

pub struct ModelHint {
pub:
	name string
}

pub struct ModelPreferences {
pub:
	hints                 []ModelHint
	cost_priority         f32 @[json: 'costPriority']
	speed_priority        f32 @[json: 'speedPriority']
	intelligence_priority f32 @[json: 'intelligencePriority']
}

pub struct SamplingCreateMessageParams {
pub:
	messages          []Message
	model_preferences ModelPreferences @[json: 'modelPreferences']
	system_prompt     string           @[json: 'systemPrompt']
	include_context   string           @[json: 'includeContext']
	temperature       f32
	max_tokens        int      @[json: 'maxTokens']
	stop_sequences    []string @[json: 'stopSequences']
	metadata          map[string]json2.Any
}

pub struct SamplingCreateMessageResult {
pub:
	model       string
	stop_reason string @[json: 'stopReason']
	role        string
	content     MessageContent
}

// sampling_create_message_handler handles the sampling/createMessage request
// This request is used to request LLM completions through the client
fn (mut s Server) sampling_create_message_handler(data string) !string {
	// Decode the request
	request_map := json2.raw_decode(data)!.as_map()
	id := request_map['id'].int()
	params_map := request_map['params'].as_map()

	// Validate required parameters
	if 'messages' !in params_map {
		return jsonrpc.new_error_response(id, missing_required_argument('messages')).encode()
	}

	if 'maxTokens' !in params_map {
		return jsonrpc.new_error_response(id, missing_required_argument('maxTokens')).encode()
	}

	// Call the backend to handle the sampling request
	result := s.backend.sampling_create_message(params_map) or {
		return jsonrpc.new_error_response(id, sampling_error(err.msg())).encode()
	}

	// Create a success response with the result
	response := jsonrpc.new_response(id, json.encode(result))
	return response.encode()
}

// Helper function to convert JSON messages to our Message struct format
fn parse_messages(messages_json json2.Any) ![]Message {
	messages_arr := messages_json.arr()
	mut result := []Message{cap: messages_arr.len}

	for msg_json in messages_arr {
		msg_map := msg_json.as_map()

		if 'role' !in msg_map {
			return error('Missing role in message')
		}

		if 'content' !in msg_map {
			return error('Missing content in message')
		}

		role := msg_map['role'].str()
		content_map := msg_map['content'].as_map()

		if 'type' !in content_map {
			return error('Missing type in message content')
		}

		typ := content_map['type'].str()
		mut text := ''
		mut data := ''
		mut mimetype := ''

		if typ == 'text' {
			if 'text' !in content_map {
				return error('Missing text in text content')
			}
			text = content_map['text'].str()
		} else if typ == 'image' {
			if 'data' !in content_map {
				return error('Missing data in image content')
			}
			data = content_map['data'].str()

			if 'mimeType' !in content_map {
				return error('Missing mimeType in image content')
			}
			mimetype = content_map['mimeType'].str()
		} else {
			return error('Unsupported content type: ${typ}')
		}

		result << Message{
			role:    role
			content: MessageContent{
				typ:      typ
				text:     text
				data:     data
				mimetype: mimetype
			}
		}
	}

	return result
}
