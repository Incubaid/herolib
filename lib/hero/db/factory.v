module db

import freeflowuniverse.herolib.core.redisclient

// Current time
// import freeflowuniverse.herolib.data.encoder

pub struct DB {
pub mut:
	redis &redisclient.Redis @[skip; str: skip]
}

pub fn new() !DB {
	mut redisconnection := redisclient.core_get()!
	return DB{
		redis: redisconnection
	}
}
