module herofs

import crypto.blake3
import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// FsBlob represents binary data up to 1MB
@[heap]
pub struct FsBlob {
	db.Base
pub mut:
	hash       string // blake192 hash of content
	data       []u8   // Binary data (max 1MB)
	size_bytes int    // Size in bytes
	created_at i64
	mime_type  string // MIME type
	encoding   string // Encoding type
}

pub struct DBFsBlob {
pub mut:
	db      &db.DB     @[skip; str: skip]
	factory &FsFactory = unsafe { nil } @[skip; str: skip]
}

pub fn (self FsBlob) type_name() string {
	return 'fs_blob'
}

pub fn (self FsBlob) dump(mut e encoder.Encoder) ! {
	e.add_string(self.hash)
	e.add_list_u8(self.data)
	e.add_int(self.size_bytes)
	e.add_i64(self.created_at)
	e.add_string(self.mime_type)
	e.add_string(self.encoding)
}

fn (mut self DBFsBlob) load(mut o FsBlob, mut e encoder.Decoder) ! {
	o.hash = e.get_string()!
	o.data = e.get_list_u8()!
	o.size_bytes = e.get_int()!
	o.created_at = e.get_i64()!
	o.mime_type = e.get_string()!
	o.encoding = e.get_string()!
}

@[params]
pub struct FsBlobArg {
pub mut:
	data       []u8 @[required]
	mime_type  string
	encoding   string
	created_at i64
}

pub fn (mut blob FsBlob) calculate_hash() {
	hash := blake3.sum256(blob.data)
	blob.hash = hash.hex()[..48] // blake192 = first 192 bits = 48 hex chars
}

// get new blob, not from the DB
pub fn (mut self DBFsBlob) new(args FsBlobArg) !FsBlob {
	if args.data.len > 1024 * 1024 { // 1MB limit
		return error('Blob size exceeds 1MB limit')
	}

	mut o := FsBlob{
		data:       args.data
		size_bytes: args.data.len
		created_at: if args.created_at != 0 { args.created_at } else { ourtime.now().unix() }
		mime_type:  args.mime_type
		encoding:   args.encoding
	}

	// Calculate hash
	o.calculate_hash()

	// Set base fields
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBFsBlob) set(o_ FsBlob) !FsBlob {
	// Use db set function which now modifies the object in-place
	o := self.db.set[FsBlob](o_)!

	// Store the hash -> id mapping for lookup
	self.db.redis.hset('fsblob:hashes', o.hash, o.id.str())!

	return o
}

pub fn (mut self DBFsBlob) delete(id u32) ! {
	// Get the blob to retrieve its hash
	mut blob := self.get(id)!

	// Remove hash -> id mapping
	self.db.redis.hdel('fsblob:hashes', blob.hash)!

	// Delete the blob
	self.db.delete[FsBlob](id)!
}

pub fn (mut self DBFsBlob) delete_multi(ids []u32) ! {
	for id in ids {
		self.delete(id)!
	}
}

pub fn (mut self DBFsBlob) exist(id u32) !bool {
	return self.db.exists[FsBlob](id)!
}

pub fn (mut self DBFsBlob) exist_multi(ids []u32) !bool {
	for id in ids {
		if !self.exist(id)! {
			return false
		}
	}
	return true
}

pub fn (mut self DBFsBlob) get(id u32) !FsBlob {
	mut o, data := self.db.get_data[FsBlob](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBFsBlob) get_multi(id []u32) ![]FsBlob {
	mut blobs := []FsBlob{}
	for i in id {
		blobs << self.get(i)!
	}
	return blobs
}

pub fn (mut self DBFsBlob) get_by_hash(hash string) !FsBlob {
	// Get blob ID from Redis hash mapping
	id_str := self.db.redis.hget('fsblob:hashes', hash)!
	if id_str == '' {
		return error('Blob with hash ${hash} not found')
	}

	id := id_str.u32()
	return self.get(id)!
}

pub fn (mut self DBFsBlob) exists_by_hash(hash string) !bool {
	// Check if hash exists in Redis mapping
	id_str := self.db.redis.hget('fsblob:hashes', hash)!
	return id_str != ''
}

pub fn (blob FsBlob) verify_integrity() bool {
	hash := blake3.sum256(blob.data)
	return hash.hex()[..48] == blob.hash
}

pub fn (mut self DBFsBlob) verify(hash string) !bool {
	blob := self.get_by_hash(hash)!
	return blob.verify_integrity()
}
