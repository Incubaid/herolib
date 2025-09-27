// Update struct:
@[heap]
pub struct FsBlob {
	db.Base
pub mut:
	hash       string // blake192 hash of content
	data       []u8   // Binary data (max 1MB)
	size_bytes int    // Size in bytes
}

// Update DBFsBlob struct:
pub struct DBFsBlob {
pub mut:
	db      &db.DB     @[skip; str: skip]
	factory &ModelsFactory = unsafe { nil } @[skip; str: skip]
}

// Add these methods:
pub fn (self FsBlob) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a blob. Returns the ID of the blob.'
		}
		'get' {
			return 'Retrieve a blob by ID. Returns the blob object.'
		}
		'delete' {
			return 'Delete a blob by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a blob exists by ID. Returns true or false.'
		}
		'get_by_hash' {
			return 'Retrieve a blob by hash. Returns the blob object.'
		}
		else {
			return 'This is generic method for the blob object.'
		}
	}
}

pub fn (self FsBlob) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"blob": {"data": "SGVsbG8gV29ybGQ="}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"hash": "abc123...", "data": "SGVsbG8gV29ybGQ=", "size_bytes": 11}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'get_by_hash' {
			return '{"hash": "abc123..."}', '{"hash": "abc123...", "data": "SGVsbG8gV29ybGQ=", "size_bytes": 11}'
		}
		else {
			return '{}', '{}'
		}
	}
}

// Add RPC handler function at the end:
pub fn fs_blob_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.fs_blob.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut o := db.decode_generic[FsBlob](params)!
			o = f.fs_blob.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			f.fs_blob.delete(id)!
			return new_response_ok(rpcid)
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.fs_blob.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'get_by_hash' {
			hash := db.decode_string(params)!
			res := f.fs_blob.get_by_hash(hash)!
			return new_response(rpcid, json.encode(res))
		}
		else {
			console.print_stderr('Method not found on fs_blob: ${method}')
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on fs_blob'
			)
		}
	}
}