# Mycelium Client

A V client library for interacting with the Mycelium messaging system. This client provides functionality for configuring and inspecting a Mycelium node.

## Components

The Mycelium integration consists of two main components:

1. **Mycelium Client** (this package) - For interacting with a running Mycelium node
2. **Mycelium Installer** (in `installers/net/mycelium/`) - For installing and managing Mycelium nodes

## Configuration

The client can be configured either through V code or using heroscript.

### V Code Configuration

```v
import incubaid.herolib.clients.mycelium

// Get default client instance
mut client := mycelium.get()!

// Get named client instance
mut client := mycelium.get(name: "custom")!
```

## Core Functions

### Inspect Node

Get information about the local Mycelium node:

```v
import incubaid.herolib.clients.mycelium

// Get node info including public key and address
result := mycelium.inspect()!
println('Public Key: ${result.public_key}')
println('Address: ${result.address}')

// Get just the IP address
addr := mycelium.ipaddr()
println('IP Address: ${addr}')
```

### Check Node Status

Check if the Mycelium node is running and reachable:

```v
import incubaid.herolib.clients.mycelium

is_running := mycelium.check()
if is_running {
    println('Mycelium node is running and reachable')
} else {
    println('Mycelium node is not running or unreachable')
}
```

### Sending and Receiving Messages

The client provides several functions for sending and receiving messages between nodes:

```v
import incubaid.herolib.clients.mycelium

mut client := mycelium.get()!

// Send a message to a node by public key
// Parameters: public_key, payload, topic, wait_for_reply
msg := client.send_msg(
    'abc123...', // destination public key
    'Hello World', // message payload
    'greetings', // optional topic
    true // wait for reply
)!
println('Sent message ID: ${msg.id}')

// Receive messages
// Parameters: wait_for_message, peek_only, topic_filter
received := client.receive_msg(true, false, 'greetings')!
println('Received message from: ${received.src_pk}')
println('Message payload: ${received.payload}')

// Reply to a message
client.reply_msg(
    received.id, // original message ID
    received.src_pk, // sender's public key
    'Got your message!', // reply payload
    'greetings' // topic
)!

// Check message status
status := client.get_msg_status(msg.id)!
println('Message status: ${status.state}')
println('Created at: ${status.created}')
println('Expires at: ${status.deadline}')
```

The messaging API supports:

- Sending messages to nodes identified by public key
- Optional message topics for filtering
- Waiting for replies when sending messages
- Peeking at messages without removing them from the queue
- Tracking message delivery status
- Base64 encoded message payloads for binary data

## Installation and Management

For installing and managing Mycelium nodes, use the Mycelium Installer package located in `installers/net/mycelium/`. The installer provides functionality for:

- Installing Mycelium nodes
- Starting/stopping nodes
- Managing node configuration
- Setting up TUN interfaces
- Configuring peer connections
