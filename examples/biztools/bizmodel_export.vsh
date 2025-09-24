#!/usr/bin/env -S v -n -w -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.biz.bizmodel
import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.core.playcmds
import os

heroscript_path := os.join_path(os.dir(@FILE), 'examples/complete.heroscript')

// Create a new playbook with the heroscript path
mut pb := playbook.new(path: heroscript_path)!

// Play the bizmodel actions
bizmodel.play(mut pb)!

// Get the bizmodel and print it
mut bm := bizmodel.get('threefold')!
bm.sheet.pprint(nr_columns: 10)!

// Export the business model to a report
bm.export(
	name:  'example_report'
	title: 'Example Business Model'
	path:  '/tmp/bizmodel_export'
)!
