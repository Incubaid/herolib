#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.core.jobs.model
import net.websocket
import json
import rand
import time
import term

const ws_url = 'ws://localhost:8080'

// Helper function to send request and receive response
fn send_request(mut ws websocket.Client, request OpenRPCRequest) !OpenRPCResponse {
	// Send request
	request_json := json.encode(request)
	println(request_json)
	ws.write_string(request_json) or {
		eprintln(term.red('Failed to send request: ${err}'))
		return err
	}

	// Wait for response
	mut msg := ws.read_next_message() or {
		eprintln(term.red('Failed to read response: ${err}'))
		return err
	}

	if msg.opcode != websocket.OPCode.text_frame {
		return error('Invalid response type: expected text frame')
	}

	response_text := msg.payload.bytestr()

	// Parse response
	response := json.decode(OpenRPCResponse, response_text) or {
		eprintln(term.red('Failed to decode response: ${err}'))
		return err
	}
	return response
}

// OpenRPC request/response structures (copied from handler.v)
struct OpenRPCRequest {
	jsonrpc string @[required]
	method  string @[required]
	params  []string
	id      int @[required]
}

struct OpenRPCResponse {
	jsonrpc string @[required]
	result  string
	error   string
	id      int @[required]
}

// Initialize and configure WebSocket client
fn init_client() !&websocket.Client {
	mut ws := websocket.new_client(ws_url)!

	ws.on_open(fn (mut ws websocket.Client) ! {
		println(term.green('Connected to WebSocket server and ready...'))
	})

	ws.on_error(fn (mut ws websocket.Client, err string) ! {
		eprintln(term.red('WebSocket error: ${err}'))
	})

	ws.on_close(fn (mut ws websocket.Client, code int, reason string) ! {
		println(term.yellow('WebSocket connection closed: ${reason}'))
	})

	ws.on_message(fn (mut ws websocket.Client, msg &websocket.Message) ! {
		if msg.payload.len > 0 {
			println(term.blue('Received message: ${msg.payload.bytestr()}'))
		}
	})

	ws.connect() or {
		eprintln(term.red('Failed to connect: ${err}'))
		return err
	}

	spawn ws.listen()
	return ws
}

// Main client logic
mut ws := init_client()!
defer {
	ws.close(1000, 'normal') or { eprintln(term.red('Error closing connection: ${err}')) }
}
println(term.green('Connected to ${ws_url}'))

// Create a new job
println(term.blue('\nCreating new job...'))
new_job := send_request(mut ws, OpenRPCRequest{
	jsonrpc: '2.0'
	method:  'job.new'
	params:  []string{}
	id:      rand.i32_in_range(1, 10000000)!
}) or {
	eprintln(term.red('Failed to create new job: ${err}'))
	exit(1)
}
println(term.green('Created new job:'))
println(json.encode_pretty(new_job))

// Parse job from response
job := json.decode(model.Job, new_job.result) or {
	eprintln(term.red('Failed to parse job: ${err}'))
	exit(1)
}

// Set job properties
println(term.blue('\nSetting job properties...'))
mut updated_job := job
updated_job.guid = 'test-job-1'
updated_job.actor = 'vm_manager'
updated_job.action = 'start'
updated_job.params = {
	'name':   'test-vm'
	'memory': '2048'
}

// Save job
set_response := send_request(mut ws, OpenRPCRequest{
	jsonrpc: '2.0'
	method:  'job.set'
	params:  [json.encode(updated_job)]
	id:      rand.int()
}) or {
	eprintln(term.red('Failed to save job: ${err}'))
	exit(1)
}
println(term.green('Saved job:'))
println(json.encode_pretty(set_response))

// Update job status to running
println(term.blue('\nUpdating job status...'))
update_response := send_request(mut ws, OpenRPCRequest{
	jsonrpc: '2.0'
	method:  'job.update_status'
	params:  ['test-job-1', 'running']
	id:      rand.int()
}) or {
	eprintln(term.red('Failed to update job status: ${err}'))
	exit(1)
}
println(term.green('Updated job status:'))
println(json.encode_pretty(update_response))

// Get job to verify changes
println(term.blue('\nRetrieving job...'))
get_response := send_request(mut ws, OpenRPCRequest{
	jsonrpc: '2.0'
	method:  'job.get'
	params:  ['test-job-1']
	id:      rand.int()
}) or {
	eprintln(term.red('Failed to retrieve job: ${err}'))
	exit(1)
}
println(term.green('Retrieved job:'))
println(json.encode_pretty(get_response))

// List all jobs
println(term.blue('\nListing all jobs...'))
list_response := send_request(mut ws, OpenRPCRequest{
	jsonrpc: '2.0'
	method:  'job.list'
	params:  []string{}
	id:      rand.int()
}) or {
	eprintln(term.red('Failed to list jobs: ${err}'))
	exit(1)
}
println(term.green('All jobs:'))
println(json.encode_pretty(list_response))
