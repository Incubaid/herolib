#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.baobab.generator
import freeflowuniverse.herolib.baobab.specification
import freeflowuniverse.herolib.schemas.openrpc
import os

const example_dir = os.dir(@FILE)
const openrpc_spec_path = os.join_path(example_dir, 'openrpc.json')

// the actor specification obtained from the OpenRPC Specification
openrpc_spec := openrpc.new(path: openrpc_spec_path)!
actor_spec := specification.from_openrpc(openrpc_spec)!

methods_file := generator.generate_methods_file(actor_spec)!
methods_file.write(example_dir,
	format:    true
	overwrite: true
)!
