module doctreeclient

import incubaid.herolib.core.base

pub fn new() !&DocTreeClient {
	mut context := base.context()!
	mut redis := context.redis()!

	return &DocTreeClient{
		redis: redis
	}
}
