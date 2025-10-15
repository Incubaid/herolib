module mycelium

import json
import encoding.base64
import incubaid.herolib.core.httpconnection

// Represents a destination for a message, can be either IP or public key
pub struct MessageDestination {
pub:
	ip string @[omitempty] // IP in the subnet of the receiver node
	pk string @[omitempty] // hex encoded public key of the receiver node
}

// Body of a message to be sent
pub struct PushMessageBody {
pub:
	dst     MessageDestination
	topic   ?string // optional message topic
	payload string  // base64 encoded message
}

// Response containing message ID after pushing
pub struct PushMessageResponseId {
pub:
	id string // hex encoded message ID
}

// A message received by the system
pub struct InboundMessage {
pub:
	id      string
	src_ip  string @[json: 'srcIp'] // Sender overlay IP address
	src_pk  string @[json: 'srcPk'] // Sender public key, hex encoded
	dst_ip  string @[json: 'dstIp'] // Receiver overlay IP address
	dst_pk  string @[json: 'dstPk'] // Receiver public key, hex encoded
	topic   string // Optional message topic
	payload string // Message payload, base64 encoded
}

// Information about an outbound message
pub struct MessageStatusResponse {
pub:
	dst      string // IP address of receiving node
	state    string // pending, received, read, aborted or sending object
	created  i64    // Unix timestamp of creation
	deadline i64    // Unix timestamp of expiry
	msg_len  int @[json: 'msgLen'] // Length in bytes
}

// General information about a node
pub struct Info {
pub:
	node_subnet string @[json: 'nodeSubnet'] // subnet owned by node
}

// Response containing public key for a node IP
pub struct PublicKeyResponse {
pub:
	node_pub_key string @[json: 'NodePubKey'] // hex encoded public key
}

// Get connection to mycelium server
pub fn (mut self Mycelium) connection() !&httpconnection.HTTPConnection {
	mut c := self.conn or {
		mut c2 := httpconnection.new(
			name:  'mycelium'
			url:   self.server_url
			retry: 3
		)!
		c2
	}

	return c
}

@[params]
pub struct SendMessageArgs {
pub mut:
	public_key string @[required]
	payload    string @[required]
	topic      ?string
	wait       bool
}

// Send a message to a node identified by public key
pub fn (mut self Mycelium) send_msg(args SendMessageArgs) !InboundMessage {
	mut conn := self.connection()!
	mut body := PushMessageBody{
		dst:     MessageDestination{
			pk: args.public_key
			ip: ''
		}
		payload: base64.encode_str(args.payload)
		topic:   if v := args.topic {
			base64.encode_str(v)
		} else {
			none
		}
	}
	mut prefix := '/api/v1/messages'
	if args.wait {
		prefix += '?reply_timeout=120'
	}
	return conn.post_json_generic[InboundMessage](
		method:     .post
		prefix:     prefix
		data:       json.encode(body)
		dataformat: .json
	)!
}

@[params]
pub struct ReceiveMessageArgs {
pub mut:
	topic ?string
	wait  bool
	peek  bool
}

// Receive a message from the queue
pub fn (mut self Mycelium) receive_msg(args ReceiveMessageArgs) !InboundMessage {
	mut conn := self.connection()!
	mut prefix := '/api/v1/messages?peek=${args.peek}&'

	if args.wait {
		prefix += 'timeout=120&'
	}

	if v := args.topic {
		prefix += 'topic=${base64.encode_str(v)}'
	}

	return conn.get_json_generic[InboundMessage](
		method:     .get
		prefix:     prefix
		dataformat: .json
	)!
}

// Optional version of receive_msg that returns none on 204
pub fn (mut self Mycelium) receive_msg_opt(args ReceiveMessageArgs) ?InboundMessage {
	res := self.receive_msg(args) or {
		if err.msg().contains('204') {
			return none
		}
		panic(err)
	}
	return res
}

// Get status of a message by ID
pub fn (mut self Mycelium) get_msg_status(id string) !MessageStatusResponse {
	mut conn := self.connection()!
	return conn.get_json_generic[MessageStatusResponse](
		method:     .get
		prefix:     '/api/v1/messages/status/${id}'
		dataformat: .json
	)!
}

@[params]
pub struct ReplyMessageArgs {
pub mut:
	id         string @[required]
	public_key string @[required]
	payload    string @[required]
	topic      ?string
}

// Reply to a message
pub fn (mut self Mycelium) reply_msg(args ReplyMessageArgs) ! {
	mut conn := self.connection()!
	mut body := PushMessageBody{
		dst:     MessageDestination{
			pk: args.public_key
			ip: ''
		}
		payload: base64.encode_str(args.payload)
		topic:   if v := args.topic { base64.encode_str(v) } else { none }
	}
	_ := conn.post_json_str(
		method:     .post
		prefix:     '/api/v1/messages/reply/${args.id}'
		data:       json.encode(body)
		dataformat: .json
	)!
}

// curl -v -H 'Content-Type: application/json' -d '{"dst": {"pk": "be4bf135d60b7e43a46be1ad68f955cdc1209a3c55dc30d00c4463b1dace4377"}, "payload": "xuV+"}' http://localhost:8989/api/v1/messages\

// Get node info
pub fn (mut self Mycelium) get_info() !Info {
	mut conn := self.connection()!
	return conn.get_json_generic[Info](
		method:     .get
		prefix:     '/api/v1/admin'
		dataformat: .json
	)!
}

// Get public key for a node IP
pub fn (mut self Mycelium) get_pubkey_from_ip(ip string) !PublicKeyResponse {
	mut conn := self.connection()!
	return conn.get_json_generic[PublicKeyResponse](
		method:     .get
		prefix:     '/api/v1/pubkey/${ip}'
		dataformat: .json
	)!
}
