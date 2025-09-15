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

