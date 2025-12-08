module deployer

import incubaid.herolib.core.base

// KVStoreFS uses Redis for caching deployment state via hero context and session
pub struct KVStoreFS {}

const session_name = 'deployer'

fn get_session() !base.Session {
	mut ctx := base.context()!
	// Try to get existing session, or create new one
	session := ctx.session_get(name: session_name) or { ctx.session_new(name: session_name)! }
	return session
}

fn cache_key(session base.Session, key string) string {
	return '${session.guid()}:${key}'
}

fn (kvs KVStoreFS) set(key string, data []u8) ! {
	mut session := get_session()!
	mut redis := session.context.redis()!
	redis.set(cache_key(session, key), data.bytestr())!
}

fn (kvs KVStoreFS) get(key string) ![]u8 {
	mut session := get_session()!
	mut redis := session.context.redis()!
	value := redis.get(cache_key(session, key)) or { return error('Key "${key}" not found.') }
	if value.len == 0 {
		return error('The value is empty.')
	}
	return value.bytes()
}

fn (kvs KVStoreFS) delete(key string) ! {
	mut session := get_session()!
	mut redis := session.context.redis()!
	redis.del(cache_key(session, key))!
}
