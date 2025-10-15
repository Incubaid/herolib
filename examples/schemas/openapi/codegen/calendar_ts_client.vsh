#!/usr/bin/env -S v -n -w -enable-globals run

// Calendar Typescript Client Generation Example
// This example demonstrates how to generate a typescript client
// from a given OpenAPI Specification using the `openapi/codegen` module.
import os
import incubaid.herolib.schemas.openapi
import incubaid.herolib.schemas.openapi.codegen

const dir = os.dir(@FILE)
const specification = openapi.new(path: '${dir}/meeting_api.json') or {
	panic('this should never happen ${err}')
}

// generate typescript client folder and write it in dir
codegen.ts_client_folder(specification)!.write(dir, overwrite: true)!
