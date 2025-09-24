module mycelium_rpc

import freeflowuniverse.herolib.data.encoderhero
import freeflowuniverse.herolib.schemas.jsonrpc

pub const version = '0.0.0'
const singleton = true
const default = false

// Default configuration for Mycelium JSON-RPC API
pub const default_url = 'http://localhost:8990'

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

@[heap]
pub struct MyceliumRPC {
pub mut:
	name string = 'default'
	url  string = default_url // RPC server URL
	// rpc_client ?&jsonrpc.Client @[skip]
}

// your checking & initialization code if needed
fn obj_init(mycfg_ MyceliumRPC) !MyceliumRPC {
	mut mycfg := mycfg_
	if mycfg.url == '' {
		mycfg.url = default_url
	}
	// For now, we'll initialize the client when needed
	// The actual client will be created in the factory
	return mycfg
}

// Response structs based on OpenRPC specification

// Info represents general information about a node
pub struct Info {
pub mut:
	node_subnet string @[json: 'nodeSubnet'] // The subnet owned by the node and advertised to peers
	node_pubkey string @[json: 'nodePubkey'] // The public key of the node (hex encoded, 64 chars)
}

// Endpoint represents identification to connect to a peer
pub struct Endpoint {
pub mut:
	proto       string @[json: 'proto']      // Protocol used (tcp, quic)
	socket_addr string @[json: 'socketAddr'] // The socket address used
}

// PeerStats represents info about a peer
pub struct PeerStats {
pub mut:
	endpoint         Endpoint @[json: 'endpoint']        // Peer endpoint
	peer_type        string   @[json: 'type']            // How we know about this peer (static, inbound, linkLocalDiscovery)
	connection_state string   @[json: 'connectionState'] // Current state of connection (alive, connecting, dead)
	tx_bytes         i64      @[json: 'txBytes']         // Bytes transmitted to this peer
	rx_bytes         i64      @[json: 'rxBytes']         // Bytes received from this peer
}

// Route represents information about a route
pub struct Route {
pub mut:
	subnet   string @[json: 'subnet']  // The overlay subnet for which this is the route
	next_hop string @[json: 'nextHop'] // Way to identify the next hop of the route
	metric   string @[json: 'metric']  // The metric of the route (can be int or "infinite")
	seqno    int    @[json: 'seqno']   // Sequence number advertised with this route
}

// QueriedSubnet represents information about a subnet currently being queried
pub struct QueriedSubnet {
pub mut:
	subnet     string // The overlay subnet which we are currently querying
	expiration string // Amount of seconds until the query expires
}

// NoRouteSubnet represents information about a subnet marked as no route
pub struct NoRouteSubnet {
pub mut:
	subnet     string // The overlay subnet which is marked
	expiration string // Amount of seconds until the entry expires
}

// InboundMessage represents a message received by the system
pub struct InboundMessage {
pub mut:
	id      string @[json: 'id']      // Id of the message, hex encoded (16 chars)
	src_ip  string @[json: 'srcIp']   // Sender overlay IP address (IPv6)
	src_pk  string @[json: 'srcPk']   // Sender public key, hex encoded (64 chars)
	dst_ip  string @[json: 'dstIp']   // Receiver overlay IP address (IPv6)
	dst_pk  string @[json: 'dstPk']   // Receiver public key, hex encoded (64 chars)
	topic   string @[json: 'topic']   // Optional message topic (base64 encoded, 0-340 chars)
	payload string @[json: 'payload'] // Message payload, base64 encoded
}

// MessageDestination represents the destination for a message
pub struct MessageDestination {
pub mut:
	ip string // Target IP of the message (IPv6)
	pk string // Hex encoded public key of the target node (64 chars)
}

// PushMessageBody represents a message to send to a given receiver
pub struct PushMessageBody {
pub mut:
	dst     MessageDestination // Message destination
	topic   string             // Optional message topic (base64 encoded, 0-340 chars)
	payload string             // Message to send, base64 encoded
}

// PushMessageResponseId represents the ID generated for a message after pushing
pub struct PushMessageResponseId {
pub mut:
	id string // Id of the message, hex encoded (16 chars)
}

// MessageStatusResponse represents information about an outbound message
pub struct MessageStatusResponse {
pub mut:
	dst      string @[json: 'dst']      // IP address of the receiving node (IPv6)
	state    string @[json: 'state']    // Transmission state
	created  i64    @[json: 'created']  // Unix timestamp of when this message was created
	deadline i64    @[json: 'deadline'] // Unix timestamp of when this message will expire
	msg_len  int    @[json: 'msgLen']   // Length of the message in bytes
}

// PublicKeyResponse represents public key requested based on a node's IP
pub struct PublicKeyResponse {
pub mut:
	node_pub_key string @[json: 'NodePubKey'] // Public key (hex encoded, 64 chars)
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj MyceliumRPC) !string {
	return encoderhero.encode[MyceliumRPC](obj)!
}

pub fn heroscript_loads(heroscript string) !MyceliumRPC {
	mut obj := encoderhero.decode[MyceliumRPC](heroscript)!
	return obj
}

// Factory function to create a new MyceliumRPC client instance
@[params]
pub struct NewClientArgs {
pub mut:
	name string = 'default'
	url  string = default_url
}

pub fn new_client(args NewClientArgs) !&MyceliumRPC {
	mut client := MyceliumRPC{
		name: args.name
		url:  args.url
	}
	client = obj_init(client)!
	return &client
}
