module crypt

import freeflowuniverse.herolib.core.redisclient

// AGEClient provides access to the Age encryption features in HeroDB
pub struct AGEClient {
pub mut:
	redis &redisclient.Redis @[str: skip]
}

@[params]
pub struct AGEClientConfig {
pub mut:
	redis_url redisclient.RedisURL = redisclient.RedisURL{}
	redis     ?&redisclient.Redis
}

// new_age_client creates a new AGE encryption client
pub fn new_age_client(config AGEClientConfig) !&AGEClient {
	// If a Redis client is provided, use it
	mut redis := if r := config.redis {
		r
	} else {
		// Otherwise create a new Redis client
		redisclient.core_get(config.redis_url)!
	}

	return &AGEClient{
		redis: redis
	}
}
