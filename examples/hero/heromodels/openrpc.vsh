#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import json
import freeflowuniverse.herolib.hero.heromodels.rpc
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.hero.heromodels
import time

fn main() {
	println('Starting RPC server on port 9090...')

	// Start the server in a background thread
	spawn fn () {
		rpc.start(http_port: 9090) or { panic('Failed to start RPC server: ${err}') }
	}()

	// Wait for server to start
	time.sleep(time.second * 2)
	println('Server started, now testing with some requests...')

	// Create a calendar object to test with
	mut mydb := heromodels.new()!
	mut my_calendar := mydb.calendar.new(
		color:     '#FF0000'
		timezone:  'UTC'
		is_public: true
		events:    []u32{}
	)!
	my_calendar.name = 'Test Calendar'
	my_calendar.description = 'A test calendar for RPC'

	// Test the calendar_set RPC method
	request := jsonrpc.new_request('calendar_set', json.encode(my_calendar))
	println('Sending request: ${request}')

	// TODO: Add HTTP client to actually send the request to localhost:9090
	// For now, just show what would be sent

	// Keep the server running
	println('Server is running on http://localhost:9090')
	println('You can test it with curl or other HTTP clients')
	println('Press Ctrl+C to stop the server')

	// Keep main thread alive so server continues running
	for {
		time.sleep(time.second * 10)
		println('Server still running...')
	}
}
