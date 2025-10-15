# Mycelium RPC Client

This is a V language client for the Mycelium mesh networking system, implementing the JSON-RPC API specification for administrative operations.

## Overview

Mycelium is a mesh networking system that creates secure, encrypted connections between nodes. This client provides a comprehensive API to interact with Mycelium nodes via their JSON-RPC interface for administrative tasks such as:

- Node information retrieval
- Peer management
- Routing information
- Message operations
- Topic management

## Features

- Complete implementation of all methods in the Mycelium JSON-RPC specification
- Type-safe API with proper error handling
- HTTP transport support
- Comprehensive documentation
- Example code for all operations

## Usage

### Basic Example

```v
import incubaid.herolib.clients.mycelium_rpc

// Create a new client
mut client := mycelium_rpc.new_client(
    name: 'my_client'
    url: 'http://localhost:8990'
)!

// Get node information
info := client.get_info()!
println('Node Subnet: ${info.node_subnet}')
println('Node Public Key: ${info.node_pubkey}')

// List peers
peers := client.get_peers()!
for peer in peers {
    println('Peer: ${peer.endpoint.proto}://${peer.endpoint.socket_addr}')
    println('State: ${peer.connection_state}')
}
```

### Configuration

The client can be configured with:

- `name`: Client instance name (default: 'default')
- `url`: Mycelium node API URL (default: '<http://localhost:8990>')

### Available Methods

#### Admin Methods

- `get_info()` - Get general information about the node
- `get_peers()` - List known peers
- `add_peer(endpoint)` - Add a new peer
- `delete_peer(endpoint)` - Remove an existing peer
- `get_public_key_from_ip(ip)` - Get public key from node IP

#### Routing Methods

- `get_selected_routes()` - List all selected routes
- `get_fallback_routes()` - List all active fallback routes
- `get_queried_subnets()` - List currently queried subnets
- `get_no_route_entries()` - List subnets marked as no route

#### Message Methods

- `pop_message(peek, timeout, topic)` - Get message from inbound queue
- `push_message(message, reply_timeout)` - Submit new message to system
- `push_message_reply(id, message)` - Reply to a message
- `get_message_info(id)` - Get status of an outbound message

#### Topic Management Methods

- `get_default_topic_action()` - Get default topic action
- `set_default_topic_action(accept)` - Set default topic action
- `get_topics()` - Get all configured topics
- `add_topic(topic)` - Add new topic to whitelist
- `remove_topic(topic)` - Remove topic from whitelist
- `get_topic_sources(topic)` - Get sources for a topic
- `add_topic_source(topic, subnet)` - Add source to topic
- `remove_topic_source(topic, subnet)` - Remove source from topic
- `get_topic_forward_socket(topic)` - Get forward socket for topic
- `set_topic_forward_socket(topic, path)` - Set forward socket for topic
- `remove_topic_forward_socket(topic)` - Remove forward socket for topic

## Data Types

### Info

```v
struct Info {
    node_subnet string // The subnet owned by the node
    node_pubkey string // The public key of the node (hex encoded)
}
```

### PeerStats

```v
struct PeerStats {
    endpoint         Endpoint // Peer endpoint
    peer_type        string   // How we know about this peer
    connection_state string   // Current state of connection
    tx_bytes         i64      // Bytes transmitted to this peer
    rx_bytes         i64      // Bytes received from this peer
}
```

### InboundMessage

```v
struct InboundMessage {
    id      string // Message ID (hex encoded)
    src_ip  string // Sender overlay IP address
    src_pk  string // Sender public key (hex encoded)
    dst_ip  string // Receiver overlay IP address
    dst_pk  string // Receiver public key (hex encoded)
    topic   string // Optional message topic (base64 encoded)
    payload string // Message payload (base64 encoded)
}
```

## Examples

See `examples/clients/mycelium_rpc.vsh` for a comprehensive example that demonstrates:

- Node information retrieval
- Peer listing and management
- Routing information
- Topic management
- Message operations
- Error handling

## Requirements

- V language compiler
- Mycelium node running with API enabled
- Network connectivity to the Mycelium node

## Running the Example

```bash
# Make sure Mycelium is installed
v run examples/clients/mycelium_rpc.vsh
```

The example will:

1. Install Mycelium if needed
2. Start a Mycelium node with API enabled
3. Demonstrate various RPC operations
4. Clean up resources on exit

## Error Handling

All methods return Result types and should be handled appropriately:

```v
info := client.get_info() or {
    println('Error getting node info: ${err}')
    return
}
```

## Notes

- The client uses HTTP transport to communicate with the Mycelium node
- All JSON field names are properly mapped using V's `@[json: 'field_name']` attributes
- The client is thread-safe and can be used concurrently
- Message operations require multiple connected Mycelium nodes to be meaningful

## License

This client follows the same license as the HeroLib project.
