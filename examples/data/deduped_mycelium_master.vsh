#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.ourdb
import time

// Known worker public key
worker1_public_key := '46a9f9cee1ce98ef7478f3dea759589bbf6da9156533e63fed9f233640ac072c'
// worker2_public_key := '46a9f9cee1ce98ef7478f3dea759589bbf6da9156533e63fed9f233640ac072c'

// Create master node
println('Starting master node...')
mut streamer := ourdb.new_streamer(
	incremental_mode: false
	server_port:      9000 // Master uses default port
	is_worker:        false
)!

println('Initializing workers...')
// Add workers and initialize its database
// You should run the deduped_mycelium_worker.vsh script for each worker
streamer.add_worker(worker1_public_key)!
// streamer.add_worker(worker2_public_key)!

// When we preforming a write, we get the ID of the record
// We basically write to the master database, and read from the workers normally
mut id1 := streamer.write(id: 1, value: 'Record 1')!
mut id2 := streamer.write(id: 2, value: 'Record 2')!
println('Master record 1 data: ${id1}')
println('Master record 2 data: ${id2}')

// Read data from master
master_id1 := streamer.read(id: 1)!
master_id2 := streamer.read(id: 2)!
println('Master 1 data: ${master_id1.bytestr()}')
println('Master 2 data: ${master_id2.bytestr()}')

// Read data from workers
worker_id1 := streamer.read(id: 1, worker_public_key: worker1_public_key)!
worker_id2 := streamer.read(id: 2, worker_public_key: worker1_public_key)!

println('Worker 1 data: ${worker_id1.bytestr()}')
println('Worker 2 data: ${worker_id2.bytestr()}')
