module mycelium_rpc

import incubaid.herolib.schemas.jsonrpc
import incubaid.herolib.core.httpconnection
import encoding.base64

// Helper function to get or create the RPC client
fn (mut c MyceliumRPC) get_client() !&jsonrpc.Client {
	if client := c.rpc_client {
		return client
	}
	// Create HTTP transport using httpconnection
	mut http_conn := httpconnection.new(
		name: 'mycelium_rpc_${c.name}'
		url:  c.url
	)!

	// Create a simple HTTP transport wrapper
	transport := HTTPTransport{
		http_conn: http_conn
	}

	mut client := jsonrpc.new_client(transport)
	c.rpc_client = client
	return client
}

// HTTPTransport implements IRPCTransportClient for HTTP connections
struct HTTPTransport {
mut:
	http_conn &httpconnection.HTTPConnection
}

// send implements the IRPCTransportClient interface
fn (mut t HTTPTransport) send(request string, params jsonrpc.SendParams) !string {
	req := httpconnection.Request{
		method:     .post
		prefix:     '/'
		dataformat: .json
		data:       request
	}

	response := t.http_conn.post_json_str(req)!
	return response
}

// Admin methods

// get_info gets general info about the node
pub fn (mut c MyceliumRPC) get_info() !Info {
	mut client := c.get_client()!
	request := jsonrpc.new_request_generic('getInfo', []string{})
	return client.send[[]string, Info](request)!
}

// get_peers lists known peers
pub fn (mut c MyceliumRPC) get_peers() ![]PeerStats {
	mut client := c.get_client()!
	request := jsonrpc.new_request_generic('getPeers', []string{})
	return client.send[[]string, []PeerStats](request)!
}

// add_peer adds a new peer identified by the provided endpoint
pub fn (mut c MyceliumRPC) add_peer(endpoint string) !bool {
	mut client := c.get_client()!
	params := {
		'endpoint': endpoint
	}
	request := jsonrpc.new_request_generic('addPeer', params)
	return client.send[map[string]string, bool](request)!
}

// delete_peer removes an existing peer identified by the provided endpoint
pub fn (mut c MyceliumRPC) delete_peer(endpoint string) !bool {
	mut client := c.get_client()!
	params := {
		'endpoint': endpoint
	}
	request := jsonrpc.new_request_generic('deletePeer', params)
	return client.send[map[string]string, bool](request)!
}

// Route methods

// get_selected_routes lists all selected routes
pub fn (mut c MyceliumRPC) get_selected_routes() ![]Route {
	mut client := c.get_client()!
	request := jsonrpc.new_request_generic('getSelectedRoutes', []string{})
	return client.send[[]string, []Route](request)!
}

// get_fallback_routes lists all active fallback routes
pub fn (mut c MyceliumRPC) get_fallback_routes() ![]Route {
	mut client := c.get_client()!
	request := jsonrpc.new_request_generic('getFallbackRoutes', []string{})
	return client.send[[]string, []Route](request)!
}

// get_queried_subnets lists all currently queried subnets
pub fn (mut c MyceliumRPC) get_queried_subnets() ![]QueriedSubnet {
	mut client := c.get_client()!
	request := jsonrpc.new_request_generic('getQueriedSubnets', []string{})
	return client.send[[]string, []QueriedSubnet](request)!
}

// get_no_route_entries lists all subnets which are explicitly marked as no route
pub fn (mut c MyceliumRPC) get_no_route_entries() ![]NoRouteSubnet {
	mut client := c.get_client()!
	request := jsonrpc.new_request_generic('getNoRouteEntries', []string{})
	return client.send[[]string, []NoRouteSubnet](request)!
}

// get_public_key_from_ip gets the pubkey from node ip
pub fn (mut c MyceliumRPC) get_public_key_from_ip(mycelium_ip string) !PublicKeyResponse {
	mut client := c.get_client()!
	params := {
		'mycelium_ip': mycelium_ip
	}
	request := jsonrpc.new_request_generic('getPublicKeyFromIp', params)
	return client.send[map[string]string, PublicKeyResponse](request)!
}

// Message methods

// PopMessageParams represents parameters for pop_message method
pub struct PopMessageParams {
pub mut:
	peek    ?bool   // Whether to peek the message or not
	timeout ?i64    // Amount of seconds to wait for a message
	topic   ?string // Optional filter for loading messages
}

// pop_message gets a message from the inbound message queue
pub fn (mut c MyceliumRPC) pop_message(peek bool, timeout i64, topic string) !InboundMessage {
	mut client := c.get_client()!
	mut params := PopMessageParams{}
	if peek {
		params.peek = peek
	}
	if timeout > 0 {
		params.timeout = timeout
	}
	if topic != '' {
		// Encode topic as base64 as required by mycelium
		params.topic = base64.encode_str(topic)
	}
	request := jsonrpc.new_request_generic('popMessage', params)
	return client.send[PopMessageParams, InboundMessage](request)!
}

// PushMessageParams represents parameters for push_message method
pub struct PushMessageParams {
pub mut:
	message       PushMessageBody // The message to send
	reply_timeout ?i64            // Amount of seconds to wait for a reply
}

// push_message submits a new message to the system
pub fn (mut c MyceliumRPC) push_message(message PushMessageBody, reply_timeout i64) !string {
	mut client := c.get_client()!
	mut params := PushMessageParams{
		message: message
	}
	if reply_timeout > 0 {
		params.reply_timeout = reply_timeout
	}
	request := jsonrpc.new_request_generic('pushMessage', params)
	// The response can be either InboundMessage or PushMessageResponseId
	// For simplicity, we'll return the raw JSON response as string
	return client.send[PushMessageParams, string](request)!
}

// PushMessageReplyParams represents parameters for push_message_reply method
pub struct PushMessageReplyParams {
pub mut:
	id      string          // The ID of the message to reply to
	message PushMessageBody // The reply message
}

// push_message_reply replies to a message with the given ID
pub fn (mut c MyceliumRPC) push_message_reply(id string, message PushMessageBody) !bool {
	mut client := c.get_client()!
	params := PushMessageReplyParams{
		id:      id
		message: message
	}
	request := jsonrpc.new_request_generic('pushMessageReply', params)
	return client.send[PushMessageReplyParams, bool](request)!
}

// get_message_info gets the status of an outbound message
pub fn (mut c MyceliumRPC) get_message_info(id string) !MessageStatusResponse {
	mut client := c.get_client()!
	params := {
		'id': id
	}
	request := jsonrpc.new_request_generic('getMessageInfo', params)
	return client.send[map[string]string, MessageStatusResponse](request)!
}

// Topic management methods

// get_default_topic_action gets the default topic action
pub fn (mut c MyceliumRPC) get_default_topic_action() !bool {
	mut client := c.get_client()!
	request := jsonrpc.new_request_generic('getDefaultTopicAction', []string{})
	return client.send[[]string, bool](request)!
}

// SetDefaultTopicActionParams represents parameters for set_default_topic_action method
pub struct SetDefaultTopicActionParams {
pub mut:
	accept bool // Whether to accept unconfigured topics by default
}

// set_default_topic_action sets the default topic action
pub fn (mut c MyceliumRPC) set_default_topic_action(accept bool) !bool {
	mut client := c.get_client()!
	params := SetDefaultTopicActionParams{
		accept: accept
	}
	request := jsonrpc.new_request_generic('setDefaultTopicAction', params)
	return client.send[SetDefaultTopicActionParams, bool](request)!
}

// get_topics gets all configured topics
pub fn (mut c MyceliumRPC) get_topics() ![]string {
	mut client := c.get_client()!
	request := jsonrpc.new_request_generic('getTopics', []string{})
	encoded_topics := client.send[[]string, []string](request)!
	// Decode base64-encoded topics for user convenience
	mut decoded_topics := []string{}
	for encoded_topic in encoded_topics {
		decoded_topic := base64.decode_str(encoded_topic)
		decoded_topics << decoded_topic
	}
	return decoded_topics
}

// add_topic adds a new topic to the system's whitelist
pub fn (mut c MyceliumRPC) add_topic(topic string) !bool {
	mut client := c.get_client()!
	// Encode topic as base64 as required by mycelium
	encoded_topic := base64.encode_str(topic)
	params := {
		'topic': encoded_topic
	}
	request := jsonrpc.new_request_generic('addTopic', params)
	return client.send[map[string]string, bool](request)!
}

// remove_topic removes a topic from the system's whitelist
pub fn (mut c MyceliumRPC) remove_topic(topic string) !bool {
	mut client := c.get_client()!
	// Encode topic as base64 as required by mycelium
	encoded_topic := base64.encode_str(topic)
	params := {
		'topic': encoded_topic
	}
	request := jsonrpc.new_request_generic('removeTopic', params)
	return client.send[map[string]string, bool](request)!
}

// get_topic_sources gets all sources (subnets) that are allowed to send messages for a specific topic
pub fn (mut c MyceliumRPC) get_topic_sources(topic string) ![]string {
	mut client := c.get_client()!
	// Encode topic as base64 as required by mycelium
	encoded_topic := base64.encode_str(topic)
	params := {
		'topic': encoded_topic
	}
	request := jsonrpc.new_request_generic('getTopicSources', params)
	return client.send[map[string]string, []string](request)!
}

// add_topic_source adds a source (subnet) that is allowed to send messages for a specific topic
pub fn (mut c MyceliumRPC) add_topic_source(topic string, subnet string) !bool {
	mut client := c.get_client()!
	// Encode topic as base64 as required by mycelium
	encoded_topic := base64.encode_str(topic)
	params := {
		'topic':  encoded_topic
		'subnet': subnet
	}
	request := jsonrpc.new_request_generic('addTopicSource', params)
	return client.send[map[string]string, bool](request)!
}

// remove_topic_source removes a source (subnet) that is allowed to send messages for a specific topic
pub fn (mut c MyceliumRPC) remove_topic_source(topic string, subnet string) !bool {
	mut client := c.get_client()!
	// Encode topic as base64 as required by mycelium
	encoded_topic := base64.encode_str(topic)
	params := {
		'topic':  encoded_topic
		'subnet': subnet
	}
	request := jsonrpc.new_request_generic('removeTopicSource', params)
	return client.send[map[string]string, bool](request)!
}

// get_topic_forward_socket gets the forward socket for a topic
pub fn (mut c MyceliumRPC) get_topic_forward_socket(topic string) !string {
	mut client := c.get_client()!
	// Encode topic as base64 as required by mycelium
	encoded_topic := base64.encode_str(topic)
	params := {
		'topic': encoded_topic
	}
	request := jsonrpc.new_request_generic('getTopicForwardSocket', params)
	return client.send[map[string]string, string](request)!
}

// set_topic_forward_socket sets the socket path where messages for a specific topic should be forwarded to
pub fn (mut c MyceliumRPC) set_topic_forward_socket(topic string, socket_path string) !bool {
	mut client := c.get_client()!
	// Encode topic as base64 as required by mycelium
	encoded_topic := base64.encode_str(topic)
	params := {
		'topic':       encoded_topic
		'socket_path': socket_path
	}
	request := jsonrpc.new_request_generic('setTopicForwardSocket', params)
	return client.send[map[string]string, bool](request)!
}

// remove_topic_forward_socket removes the socket path where messages for a specific topic are forwarded to
pub fn (mut c MyceliumRPC) remove_topic_forward_socket(topic string) !bool {
	mut client := c.get_client()!
	// Encode topic as base64 as required by mycelium
	encoded_topic := base64.encode_str(topic)
	params := {
		'topic': encoded_topic
	}
	request := jsonrpc.new_request_generic('removeTopicForwardSocket', params)
	return client.send[map[string]string, bool](request)!
}
