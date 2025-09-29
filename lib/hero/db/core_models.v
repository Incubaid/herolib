module db

pub struct Base {
pub mut:
	id             u32
	name           string
	description    string
	created_at     i64
	updated_at     i64
	securitypolicy u32
	tags           u32 // when we set/get we always do as []string but this can then be sorted and md5ed this gies the unique id of tags
	messages       []u32
}

@[heap]
pub struct SecurityPolicy {
pub mut:
	id     u32
	read   []u32 // links to users & groups
	write  []u32 // links to users & groups
	delete []u32 // links to users & groups
	public bool
	md5    string // this sorts read, write and delete u32 + hash, then do md5 hash, this allows to go from a random read/write/delete/public config to a hash
}

@[heap]
pub struct Tags {
pub mut:
	id    u32
	names []string // unique per id
	md5   string   // of sorted names, to make easy to find unique id, each name lowercased and made ascii
}
