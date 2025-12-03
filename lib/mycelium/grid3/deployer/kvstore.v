module deployer

import incubaid.herolib.core.base

// Will be changed when we support the logic of the TFChain one
pub struct KVStoreFS {}

fn (kvs KVStoreFS) set(key string, data []u8) ! {
	// set in context
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('deployer:deployments', key, data.bytestr())!
}

fn (kvs KVStoreFS) get(key string) ![]u8 {
	mut context := base.context()!
	mut r := context.redis()!
	value := r.hget('deployer:deployments', key)!
	if value.len == 0 {
		return error('The value is empty.')
	}

	return value.bytes()
}

fn (kvs KVStoreFS) delete(key string) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('deployer:deployments', key)!
}
