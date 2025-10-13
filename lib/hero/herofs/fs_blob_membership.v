module herofs

import incubaid.herolib.data.encoder
import incubaid.herolib.hero.db
import incubaid.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_ok, new_response_true }
import incubaid.herolib.hero.user { UserRef }
import incubaid.herolib.ui.console
import json

// FsBlobMembership represents membership of a blob in one or more filesystems, the key is the hash of the blob
@[heap]
pub struct FsBlobMembership {
pub mut:
	hash   string // blake192 hash of content (key)
	fsid   []u32  // list of fs ids where this blob is used
	blobid u32    // id of the blob
}

pub struct DBFsBlobMembership {
pub mut:
	db      &db.DB     @[skip; str: skip]
	factory &FSFactory = unsafe { nil } @[skip; str: skip]
}

pub fn (self FsBlobMembership) type_name() string {
	return 'fs_blob_membership'
}

pub fn (self FsBlobMembership) dump(mut e encoder.Encoder) ! {
	e.add_string(self.hash)
	e.add_list_u32(self.fsid)
	e.add_u32(self.blobid)
}

fn (self DBFsBlobMembership) load(mut o FsBlobMembership, mut e encoder.Decoder) ! {
	o.hash = e.get_string()!
	o.fsid = e.get_list_u32()!
	o.blobid = e.get_u32()!
}

@[params]
pub struct FsBlobMembershipArg {
pub mut:
	hash   string @[required]
	fsid   []u32  @[required]
	blobid u32    @[required]
}

pub fn (self DBFsBlobMembership) new(args FsBlobMembershipArg) !FsBlobMembership {
	o := FsBlobMembership{
		hash:   args.hash
		fsid:   args.fsid
		blobid: args.blobid
	}

	return o
}

pub fn (mut self DBFsBlobMembership) set(o FsBlobMembership) !FsBlobMembership {
	// Validate that the blob exists
	if o.blobid == 0 {
		return error('Blob ID cannot be 0')
	}
	blob_exists := self.factory.fs_blob.exist(o.blobid)!
	if !blob_exists {
		return error('Blob with ID ${o.blobid} does not exist')
	}

	mut o_mut := o

	if o_mut.hash == '' {
		blob := self.factory.fs_blob.get(o_mut.blobid) or {
			return error('Failed to retrieve blob with ID ${o_mut.blobid}: ${err.msg()}')
		}
		o_mut.hash = blob.hash
	}

	if o_mut.fsid.len == 0 {
		return error('Blob membership filesystem IDs cannot be empty')
	}

	// Validate that all filesystems exist
	for fs_id in o_mut.fsid {
		fs_exists := self.factory.fs.exist(fs_id)!
		if !fs_exists {
			return error('Filesystem with ID ${fs_id} does not exist')
		}
	}

	// Encode the object
	mut e_encoder := encoder.new()
	o_mut.dump(mut e_encoder)!

	// Store using hash as key in the blob_membership hset
	self.db.redis.hset('fs_blob_membership', o_mut.hash, e_encoder.data.bytestr())!

	return o_mut
}

pub fn (mut self DBFsBlobMembership) delete(hash string) ! {
	self.db.redis.hdel('fs_blob_membership', hash)!
}

pub fn (mut self DBFsBlobMembership) exist(hash string) !bool {
	return self.db.redis.hexists('fs_blob_membership', hash)!
}

pub fn (mut self DBFsBlobMembership) get(hash string) !FsBlobMembership {
	// Get the data from Redis
	data := self.db.redis.hget('fs_blob_membership', hash)!
	if data == '' {
		return error('Blob membership with hash "${hash}" not found')
	}
	data2 := data.bytes()
	// Create object and decode
	mut o := FsBlobMembership{}
	mut e_decoder := encoder.decoder_new(data2)
	self.load(mut o, mut e_decoder)!

	return o
}

// Add a filesystem to an existing blob membership
pub fn (mut self DBFsBlobMembership) add_filesystem(hash string, fs_id u32) ! {
	// Validate filesystem exists
	fs_exists := self.factory.fs.exist(fs_id)!
	if !fs_exists {
		return error('Filesystem with ID ${fs_id} does not exist')
	}

	mut membership := self.get(hash)!

	// Check if filesystem is already in the list
	if fs_id !in membership.fsid {
		membership.fsid << fs_id
	}

	self.set(membership)!
}

// Remove a filesystem from an existing blob membership
pub fn (mut self DBFsBlobMembership) remove_filesystem(hash string, fs_id u32) ! {
	mut membership := self.get(hash)!

	// Remove filesystem from the list
	membership.fsid = membership.fsid.filter(it != fs_id)

	// If no filesystems left, delete the membership entirely
	if membership.fsid.len == 0 {
		self.delete(hash)!
		return
	}

	self.set(membership)!
}

// BlobList represents a simplified blob structure for listing purposes
pub struct BlobList {
pub mut:
	id   u32
	hash string
	size int
}

// list_by_hash_prefix lists blob memberships where hash starts with the given prefix
// Returns maximum 10000 items as FsBlobMembership entries
pub fn (mut self DBFsBlobMembership) list_prefix(prefix string) ![]FsBlobMembership {
	mut result := []FsBlobMembership{}
	mut cursor := 0
	mut count := 0

	for {
		if count >= 10000 {
			break
		}

		// Use hscan with MATCH pattern and COUNT to iterate through the hash
		new_cursor, values := self.db.redis.hscan('fs_blob_membership', cursor,
			match: '${prefix}*'
			count: 100
		)!

		// Process the returned field-value pairs
		// hscan returns alternating field-value pairs, so we iterate by 2
		mut i := 0
		for i < values.len && count < 10000 {
			hash := values[i]
			// Skip the value (we don't need it since we'll get the object by hash)
			i += 2

			if hash.starts_with(prefix) {
				result << self.get(hash)!
				count++
			}
		}

		// If cursor is "0", we've completed the full iteration
		if new_cursor == '0' {
			break
		}

		cursor = new_cursor.int()
	}

	return result
}

pub fn (self FsBlobMembership) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a blob membership. Returns success.'
		}
		'get' {
			return 'Retrieve a blob membership by hash. Returns the membership object.'
		}
		'delete' {
			return 'Delete a blob membership by hash. Returns true if successful.'
		}
		'exist' {
			return 'Check if a blob membership exists by hash. Returns true or false.'
		}
		'add_filesystem' {
			return 'Add a filesystem to a blob membership. Returns success.'
		}
		'remove_filesystem' {
			return 'Remove a filesystem from a blob membership. Returns success.'
		}
		else {
			return 'This is generic method for the blob membership object.'
		}
	}
}

pub fn (self FsBlobMembership) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"membership": {"hash": "abc123...", "fsid": [1, 2], "blobid": 5}}', 'true'
		}
		'get' {
			return '{"hash": "abc123..."}', '{"hash": "abc123...", "fsid": [1, 2], "blobid": 5}'
		}
		'delete' {
			return '{"hash": "abc123..."}', 'true'
		}
		'exist' {
			return '{"hash": "abc123..."}', 'true'
		}
		'add_filesystem' {
			return '{"hash": "abc123...", "fs_id": 3}', 'true'
		}
		'remove_filesystem' {
			return '{"hash": "abc123...", "fs_id": 1}', 'true'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn fs_blob_membership_handle(mut f FSFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			hash := db.decode_string(params)!
			res := f.fs_blob_membership.get(hash)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut o := db.decode_generic[FsBlobMembership](params)!
			o = f.fs_blob_membership.set(o)!
			return new_response_ok(rpcid)
		}
		'delete' {
			hash := db.decode_string(params)!
			f.fs_blob_membership.delete(hash)!
			return new_response_ok(rpcid)
		}
		'exist' {
			hash := db.decode_string(params)!
			if f.fs_blob_membership.exist(hash)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		else {
			console.print_stderr('Method not found on fs_blob_membership: ${method}')
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on fs_blob_membership'
			)
		}
	}
}
