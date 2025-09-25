module typescriptgenerator

import freeflowuniverse.herolib.schemas.openrpc
import os

const openrpc_path = os.dir(@FILE) + '/../../heromodels/openrpc.json'
const output_dir = os.dir(@FILE) + '/test_generated_ts_client'


fn test_generate_typescript_client() {
    spec_text := os.read_file(openrpc_path) or {
        eprintln('Failed to read openrpc.json: ${err}')
        return
    }

    openrpc_spec := openrpc.decode(spec_text) or {
        eprintln('Failed to decode openrpc spec: ${err}')
        return
    }

    config := IntermediateConfig{
        base_url: 'http://localhost:8086/api/heromodels'
    }

    intermediate_spec := from_openrpc(openrpc_spec, config) or {
        eprintln('Failed to create intermediate spec: ${err}')
        return
    }

    generate_typescript_client(intermediate_spec, output_dir) or {
        eprintln('Failed to generate typescript client: ${err}')
        return
    }
    
    println("TypeScript client generated successfully in ${output_dir}")
}