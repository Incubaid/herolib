module main

import incubaid.herolib.data.ourdb_syncer.streamer

fn main() {
	master_public_key := '570c1069736786f06c4fd2a6dc6c17cd88347604593b60e34b5688c369fa1b39'

	// Create a new streamer
	mut streamer_ := streamer.connect_streamer(
		name:              'streamer'
		port:              8080
		master_public_key: master_public_key
	)!

	workers := streamer_.get_workers()!

	println('workers: ${workers}')
}
