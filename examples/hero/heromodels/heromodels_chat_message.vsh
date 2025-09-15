#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!

// First create a chat group to reference
mut chat_group := mydb.chat_group.new(
	name:          'General Discussion'
	description:   'A public channel for general discussions'
	chat_type:     .public_channel
	last_activity: 0
	is_archived:   false
)!
chat_group_id := mydb.chat_group.set(chat_group)!

// Create a new chat message
mut chat_message := mydb.chat_message.new(
	name:            'Hello World Message'
	description:     'A simple hello world message'
	content:         'Hello, world!'
	chat_group_id:   chat_group_id
	sender_id:       1
	parent_messages: []
	fs_files:        []
	message_type:    .text
	status:          .sent
	reactions:       []
	mentions:        []
)!

// Save to database
oid := mydb.chat_message.set(chat_message)!
println('Created chat message with ID: ${oid}')

// Retrieve from database
mut chat_message2 := mydb.chat_message.get(oid)!
println('Retrieved chat message: ${chat_message2}')

// List all chat messages
mut chat_messages := mydb.chat_message.list()!
println('All chat messages: ${chat_messages}')

// Update the chat message
chat_message2.status = .read
mydb.chat_message.set(chat_message2)!

// Retrieve updated chat message
mut chat_message3 := mydb.chat_message.get(oid)!
println('Updated chat message: ${chat_message3}')
