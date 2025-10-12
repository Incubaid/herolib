module httpconnection

import net.http { Header }
import incubaid.herolib.core.redisclient { Redis }

@[heap]
pub struct HTTPConnection {
pub mut:
	redis          Redis @[str: skip]
	base_url       string // the base url
	default_header Header
	cache          CacheConfig
	retry          int = 5
}

// Join headers from httpconnection and Request
fn (mut h HTTPConnection) header(req Request) Header {
	mut header := req.header or { return h.default_header }

	return h.default_header.join(header)
}
