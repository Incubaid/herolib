module heromodels

import time
import crypto.blake3
import json

// ChatMessage represents a message in a chat group
@[heap]
pub struct ChatMessage {
pub mut:
	content         string
	chat_group_id   u32        // Associated chat group
	sender_id       u32        // User ID of sender
	parent_messages []MessageLink // Referenced/replied messages
	fs_files        []u32      // IDs of linked files
	message_type    MessageType
	status          MessageStatus
	reactions       []MessageReaction
	mentions        []u32 // User IDs mentioned in message
}

pub struct MessageLink {
pub mut:
	message_id u32
	link_type  MessageLinkType
}

pub enum MessageLinkType {
	reply
	reference
	forward
	quote
}

pub enum MessageType {
	text
	image
	file
	voice
	video
	system
	announcement
}

pub enum MessageStatus {
	sent
	delivered
	read
	failed
	deleted
}

pub struct MessageReaction {
pub mut:
	user_id   u32
	emoji     string
	timestamp i64
}
