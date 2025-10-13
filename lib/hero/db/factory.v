module db

import incubaid.herolib.core.redisclient

// Current time
// import incubaid.herolib.data.encoder

pub struct DB {
pub mut:
	redis &redisclient.Redis @[skip; str: skip]
}

@[params]
pub struct DBArgs {
pub mut:
	redis ?&redisclient.Redis
}

pub fn new(args DBArgs) !DB {
	mut redisconnection := args.redis or { redisclient.core_get()! }
	return DB{
		redis: redisconnection
	}
}

pub fn new_test() !DB {
	mut redisconnection := redisclient.test_get()!
	return DB{
		redis: redisconnection
	}
}
