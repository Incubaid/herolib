#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import json
import freeflowuniverse.herolib.hero.heromodels.rpc
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.hero.heromodels
import time

fn main() {
	spawn fn () ! {
		println('starting server')
		rpc.start(http_port: 9090) or { panic('Failed to start RPC server: ${err}') }
	}()

	time.sleep(time.second * 3)
	println('sleeping for 3 seconds to let server start')
	// my_calendar := heromodels.calendar_new(
	// 	name:           'My Calendar'
	// 	description:    'My Calendar'
	// 	securitypolicy: 1
	// 	tags:           ['tag1', 'tag2']
	// 	group_id:       1
	// 	events:         []u32{}
	// 	color:          '#000000'
	// 	timezone:       'UTC'
	// 	is_public:      true
	// )!

	// response := handler.handle(jsonrpc.new_request('calendar_set', json.encode(my_calendar)))!
	// println(response)
}
