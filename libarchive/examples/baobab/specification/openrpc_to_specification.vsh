#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.baobab.specification
import freeflowuniverse.herolib.schemas.openrpc
import os

const example_dir = os.dir(@FILE)
const openrpc_spec_path = os.join_path(example_dir, 'openrpc.json')

// the actor specification obtained from the OpenRPC Specification
openrpc_spec := openrpc.new(path: openrpc_spec_path)!
actor_specification := specification.from_openrpc(openrpc_spec)!
println(actor_specification)
