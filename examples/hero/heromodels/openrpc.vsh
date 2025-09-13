#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import json
import freeflowuniverse.herolib.hero.heromodels.openrpc
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.hero.heromodels

fn main() {
	mut handler := openrpc.new_heromodels_handler()!

	my_calendar := heromodels.calendar_new(
		name:           'My Calendar'
		description:    'My Calendar'
		securitypolicy: 1
		tags:           ['tag1', 'tag2']
		group_id:       1
		events:         []u32{}
		color:          '#000000'
		timezone:       'UTC'
		is_public:      true
	)!

	response := handler.handle(jsonrpc.new_request('calendar_set', json.encode(my_calendar)))!
	println(response)
}
