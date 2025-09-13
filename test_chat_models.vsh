#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.heromodels

fn main() {
	mut mydb := heromodels.new()!

	// Test chat group creation
	mut chat_group := mydb.chat_group.new(
		name: 'Test Group'
		description: 'A test chat group'
		chat_type: .public_channel
		last_activity: 1672531200
		is_archived: false
	)!
	
	// Save chat group
	chat_group_id := mydb.chat_group.set(chat_group)!
	println('Created chat group with ID: ${chat_group_id}')
	
	// Retrieve chat group
	mut retrieved_group := mydb.chat_group.get(chat_group_id)!
	println('Retrieved chat group: ${retrieved_group}')
	
	// Test chat message creation
	mut chat_message := mydb.chat_message.new(
		name: 'Test Message'
		description: 'A test chat message'
		content: 'This is a test message'
		chat_group_id: chat_group_id
		sender_id: 1
		parent_messages: []
		fs_files: []
		message_type: .text
		status: .sent
		reactions: []
		mentions: []
	)!
	
	// Save chat message
	message_id := mydb.chat_message.set(chat_message)!
	println('Created chat message with ID: ${message_id}')
	
	// Retrieve chat message
	mut retrieved_message := mydb.chat_message.get(message_id)!
	println('Retrieved chat message: ${retrieved_message}')
}
