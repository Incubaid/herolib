module client

import incubaid.herolib.core.base

@[params]
pub struct DocTreeClientArgs {
pub:
	export_dir string @[required] // Path to doctree export directory
}

// Create a new DocTreeClient instance
// The export_dir should point to the directory containing content/ and meta/ subdirectories
pub fn new(args DocTreeClientArgs) !&DocTreeClient {
	mut context := base.context()!
	mut redis := context.redis()!

	return &DocTreeClient{
		redis:      redis
		export_dir: args.export_dir
	}
}
