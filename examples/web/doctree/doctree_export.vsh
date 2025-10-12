#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.doctree

mut tree := doctree.new(name: 'test')!

// path      string
// heal      bool = true // healing means we fix images
// git_url   string
// git_reset bool
// git_root  string
// git_pull  bool

tree.scan(
	git_url:  'https://git.threefold.info/tfgrid/docs_tfgrid4/src/branch/main/collections'
	git_pull: false
)!

tree.export(
	destination:    '/tmp/mdexport'
	reset:          true
	exclude_errors: false
)!
