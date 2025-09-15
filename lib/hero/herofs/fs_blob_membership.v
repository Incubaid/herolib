module herofs

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.hero.db

// FsBlobMembership represents membership of a blob in one or more filesystems, the key is the hash of the blob
@[heap]
pub struct FsBlobMembership {
pub mut:
	hash   string // blake192 hash of content
	fsid   []u32  // list of fs ids where this blob is used
	blobid u32    // id of the blob
}

pub struct DBFsBlobMembership {
pub mut:
	db      &db.DB     @[skip; str: skip]
	factory &FsFactory = unsafe { nil } @[skip; str: skip]
}

pub fn (self FsBlobMembership) type_name() string {
	return 'fs_blob_membership'
}

pub fn (self FsBlobMembership) dump(mut e encoder.Encoder) ! {
	e.add_string(self.hash)
	e.add_list_u32(self.fsid)
	e.add_u32(self.blobid)
}

fn (mut self DBFsBlobMembership) load(mut o FsBlobMembership, mut e encoder.Decoder) ! {
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

// get new blob membership, not from the DB
pub fn (mut self DBFsBlobMembership) new(args FsBlobMembershipArg) !FsBlobMembership {
	mut o := FsBlobMembership{
		hash:   args.hash
		fsid:   args.fsid
		blobid: args.blobid
	}

	return o
}

pub fn (mut self DBFsBlobMembership) set(o FsBlobMembership) !string {
	// Validate that the blob exists
	blob_exists := self.factory.fs_blob.exists(o.blobid)!
	if !blob_exists {
		return error('Blob with ID ${o.blobid} does not exist')
	}

	// Validate that all filesystems exist
	for fs_id in o.fsid {
		fs_exists := self.factory.fs_file.exists(fs_id)!
		if !fs_exists {
			return error('Filesystem with ID ${fs_id} does not exist')
		}
	}

	// Encode the object
	mut e_encoder := encoder.new()
	o.dump(mut e_encoder)!

	// Store using hash as key in the blob_membership hset
	self.db.redis.hset('fs_blob_membership', o.hash, e_encoder.data.bytestr())!
	return o.hash
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

	// Decode hex data back to bytes
	data2 := data.bytes()

	// Create object and decode
	mut o := FsBlobMembership{}
	mut e_decoder := encoder.decoder_new(data2)
	self.load(mut o, mut e_decoder)!

	return o
}

// Add a filesystem to an existing blob membership
pub fn (mut self DBFsBlobMembership) add_filesystem(hash string, fs_id u32) !string {
	// Validate filesystem exists
	fs_exists := self.db.fs_file.exists(fs_id)!
	if !fs_exists {
		return error('Filesystem with ID ${fs_id} does not exist')
	}

	mut membership := self.get(hash)!

	// Check if filesystem is already in the list
	if fs_id !in membership.fsid {
		membership.fsid << fs_id
	}

	return self.set(membership)!
}

// Remove a filesystem from an existing blob membership
pub fn (mut self DBFsBlobMembership) remove_filesystem(hash string, fs_id u32) !string {
	mut membership := self.get(hash)!

	// Remove filesystem from the list
	membership.fsid = membership.fsid.filter(it != fs_id)

	// If no filesystems left, delete the membership entirely
	if membership.fsid.len == 0 {
		self.delete(hash)!
		return hash
	}

	return self.set(membership)!
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
pub fn (mut self DBFsBlobMembership) list(prefix string) ![]FsBlobMembership {
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
