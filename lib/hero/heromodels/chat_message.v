module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_ok, new_response_true }
import freeflowuniverse.herolib.hero.user { UserRef }
import json

// ChatMessage represents a message in a chat group
@[heap]
pub struct ChatMessage {
	db.Base
pub mut:
	content         string
	chat_group_id   u32           // Associated chat group
	sender_id       u32           // User ID of sender
	parent_messages []MessageLink // Referenced/replied messages
	fs_files        []u32         // IDs of linked files
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

pub struct DBChatMessage {
pub mut:
	db &db.DB @[skip; str: skip]
}

@[params]
pub struct ChatMessageListArg {
pub mut:
	chat_group_id u32
	message_type  MessageType
	status        MessageStatus
	limit         int = 100 // Default limit is 100
}

pub fn (self ChatMessage) type_name() string {
	return 'chat_message'
}

// return example rpc call and result for each methodname
pub fn (self ChatMessage) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a chat message. Returns the ID of the message.'
		}
		'get' {
			return 'Retrieve a chat message by ID. Returns the message object.'
		}
		'delete' {
			return 'Delete a chat message by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a chat message exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all chat messages. Returns an array of message objects.'
		}
		else {
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

// return example rpc call and result for each methodname
pub fn (self ChatMessage) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"chat_message": {"content": "Hello, everyone!", "chat_group_id": 1, "sender_id": 1, "parent_messages": [{"message_id": 123, "link_type": "reply"}], "fs_files": [], "message_type": "text", "status": "sent", "reactions": [{"user_id": 2, "emoji": "👍", "timestamp": 1678886400}], "mentions": [2, 3]}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"content": "Hello, everyone!", "chat_group_id": 1, "sender_id": 1, "parent_messages": [{"message_id": 123, "link_type": "reply"}], "fs_files": [], "message_type": "text", "status": "sent", "reactions": [{"user_id": 2, "emoji": "👍", "timestamp": 1678886400}], "mentions": [2, 3]}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"content": "Hello, everyone!", "chat_group_id": 1, "sender_id": 1, "parent_messages": [{"message_id": 123, "link_type": "reply"}], "fs_files": [], "message_type": "text", "status": "sent", "reactions": [{"user_id": 2, "emoji": "👍", "timestamp": 1678886400}], "mentions": [2, 3]}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self ChatMessage) dump(mut e encoder.Encoder) ! {
	e.add_string(self.content)
	e.add_u32(self.chat_group_id)
	e.add_u32(self.sender_id)

	// Encode parent_messages array
	e.add_u16(u16(self.parent_messages.len))
	for link in self.parent_messages {
		e.add_u32(link.message_id)
		e.add_u8(u8(link.link_type))
	}

	e.add_list_u32(self.fs_files)
	e.add_u8(u8(self.message_type))
	e.add_u8(u8(self.status))

	// Encode reactions array
	e.add_u16(u16(self.reactions.len))
	for reaction in self.reactions {
		e.add_u32(reaction.user_id)
		e.add_string(reaction.emoji)
		e.add_i64(reaction.timestamp)
	}

	e.add_list_u32(self.mentions)
}

pub fn (mut self DBChatMessage) load(mut o ChatMessage, mut e encoder.Decoder) ! {
	o.content = e.get_string()!
	o.chat_group_id = e.get_u32()!
	o.sender_id = e.get_u32()!

	// Decode parent_messages array
	parent_messages_len := e.get_u16()!
	mut parent_messages := []MessageLink{}
	for _ in 0 .. parent_messages_len {
		message_id := e.get_u32()!
		link_type := unsafe { MessageLinkType(e.get_u8()!) }
		parent_messages << MessageLink{
			message_id: message_id
			link_type:  link_type
		}
	}
	o.parent_messages = parent_messages

	o.fs_files = e.get_list_u32()!
	o.message_type = unsafe { MessageType(e.get_u8()!) }
	o.status = unsafe { MessageStatus(e.get_u8()!) }

	// Decode reactions array
	reactions_len := e.get_u16()!
	mut reactions := []MessageReaction{}
	for _ in 0 .. reactions_len {
		user_id := e.get_u32()!
		emoji := e.get_string()!
		timestamp := e.get_i64()!
		reactions << MessageReaction{
			user_id:   user_id
			emoji:     emoji
			timestamp: timestamp
		}
	}
	o.reactions = reactions

	o.mentions = e.get_list_u32()!
}

@[params]
pub struct ChatMessageArg {
pub mut:
	name            string
	description     string
	content         string
	chat_group_id   u32
	sender_id       u32
	parent_messages []MessageLink
	fs_files        []u32
	message_type    MessageType
	status          MessageStatus
	reactions       []MessageReaction
	mentions        []u32
	securitypolicy  u32
	tags            []string
	messages        []db.MessageArg
}

// get new chat message, not from the DB
pub fn (mut self DBChatMessage) new(args ChatMessageArg) !ChatMessage {
	mut o := ChatMessage{
		content:         args.content
		chat_group_id:   args.chat_group_id
		sender_id:       args.sender_id
		parent_messages: args.parent_messages
		fs_files:        args.fs_files
		message_type:    args.message_type
		status:          args.status
		reactions:       args.reactions
		mentions:        args.mentions
	}

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!
	o.messages = self.db.messages_get(args.messages)!
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBChatMessage) set(o ChatMessage) !ChatMessage {
	// Use db set function which returns the object with assigned ID
	return self.db.set[ChatMessage](o)!
}

pub fn (mut self DBChatMessage) delete(id u32) ! {
	self.db.delete[ChatMessage](id)!
}

pub fn (mut self DBChatMessage) exist(id u32) !bool {
	return self.db.exists[ChatMessage](id)!
}

pub fn (mut self DBChatMessage) get(id u32) !ChatMessage {
	mut o, data := self.db.get_data[ChatMessage](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBChatMessage) list() ![]ChatMessage {
	return self.db.list[ChatMessage]()!.map(self.get(it)!)
}

pub fn chat_message_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.chat_message.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut o := db.decode_generic[ChatMessage](params)!
			o = f.chat_message.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			f.chat_message.delete(id)!
			return new_response_ok(rpcid)
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.chat_message.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			res := f.chat_message.list()!
			return new_response(rpcid, json.encode(res))
		}
		else {
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on chat_message'
			)
		}
	}
}
