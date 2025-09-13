module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// ChatGroup represents a chat channel or conversation
@[heap]
pub struct ChatGroup {
	db.Base
pub mut:
	chat_type     ChatType
	last_activity i64
	is_archived   bool
}

pub enum ChatType {
	public_channel
	private_channel
	direct_message
	group_message
}

pub struct DBChatGroup {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self ChatGroup) type_name() string {
	return 'chat_group'
}

pub fn (self ChatGroup) dump(mut e &encoder.Encoder) ! {
	e.add_u8(u8(self.chat_type))
	e.add_i64(self.last_activity)
	e.add_bool(self.is_archived)
}

fn (mut self DBChatGroup) load(mut o ChatGroup, mut e &encoder.Decoder) ! {
	o.chat_type = unsafe { ChatType(e.get_u8()!) }
	o.last_activity = e.get_i64()!
	o.is_archived = e.get_bool()!
}

@[params]
pub struct ChatGroupArg {
pub mut:
	name           string
	description    string
	chat_type      ChatType
	last_activity  i64
	is_archived    bool
	securitypolicy u32
	tags           []string
	comments       []db.CommentArg
}

// get new chat group, not from the DB
pub fn (mut self DBChatGroup) new(args ChatGroupArg) !ChatGroup {
	mut o := ChatGroup{
		chat_type:     args.chat_type
		last_activity: args.last_activity
		is_archived:   args.is_archived
	}

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!
	o.comments = self.db.comments_get(args.comments)!
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBChatGroup) set(o ChatGroup) !u32 {
	// Use db set function which now returns the ID
	return self.db.set[ChatGroup](o)!
}

pub fn (mut self DBChatGroup) delete(id u32) ! {
	self.db.delete[ChatGroup](id)!
}

pub fn (mut self DBChatGroup) exist(id u32) !bool {
	return self.db.exists[ChatGroup](id)!
}

pub fn (mut self DBChatGroup) get(id u32) !ChatGroup {
	mut o, data := self.db.get_data[ChatGroup](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBChatGroup) list() ![]ChatGroup {
	return self.db.list[ChatGroup]()!.map(self.get(it)!)
}
