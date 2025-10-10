module mcp

import freeflowuniverse.herolib.schemas.jsonrpc
import json

// This file contains tests for the MCP initialize handler implementation.
// It tests the handler's ability to process initialize requests according to the MCP specification.

// test_json_serialization_deserialization tests the JSON serialization and deserialization of initialize request and response
fn test_json_serialization_deserialization() {
	// Create a sample initialize params object
	params := ClientConfiguration{
		protocol_version: '2024-11-05'
		capabilities:     ClientCapabilities{
			roots: RootsCapability{
				list_changed: true
			}
			// sampling: SamplingCapability{}
		}
		client_info:      ClientInfo{
			name: 'mcp-inspector'
			// version: '0.0.1'
		}
	}

	// Serialize the params to JSON
	params_json := json.encode(params)

	// Verify the JSON structure has the correct camelCase keys
	assert params_json.contains('"protocolVersion":"2024-11-05"'), 'JSON should have protocolVersion in camelCase'
	assert params_json.contains('"clientInfo":{'), 'JSON should have clientInfo in camelCase'
	assert params_json.contains('"listChanged":true'), 'JSON should have listChanged in camelCase'

	// Deserialize the JSON back to a struct
	deserialized_params := json.decode(ClientConfiguration, params_json) or {
		assert false, 'Failed to deserialize params: ${err}'
		return
	}

	// Verify the deserialized object matches the original
	assert deserialized_params.protocol_version == params.protocol_version, 'Deserialized protocol_version should match original'
	assert deserialized_params.client_info.name == params.client_info.name, 'Deserialized client_info.name should match original'
	assert deserialized_params.client_info.version == params.client_info.version, 'Deserialized client_info.version should match original'
	assert deserialized_params.capabilities.roots.list_changed == params.capabilities.roots.list_changed, 'Deserialized capabilities.roots.list_changed should match original'

	// Now test the response serialization/deserialization
	response := ServerConfiguration{
		protocol_version: '2024-11-05'
		capabilities:     ServerCapabilities{
			logging:   LoggingCapability{}
			prompts:   PromptsCapability{
				list_changed: true
			}
			resources: ResourcesCapability{
				subscribe:    true
				list_changed: true
			}
			tools:     ToolsCapability{
				list_changed: true
			}
		}
		server_info:      ServerInfo{
			name:    'HeroLibMCPServer'
			version: '1.0.0'
		}
	}

	// Serialize the response to JSON
	response_json := json.encode(response)

	// Verify the JSON structure has the correct camelCase keys
	assert response_json.contains('"protocolVersion":"2024-11-05"'), 'JSON should have protocolVersion in camelCase'
	assert response_json.contains('"serverInfo":{'), 'JSON should have serverInfo in camelCase'
	assert response_json.contains('"listChanged":true'), 'JSON should have listChanged in camelCase'
	assert response_json.contains('"subscribe":true'), 'JSON should have subscribe field'

	// Deserialize the JSON back to a struct
	deserialized_response := json.decode(ServerConfiguration, response_json) or {
		assert false, 'Failed to deserialize response: ${err}'
		return
	}

	// Verify the deserialized object matches the original
	assert deserialized_response.protocol_version == response.protocol_version, 'Deserialized protocol_version should match original'
	assert deserialized_response.server_info.name == response.server_info.name, 'Deserialized server_info.name should match original'
	assert deserialized_response.server_info.version == response.server_info.version, 'Deserialized server_info.version should match original'
	assert deserialized_response.capabilities.prompts.list_changed == response.capabilities.prompts.list_changed, 'Deserialized capabilities.prompts.list_changed should match original'
	assert deserialized_response.capabilities.resources.subscribe == response.capabilities.resources.subscribe, 'Deserialized capabilities.resources.subscribe should match original'
	assert deserialized_response.capabilities.resources.list_changed == response.capabilities.resources.list_changed, 'Deserialized capabilities.resources.list_changed should match original'
	assert deserialized_response.capabilities.tools.list_changed == response.capabilities.tools.list_changed, 'Deserialized capabilities.tools.list_changed should match original'
}
