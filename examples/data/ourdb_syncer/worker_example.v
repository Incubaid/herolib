module main

import incubaid.herolib.data.ourdb_syncer.streamer

fn main() {
	// Create a new streamer
	mut streamer_ := streamer.connect_streamer(
		name:              'streamer'
		port:              8080
		master_public_key: '570c1069736786f06c4fd2a6dc6c17cd88347604593b60e34b5688c369fa1b39'
	)!

	mut worker_node := streamer_.add_worker(
		public_key: '46a9f9cee1ce98ef7478f3dea759589bbf6da9156533e63fed9f233640ac072c'
		address:    '4ff:3da9:f2b2:4103:fa6e:7ea:7cbe:8fef'
	)!

	worker_node.start_and_listen()!
}
