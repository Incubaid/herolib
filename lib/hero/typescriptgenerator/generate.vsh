#!/usr/bin/env -S v -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.hero.typescriptgenerator
import incubaid.herolib.schemas.openrpc
import os

const openrpc_path = os.dir(@FILE) + '/../../hero/heromodels/openrpc.json'
const output_dir = os.expand_tilde_to_home('~/code/heromodels/generated')

fn main() {
	spec_text := os.read_file(openrpc_path) or {
		eprintln('Failed to read openrpc.json: ${err}')
		return
	}

	openrpc_spec := openrpc.decode(spec_text) or {
		eprintln('Failed to decode openrpc spec: ${err}')
		return
	}

	config := typescriptgenerator.IntermediateConfig{
		base_url:     'http://localhost:8086/api/heromodels'
		handler_type: 'heromodels'
	}

	intermediate_spec := typescriptgenerator.from_openrpc(openrpc_spec, config) or {
		eprintln('Failed to create intermediate spec: ${err}')
		return
	}

	typescriptgenerator.generate_typescript_client(intermediate_spec, output_dir) or {
		eprintln('Failed to generate typescript client: ${err}')
		return
	}

	println('TypeScript client generated successfully in ${output_dir}')
}
