module ledger

import incubaid.herolib.data.encoder
import incubaid.herolib.hero.db

// UserKVSItem represents a single item in a user's key-value store
@[heap]
pub struct UserKVSItem {
	db.Base
pub mut:
	kvs_id    u32    @[index]
	key       string @[index]
	value     string
}

pub struct DBUserKVSItem {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self UserKVSItem) type_name() string {
	return 'userkvsitem'
}

pub fn (self UserKVSItem) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a KVS item. Returns the ID of the item.'
		}
		'get' {
			return 'Retrieve a KVS item by ID. Returns the item object.'
		}
		'delete' {
			return 'Delete a KVS item by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a KVS item exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all KVS items. Returns an array of item objects.'
		}
		else {
			return 'User KVS item management operations'
		}
	}
}

pub fn (self UserKVSItem) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"userkvsitem": {"kvs_id": 1, "key": "mykey", "value": "myvalue"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"kvs_id": 1, "key": "mykey", "value": "myvalue"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"kvs_id": 1, "key": "mykey", "value": "myvalue"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self UserKVSItem) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.kvs_id)
	e.add_string(self.key)
	e.add_string(self.value)
	e.add_u64(self.timestamp)
}

fn (mut self DBUserKVSItem) load(mut o UserKVSItem, mut e encoder.Decoder) ! {
	o.kvs_id = e.get_u32()!
	o.key = e.get_string()!
	o.value = e.get_string()!
	o.timestamp = e.get_u64()!
}

@[params]
pub struct UserKVSItemArg {
pub mut:
	name        string
	description string
	kvs_id      u32
	key         string
	value       string
}

pub fn (mut self DBUserKVSItem) new(args UserKVSItemArg) !UserKVSItem {
	mut o := UserKVSItem{
		kvs_id:    args.kvs_id
		key:       args.key
		value:     args.value
		timestamp: u64(ourtime.now().unix())
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBUserKVSItem) set(o UserKVSItem) !UserKVSItem {
	return self.db.set[UserKVSItem](o)!
}

pub fn (mut self DBUserKVSItem) delete(id u32) ! {
	self.db.delete[UserKVSItem](id)!
}

pub fn (mut self DBUserKVSItem) exist(id u32) !bool {
	return self.db.exists[UserKVSItem](id)!
}

pub fn (mut self DBUserKVSItem) get(id u32) !UserKVSItem {
	mut o, data := self.db.get_data[UserKVSItem](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBUserKVSItem) list() ![]UserKVSItem {
	return self.db.list[UserKVSItem]()!.map(self.get(it)!)
}
