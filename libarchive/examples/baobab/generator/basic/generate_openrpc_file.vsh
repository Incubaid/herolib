#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.baobab.generator
import freeflowuniverse.herolib.baobab.specification
import freeflowuniverse.herolib.schemas.openrpc
import os

const example_dir = os.dir(@FILE)
const openrpc_spec_path = os.join_path(example_dir, 'openrpc.json')

// the actor specification obtained from the OpenRPC Specification
openrpc_spec_ := openrpc.new(path: openrpc_spec_path)!
actor_spec := specification.from_openrpc(openrpc_spec_)!
openrpc_spec := actor_spec.to_openrpc()

openrpc_file := generator.generate_openrpc_file(openrpc_spec)!
openrpc_file.write(os.join_path(example_dir, 'docs'),
	overwrite: true
)!
