#!/usr/bin/env -S v -n -w -gc none  -cg -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.web.starlight
// import incubaid.herolib.data.doctree

// Create a new starlight factory
mut docs := starlight.new(
	build_path: '/tmp/starlight_build'
)!

// Create a new starlight site
mut site := docs.get(
	url:  'https://git.threefold.info/tfgrid/docs_aibox'
	init: true // init means we put config files if not there
)!

site.dev(host: 'localhost', port: 3000)!
