module main

import incubaid.herolib.data.ourdb_syncer.streamer

fn main() {
	println('Strating the streamer first!')

	// Create a new streamer
	mut streamer_ := streamer.new_streamer(
		name: 'streamer'
		port: 8080
	)!

	mut master_node := streamer_.add_master(
		address:    '4ff:3da9:f2b2:4103:fa6e:7ea:7cbe:8fef'
		public_key: '570c1069736786f06c4fd2a6dc6c17cd88347604593b60e34b5688c369fa1b39'
	)!

	master_node.start_and_listen()!
}
