module client

import incubaid.herolib.core.redisclient

// AtlasClient provides access to Atlas-exported documentation collections
// It reads from both the exported directory structure and Redis metadata
pub struct AtlasClient {
	AtlasError // Embedded error handler for generating standardized errors
pub mut:
	redis      &redisclient.Redis
	export_dir string // Path to the atlas export directory (contains content/ and meta/)
}
