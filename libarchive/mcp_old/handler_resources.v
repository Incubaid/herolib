module mcp

import time
import os
import log
import x.json2
import json
import freeflowuniverse.herolib.schemas.jsonrpc

pub struct Resource {
pub:
	uri         string
	name        string
	description string
	mimetype    string @[json: 'mimeType']
}

// Resource List Handler

pub struct ResourceListParams {
pub:
	cursor string
}

pub struct ResourceListResult {
pub:
	resources   []Resource
	next_cursor string @[json: 'nextCursor']
}

// resources_list_handler handles the resources/list request
// This request is used to retrieve a list of available resources
fn (mut s Server) resources_list_handler(data string) !string {
	// Decode the request with cursor parameter
	request := jsonrpc.decode_request_generic[ResourceListParams](data)!
	cursor := request.params.cursor

	// TODO: Implement pagination logic using the cursor
	// For now, return all resources

	// Create a success response with the result
	response := jsonrpc.new_response_generic[ResourceListResult](request.id, ResourceListResult{
		resources:   s.backend.resource_list()!
		next_cursor: '' // Empty if no more pages
	})
	return response.encode()
}

// Resource Read Handler

pub struct ResourceReadParams {
pub:
	uri string
}

pub struct ResourceReadResult {
pub:
	contents []ResourceContent
}

pub struct ResourceContent {
pub:
	uri      string
	mimetype string @[json: 'mimeType']
	text     string
	blob     string // Base64-encoded binary data
}

// resources_read_handler handles the resources/read request
// This request is used to retrieve the contents of a resource
fn (mut s Server) resources_read_handler(data string) !string {
	// Decode the request with uri parameter
	request := jsonrpc.decode_request_generic[ResourceReadParams](data)!

	if !s.backend.resource_exists(request.params.uri)! {
		return jsonrpc.new_error_response(request.id, resource_not_found(request.params.uri)).encode()
	}

	// Get the resource contents by URI
	resource_contents := s.backend.resource_contents_get(request.params.uri)!

	// Create a success response with the result
	response := jsonrpc.new_response_generic[ResourceReadResult](request.id, ResourceReadResult{
		contents: resource_contents
	})
	return response.encode()
}

// Resource Templates Handler

pub struct ResourceTemplatesListResult {
pub:
	resource_templates []ResourceTemplate @[json: 'resourceTemplates']
}

pub struct ResourceTemplate {
pub:
	uri_template string @[json: 'uriTemplate']
	name         string
	description  string
	mimetype     string @[json: 'mimeType']
}

// resources_templates_list_handler handles the resources/templates/list request
// This request is used to retrieve a list of available resource templates
fn (mut s Server) resources_templates_list_handler(data string) !string {
	// Decode the request
	request := jsonrpc.decode_request(data)!

	// Create a success response with the result
	response := jsonrpc.new_response_generic[ResourceTemplatesListResult](request.id,
		ResourceTemplatesListResult{
		resource_templates: s.backend.resource_templates_list()!
	})
	return response.encode()
}

// Resource Subscription Handler

pub struct ResourceSubscribeParams {
pub:
	uri string
}

pub struct ResourceSubscribeResult {
pub:
	subscribed bool
}

// resources_subscribe_handler handles the resources/subscribe request
// This request is used to subscribe to changes for a specific resource
fn (mut s Server) resources_subscribe_handler(data string) !string {
	request := jsonrpc.decode_request_generic[ResourceSubscribeParams](data)!

	if !s.backend.resource_exists(request.params.uri)! {
		return jsonrpc.new_error_response(request.id, resource_not_found(request.params.uri)).encode()
	}

	s.backend.resource_subscribe(request.params.uri)!

	response := jsonrpc.new_response_generic[ResourceSubscribeResult](request.id, ResourceSubscribeResult{
		subscribed: true
	})
	return response.encode()
}

// Resource Notification Handlers

// send_resources_list_changed_notification sends a notification when the list of resources changes
pub fn (mut s Server) send_resources_list_changed_notification() ! {
	// Check if the client supports this notification
	if !s.client_config.capabilities.roots.list_changed {
		return
	}

	// Create a notification
	notification := jsonrpc.new_blank_notification('notifications/resources/list_changed')
	s.send(json.encode(notification))
	// Send the notification to all connected clients
	// In a real implementation, this would use a WebSocket or other transport
	log.info('Sending resources list changed notification: ${json.encode(notification)}')
}

pub struct ResourceUpdatedParams {
pub:
	uri string
}

// send_resource_updated_notification sends a notification when a subscribed resource is updated
pub fn (mut s Server) send_resource_updated_notification(uri string) ! {
	// Check if the client is subscribed to this resource
	if !s.backend.resource_subscribed(uri)! {
		return
	}

	// Create a notification
	notification := jsonrpc.new_notification[ResourceUpdatedParams]('notifications/resources/updated',
		ResourceUpdatedParams{
		uri: uri
	})

	s.send(json.encode(notification))
	// Send the notification to all connected clients
	// In a real implementation, this would use a WebSocket or other transport
	log.info('Sending resource updated notification: ${json.encode(notification)}')
}
