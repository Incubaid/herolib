module deployer

import incubaid.herolib.core.base as context
import incubaid.herolib.core

// Will be changed when we support the logic of the TFChain one
pub struct KVStoreFS {}

fn (kvs KVStoreFS) set(key string, data []u8) ! {
	// set in context
	core.memdb_set(key, data.bytestr())
}

fn (kvs KVStoreFS) get(key string) ![]u8 {
	value := core.memdb_get(key)
	if value.len == 0 {
		return error('The value is empty.')
	}

	return value.bytes()
}

fn (kvs KVStoreFS) delete(key string) ! {
	// clearing the entry is sufficient for current usage
	core.memdb_set(key, '')
}
