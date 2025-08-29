#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.baobab.specification
import freeflowuniverse.herolib.schemas.openapi
import os

const example_dir = os.dir(@FILE)
const openapi_spec_path = os.join_path(example_dir, 'openapi.json')

// the actor specification obtained from the OpenRPC Specification
openapi_spec := openapi.new(path: openapi_spec_path)!
actor_specification := specification.from_openapi(openapi_spec)!
println(actor_specification)
