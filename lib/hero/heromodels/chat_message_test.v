#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module heromodels

import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.data.ourtime

// Test ChatMessage model CRUD operations
fn test_chat_message_new() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }
	now := ourtime.now().unix()

	// Test creating a new chat message with all fields
	mut message := mydb.chat_message.new(
		name:            'MSG-001'
		description:     'Important team announcement'
		content:         'Hello team! We have an important announcement about the upcoming release.'
		chat_group_id:   1
		sender_id:       123
		parent_messages: [
			MessageLink{
				message_id: 100
				link_type:  .reply
			},
		]
		fs_files:        [u32(200), 300]
		message_type:    .text
		status:          .sent
		reactions:       [
			MessageReaction{
				user_id:   456
				emoji:     '👍'
				timestamp: now
			},
			MessageReaction{
				user_id:   789
				emoji:     '❤️'
				timestamp: now
			},
		]
		mentions:        [u32(456), 789, 101]
		securitypolicy:  1
		tags:            ['announcement', 'important']
		comments:        []
	) or { panic('Failed to create chat message: ${err}') }

	// Verify the message was created with correct values
	assert message.name == 'MSG-001'
	assert message.description == 'Important team announcement'
	assert message.content == 'Hello team! We have an important announcement about the upcoming release.'
	assert message.chat_group_id == 1
	assert message.sender_id == 123
	assert message.parent_messages.len == 1
	assert message.parent_messages[0].message_id == 100
	assert message.parent_messages[0].link_type == .reply
	assert message.fs_files.len == 2
	assert message.fs_files[0] == 200
	assert message.message_type == .text
	assert message.status == .sent
	assert message.reactions.len == 2
	assert message.reactions[0].user_id == 456
	assert message.reactions[0].emoji == '👍'
	assert message.mentions.len == 3
	assert message.mentions[0] == 456
	assert message.id == 0 // Should be 0 before saving
	assert message.updated_at > 0 // Should have timestamp
}

fn test_chat_message_set_and_get() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create a chat message
	mut message := mydb.chat_message.new(
		name:            'MSG-002'
		description:     'Simple text message'
		content:         'Hey everyone, how is the project going?'
		chat_group_id:   2
		sender_id:       456
		parent_messages: []MessageLink{}
		fs_files:        []u32{}
		message_type:    .text
		status:          .delivered
		reactions:       []MessageReaction{}
		mentions:        []u32{}
		securitypolicy:  1
		tags:            ['casual', 'question']
		comments:        []
	) or { panic('Failed to create chat message: ${err}') }

	// Save the message
	message = mydb.chat_message.set(message) or { panic('Failed to save chat message: ${err}') }

	// Verify ID was assigned
	assert message.id > 0
	original_id := message.id

	// Retrieve the message
	retrieved_message := mydb.chat_message.get(message.id) or {
		panic('Failed to get chat message: ${err}')
	}

	// Verify all fields match
	assert retrieved_message.id == original_id
	assert retrieved_message.name == 'MSG-002'
	assert retrieved_message.description == 'Simple text message'
	assert retrieved_message.content == 'Hey everyone, how is the project going?'
	assert retrieved_message.chat_group_id == 2
	assert retrieved_message.sender_id == 456
	assert retrieved_message.parent_messages.len == 0
	assert retrieved_message.fs_files.len == 0
	assert retrieved_message.message_type == .text
	assert retrieved_message.status == .delivered
	assert retrieved_message.reactions.len == 0
	assert retrieved_message.mentions.len == 0
	assert retrieved_message.created_at > 0
	assert retrieved_message.updated_at > 0
}

fn test_chat_message_types_and_status() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test different message types
	message_types := [heromodels.MessageType.text, .image, .file, .system]
	statuses := [heromodels.MessageStatus.sent, .delivered, .read, .failed, .deleted]

	for i, msg_type in message_types {
		status := statuses[i % statuses.len]

		mut message := mydb.chat_message.new(
			name:            'TEST-${i}'
			description:     'Testing ${msg_type} with ${status} status'
			content:         'Test message content for ${msg_type}'
			chat_group_id:   1
			sender_id:       u32(i + 1)
			parent_messages: []MessageLink{}
			fs_files:        []u32{}
			message_type:    heromodels.MessageType(msg_type)
			status:          heromodels.MessageStatus(status)
			reactions:       []MessageReaction{}
			mentions:        []u32{}
			securitypolicy:  1
			tags:            ['test']
			comments:        []
		) or { panic('Failed to create message with type ${msg_type}: ${err}') }

		message = mydb.chat_message.set(message) or {
			panic('Failed to save message with type ${msg_type}: ${err}')
		}

		retrieved_message := mydb.chat_message.get(message.id) or {
			panic('Failed to get message with type ${msg_type}: ${err}')
		}
		assert retrieved_message.message_type == heromodels.MessageType(msg_type)
		assert retrieved_message.status == heromodels.MessageStatus(status)
	}
}

fn test_chat_message_reactions() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }
	now := ourtime.now().unix()

	// Create message with multiple reactions
	mut message := mydb.chat_message.new(
		name:            'REACT-MSG'
		description:     'Message with reactions'
		content:         'This is a great idea! 🎉'
		chat_group_id:   1
		sender_id:       100
		parent_messages: []MessageLink{}
		fs_files:        []u32{}
		message_type:    .text
		status:          .read
		reactions:       [
			MessageReaction{
				user_id:   101
				emoji:     '👍'
				timestamp: now
			},
			MessageReaction{
				user_id:   102
				emoji:     '❤️'
				timestamp: now
			},
			MessageReaction{
				user_id:   103
				emoji:     '😂'
				timestamp: now
			},
			MessageReaction{
				user_id:   104
				emoji:     '👍'
				timestamp: now
			},
		]
		mentions:        []u32{}
		securitypolicy:  1
		tags:            ['positive', 'reactions']
		comments:        []
	) or { panic('Failed to create message with reactions: ${err}') }

	message = mydb.chat_message.set(message) or { panic('Failed to save message with reactions: ${err}') }

	retrieved_message := mydb.chat_message.get(message.id) or {
		panic('Failed to get message with reactions: ${err}')
	}

	// Verify all reactions are preserved
	assert retrieved_message.reactions.len == 4

	// Count reaction types
	mut thumbs_up_count := 0
	mut heart_count := 0
	mut laugh_count := 0

	for reaction in retrieved_message.reactions {
		match reaction.emoji {
			'👍' { thumbs_up_count++ }
			'❤️' { heart_count++ }
			'😂' { laugh_count++ }
			else {}
		}
	}

	assert thumbs_up_count == 2
	assert heart_count == 1
	assert laugh_count == 1
}

fn test_chat_message_thread() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create original message
	mut original_message := mydb.chat_message.new(
		name:            'THREAD-ORIGINAL'
		description:     'Original message in thread'
		content:         'What do you think about the new feature proposal?'
		chat_group_id:   1
		sender_id:       200
		parent_messages: []MessageLink{}
		fs_files:        []u32{}
		message_type:    .text
		status:          .read
		reactions:       []MessageReaction{}
		mentions:        []u32{}
		securitypolicy:  1
		tags:            ['discussion', 'feature']
		comments:        []
	) or { panic('Failed to create original message: ${err}') }

	original_message = mydb.chat_message.set(original_message) or {
		panic('Failed to save original message: ${err}')
	}
	original_id := original_message.id

	// Create reply message
	mut reply_message := mydb.chat_message.new(
		name:            'THREAD-REPLY-1'
		description:     'Reply to original message'
		content:         "I think it's a great idea! We should implement it."
		chat_group_id:   1
		sender_id:       201
		parent_messages: [
			MessageLink{
				message_id: original_id
				link_type:  .reply
			},
		]
		fs_files:        []u32{}
		message_type:    .text
		status:          .sent
		reactions:       []MessageReaction{}
		mentions:        [u32(200)] // Mention original sender
		securitypolicy:  1
		tags:            ['reply', 'positive']
		comments:        []
	) or { panic('Failed to create reply message: ${err}') }

	reply_message = mydb.chat_message.set(reply_message) or { panic('Failed to save reply message: ${err}') }

	// Create another reply
	mut reply2_message := mydb.chat_message.new(
		name:            'THREAD-REPLY-2'
		description:     'Second reply to original message'
		content:         "I agree with @user201. Let's schedule a meeting to discuss details."
		chat_group_id:   1
		sender_id:       202
		parent_messages: [
			MessageLink{
				message_id: original_id
				link_type:  .reply
			},
		]
		fs_files:        []u32{}
		message_type:    .text
		status:          .delivered
		reactions:       []MessageReaction{}
		mentions:        [u32(200), 201] // Mention both previous users
		securitypolicy:  1
		tags:            ['reply', 'meeting']
		comments:        []
	) or { panic('Failed to create second reply message: ${err}') }

	reply2_message = mydb.chat_message.set(reply2_message) or {
		panic('Failed to save second reply message: ${err}')
	}

	// Verify thread structure
	retrieved_original := mydb.chat_message.get(original_id) or {
		panic('Failed to get original message: ${err}')
	}
	retrieved_reply1 := mydb.chat_message.get(reply_message.id) or {
		panic('Failed to get first reply: ${err}')
	}
	retrieved_reply2 := mydb.chat_message.get(reply2_message.id) or {
		panic('Failed to get second reply: ${err}')
	}

	// Original message should have no parent
	assert retrieved_original.parent_messages.len == 0

	// Both replies should reference the original message
	assert retrieved_reply1.parent_messages.len == 1
	assert retrieved_reply1.parent_messages[0].message_id == original_id
	assert retrieved_reply1.parent_messages[0].link_type == .reply
	assert retrieved_reply1.mentions.len == 1
	assert retrieved_reply1.mentions[0] == 200

	assert retrieved_reply2.parent_messages.len == 1
	assert retrieved_reply2.parent_messages[0].message_id == original_id
	assert retrieved_reply2.parent_messages[0].link_type == .reply
	assert retrieved_reply2.mentions.len == 2
	assert retrieved_reply2.mentions.contains(200)
	assert retrieved_reply2.mentions.contains(201)
}

fn test_chat_message_update() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }
	now := ourtime.now().unix()

	// Create and save a message
	mut message := mydb.chat_message.new(
		name:            'EDIT-MSG'
		description:     'Original message'
		content:         'Original content'
		chat_group_id:   1
		sender_id:       300
		parent_messages: []MessageLink{}
		fs_files:        []u32{}
		message_type:    .text
		status:          .sent
		reactions:       []MessageReaction{}
		mentions:        []u32{}
		securitypolicy:  1
		tags:            ['original']
		comments:        []
	) or { panic('Failed to create chat message: ${err}') }

	message = mydb.chat_message.set(message) or { panic('Failed to save chat message: ${err}') }
	original_id := message.id
	original_created_at := message.created_at
	original_updated_at := message.updated_at

	// Update the message
	message.name = 'EDIT-MSG-UPDATED'
	message.description = 'Updated message'
	message.content = 'Updated content - this message has been edited'
	message.status = .read
	message.reactions = [
		MessageReaction{
			user_id:   301
			emoji:     '👍'
			timestamp: now
		},
	]
	message.mentions = [u32(302)]

	message = mydb.chat_message.set(message) or { panic('Failed to update chat message: ${err}') }

	// Verify ID remains the same and updated_at is set
	assert message.id == original_id
	assert message.created_at == original_created_at
	assert message.updated_at >= original_updated_at

	// Retrieve and verify updates
	updated_message := mydb.chat_message.get(message.id) or {
		panic('Failed to get updated chat message: ${err}')
	}
	assert updated_message.name == 'EDIT-MSG-UPDATED'
	assert updated_message.description == 'Updated message'
	assert updated_message.content == 'Updated content - this message has been edited'
	assert updated_message.status == .read
	assert updated_message.reactions.len == 1
	assert updated_message.reactions[0].user_id == 301
	assert updated_message.mentions.len == 1
	assert updated_message.mentions[0] == 302
}
