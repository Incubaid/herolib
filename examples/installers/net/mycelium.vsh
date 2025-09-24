#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.installers.net.mycelium_installer
import freeflowuniverse.herolib.clients.mycelium

mut installer := mycelium_installer.get(create: true)!
println(installer)

installer.start()!

// $dbg;

mut r := mycelium.inspect()!
println(r)

// $dbg;

mut client := mycelium.get()!

// Send a message to a node by public key
// Parameters: public_key, payload, topic, wait_for_reply
msg := client.send_msg(
	public_key: 'abc123...'   // destination public key
	payload:    'Hello World' // message payload
	topic:      'greetings'   // optional topic
	wait:       true          // wait for reply
)!
println('Sent message ID: ${msg.id}')

// Receive messages
// Parameters: wait_for_message, peek_only, topic_filter
received := client.receive_msg(wait: true, peek: false, topic: 'greetings')!
println('Received message from: ${received.src_pk}')
println('Message payload: ${received.payload}')

// Reply to a message
client.reply_msg(
	id:         received.id         // original message ID
	public_key: received.src_pk     // sender's public key
	payload:    'Got your message!' // reply payload
	topic:      'greetings'         // topic
)!

// Check message status
status := client.get_msg_status(msg.id)!
println('Message status: ${status.state}')
println('Created at: ${status.created}')
println('Expires at: ${status.deadline}')
