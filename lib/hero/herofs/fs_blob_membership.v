module herofs

import time
import crypto.blake3
import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

//IMPORTANT WHEN CREATING THIS TABLE WE NEED TO USE THE HASH AS THE KEY IN THE HSET (not the id, this one is not used, there is no base object for it)

//FsBlobMembership represents membership of a blob in one or more filesystems, the key is the hash of the blob
@[heap]
pub struct FsBlobMembership {
pub mut:
	hash       string // blake192 hash of content
	fsid       []u32 //list of fs ids where this blob is used
	blobid	 u32   // id of the blob	
}

pub struct DBFsBlobMembership {
pub mut:
	db &db.DB @[skip; str: skip]
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
	hash string @[required]
	fsid []u32 @[required]
	blobid u32 @[required]
}




// BlobList represents a simplified blob structure for listing purposes
pub struct BlobList {
pub mut:
	id   u32
	hash string
	size int
}

// list_by_hash_prefix lists blobs where hash starts with the given prefix
// Returns maximum 10000 items as BlobList entries with id, hash, and size
pub fn (mut self DBFsBlobMembership) list(prefix string) ![]BlobList {
	// Get all blob IDs and hashes
	//TODO: change don't use hgetall, this will create performance issues when there are many blobs
	all_blobs := self.db.redis.hgetall('fsblob:hashes')!//TODO: change using keys (scan with prefix???)
	 
	mut result := []BlobList{}
	mut count := 0
	
	// Iterate through all blobs to find those matching the prefix
	for hash, id_str in all_blobs {
		if count >= 10000 {
			break
		}
		
		if hash.starts_with(prefix) {
			// Get the full blob to retrieve its size
			blob := self.get(id_str.u32())!
			result << BlobList{
				id:   id_str.u32()
				hash: hash
				size: blob.size_bytes
			}
			count++
		}
	}
	
	return result
}
