module streamer

import freeflowuniverse.herolib.clients.mycelium
import freeflowuniverse.herolib.data.ourdb
import encoding.base64
import json
import time

// Maximum number of workers allowed
const max_workers = 10

// Streamer represents the entire network, including master and workers
pub struct Streamer {
pub mut:
	name             string = 'streamer'
	port             int    = 8080
	master           StreamerNode
	incremental_mode bool = true // Incremental mode for database
	reset            bool = true // Reset database
}

// NewStreamerParams defines parameters for creating a new streamer
@[params]
pub struct NewStreamerParams {
pub mut:
	name             string = 'streamer'
	port             int    = 8080
	incremental_mode bool   = true // Incremental mode for database
	reset            bool   = true // Reset database
}

// Creates a new streamer instance
pub fn new_streamer(params NewStreamerParams) !Streamer {
	log_event(
		event_type: 'logs'
		message:    'Creating new streamer'
	)

	mut db := new_db(
		incremental_mode: params.incremental_mode
		reset:            params.reset
	)!

	master := StreamerNode{
		db: db
	}

	return Streamer{
		name:             params.name
		port:             params.port
		master:           master
		incremental_mode: params.incremental_mode
		reset:            params.reset
	}
}

@[params]
struct NewMyCeliumClientParams {
	port int    = 8080              // HTTP server port
	name string = 'streamer_client' // Mycelium client name
}

fn new_mycelium_client(params NewMyCeliumClientParams) !&mycelium.Mycelium {
	mut mycelium_client := mycelium.get()!
	mycelium_client.server_url = 'http://localhost:${params.port}'
	mycelium_client.name = params.name
	return mycelium_client
}

@[params]
struct DBClientParams {
	db_dir           string = '/tmp/ourdb' // Database directory
	reset            bool   = true         // Reset database
	incremental_mode bool   = true         // Incremental mode for database
	record_size_max  u32    = 1024         // Maximum record size
	record_nr_max    u32    = 16777216 - 1 // Maximum number of records
}

fn new_db(params DBClientParams) !&ourdb.OurDB {
	mut db := ourdb.new(
		record_nr_max:    params.record_nr_max
		record_size_max:  params.record_size_max
		path:             params.db_dir
		reset:            params.reset
		incremental_mode: params.incremental_mode
	)!
	return &db
}

// ConnectStreamerParams defines parameters for connecting to an existing streamer
@[params]
pub struct ConnectStreamerParams {
pub mut:
	master_public_key string @[required] // Public key of the master node
	port              int    = 8080       // HTTP server port
	name              string = 'streamer' // Mycelium client name
}

// Connects to an existing streamer master node; intended for worker nodes
pub fn connect_streamer(params ConnectStreamerParams) !Streamer {
	log_event(
		event_type: 'info'
		message:    'Connecting to streamer'
	)

	mut streamer_ := new_streamer(
		port: params.port
		name: params.name
	)!

	// To fo this, we need to let the user send te node IP to ping it.
	// // Setting the master address to just ping the node
	// streamer_.master = StreamerNode{
	// 	address: params.master_public_key
	// }

	// if !streamer_.master.is_running() {
	// 	return error('Master node is not running')
	// }

	// 1. Get the master node | Done
	// 2. Keep listening until we receive replay from the master node | Done
	// 3. Sync the master workers | Done
	// 4. Push to the network that a new visitor has joined | Done
	// 5. Sync the master DB InProgress...

	mut mycelium_client := new_mycelium_client(
		port: params.port
		name: params.name
	)!

	// 1. Push an event to the running network to get the master
	mycelium_client.send_msg(
		topic:      'master_sync'
		payload:    params.master_public_key
		public_key: params.master_public_key
	)!

	mut encoded_master := ''

	// 2. Keep listening until we receive replay from the master node
	mut retries := 0
	for {
		time.sleep(2 * time.second)
		log_event(
			event_type: 'info'
			message:    'Waiting for master sync replay'
		)

		encoded_master = handle_master_sync_replay(mut mycelium_client) or { '' }
		if encoded_master.len > 0 {
			log_event(
				event_type: 'info'
				message:    'Got master sync replay'
			)

			encoded_master = encoded_master
			break
		}

		if retries > 10 {
			log_event(
				event_type: 'error'
				message:    'Failed to connect to master node'
			)
			return error('Failed to connect to master node')
		}
		retries++
	}

	// 3. Sync the master DB
	master_to_json := base64.decode(encoded_master).bytestr()
	master := json.decode(StreamerNode, master_to_json) or {
		return error('Failed to decode master node: ${err}')
	}

	println('MasterDB is: ${master.db}')

	streamer_.master = master

	return streamer_
}

// StreamerNodeParams defines parameters for creating a new master or worker node
@[params]
pub struct StreamerNodeParams {
pub mut:
	public_key       string @[required] // Node public key
	address          string @[required] // Node address
	db_dir           string = '/tmp/ourdb'    // Database directory
	incremental_mode bool   = true            // Incremental mode for database
	reset            bool   = true            // Reset database
	name             string = 'streamer_node' // Node/Mycelium name
	port             int    = 8080            // HTTP server port
	master           bool // Flag indicating if this is a master node
}

// Creates a new master node
fn (self Streamer) new_node(params StreamerNodeParams) !StreamerNode {
	mut client := new_mycelium_client(name: params.name, port: params.port)!
	mut db := new_db(
		db_dir:           params.db_dir
		incremental_mode: params.incremental_mode
		reset:            params.reset
	)!

	return StreamerNode{
		address:           params.address
		public_key:        params.public_key
		mycelium_client:   client
		db:                db
		is_master:         params.master
		master_public_key: params.public_key
	}
}

// Adds a master node to the streamer
pub fn (mut self Streamer) add_master(params StreamerNodeParams) !StreamerNode {
	if self.master.public_key.len != 0 {
		return error('Streamer already has a master node!')
	}

	mut params_ := params
	params_.master = true

	new_master := self.new_node(params_)!
	self.master = new_master
	return self.master
}

// Connects to an existing streamer master node; intended for worker nodes
pub fn (mut self Streamer) add_worker(params StreamerNodeParams) !StreamerNode {
	if params.master {
		return error('Worker nodes cannot be master nodes')
	}

	if self.master.public_key.len == 0 {
		return error('Streamer has no master node')
	}

	if self.master.workers.len >= max_workers {
		return error('Maximum worker limit reached')
	}

	mut worker_node := self.new_node(params)!

	if !(worker_node.is_running() or { false }) {
		return error('Worker node is not running')
	}

	self.master.workers << worker_node
	worker_node.master_public_key = self.master.public_key
	worker_node.connect_to_master()!
	return worker_node
}

// Gets the master node
pub fn (self Streamer) get_master() StreamerNode {
	return self.master
}

// Get master worker nodes
pub fn (self Streamer) get_workers() ![]StreamerNode {
	if self.master.public_key.len == 0 {
		return error('Streamer has no master node')
	}

	return self.master.workers
}

@[params]
pub struct GetWorkerParams {
pub mut:
	public_key string @[required] // Public key of the worker node
}

// Get worker node
pub fn (self Streamer) get_worker(params GetWorkerParams) !StreamerNode {
	if !self.master.is_master {
		return self.master
	}

	// Find the worker node
	for worker in self.master.workers {
		if params.public_key == worker.public_key {
			return worker
		}
	}

	return error('Worker with public key ${params.public_key} not found')
}
