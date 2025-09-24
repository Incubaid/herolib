#!/usr/bin/env -S v -n -w -gc none  -cg -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.web.ui

fn main() {
	println('Starting UI test server on port 8080...')
	println('Visit http://localhost:8080 to see the admin interface')

	ui.start(
		title: 'Test Admin Panel'
		port:  8080
	)!
}
