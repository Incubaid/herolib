module heromodels

import time
import crypto.blake3
import json

// ChatGroup represents a chat channel or conversation
@[heap]
pub struct ChatGroup {
pub mut:
	chat_type     ChatType
	messages      []u32 // IDs of chat messages
	created_at    i64
	updated_at    i64
	last_activity i64
	is_archived   bool
	tags          []string
}

pub enum ChatType {
	public_channel
	private_channel
	direct_message
	group_message
}
