module doctreeclient

import incubaid.herolib.core.redisclient

// Combined config structure
pub struct DocTreeClient {
pub mut:
	redis &redisclient.Redis
}
