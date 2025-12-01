module client

import incubaid.herolib.core.base

@[params]
pub struct AtlasClientArgs {
pub:
	export_dir string @[required] // Path to doctree export directory
}

// Create a new AtlasClient instance
// The export_dir should point to the directory containing content/ and meta/ subdirectories
pub fn new(args AtlasClientArgs) !&AtlasClient {
	mut context := base.context()!
	mut redis := context.redis()!

	return &AtlasClient{
		redis:      redis
		export_dir: args.export_dir
	}
}
