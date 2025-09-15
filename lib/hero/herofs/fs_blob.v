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
}

fn (mut self DBFsBlob) load(mut o FsBlob, mut e encoder.Decoder) ! {
	o.hash = e.get_string()!
	o.data = e.get_list_u8()!
	o.size_bytes = e.get_int()!
}

@[params]
pub struct FsBlobArg {
pub mut:
	data []u8 @[required]
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
	}

	// Calculate hash
	o.calculate_hash()

	// Set base fields
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBFsBlob) set(mut o FsBlob) ! {
	// Use db set function which now modifies the object in-place
	self.db.set[FsBlob](mut o)!

	// Store the hash -> id mapping for lookup
	self.db.redis.hset('fsblob:hashes', o.hash, o.id.str())!
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
	if self.factory.fs_blob_membership.exist(hash)! {
		o := self.factory.fs_blob_membership.get(hash) or { panic('bug') }
		return self.get(o.blobid)!
	}
	return error('Blob with hash ${hash} not found')
}

pub fn (mut self DBFsBlob) exists_by_hash(hash string) !bool {
	return self.factory.fs_blob_membership.exist(hash)
}

pub fn (blob FsBlob) verify_integrity() bool {
	hash := blake3.sum256(blob.data)
	return hash.hex()[..48] == blob.hash
}

pub fn (mut self DBFsBlob) verify(hash string) !bool {
	blob := self.get_by_hash(hash)!
	return blob.verify_integrity()
}
