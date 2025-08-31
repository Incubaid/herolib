#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.baobab.generator
import freeflowuniverse.herolib.baobab.specification
import freeflowuniverse.herolib.schemas.openapi
import os

const example_dir = os.dir(@FILE)
const specs = ['merchant', 'profiler', 'farmer']

for spec in specs {
	openapi_spec_path := os.join_path(example_dir, '${spec}.json')
	openapi_spec := openapi.new(path: openapi_spec_path, process: true)!
	actor_spec := specification.from_openapi(openapi_spec)!
	actor_module := generator.generate_actor_folder(actor_spec,
		interfaces: [.openapi, .http]
	)!
	actor_module.write(example_dir,
		format:    true
		overwrite: true
		compile:   false
	)!
}
