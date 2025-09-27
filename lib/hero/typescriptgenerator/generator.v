module typescriptgenerator

import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.core.texttools
import os

pub fn generate_typescript_client(spec IntermediateSpec, dest_path string) ! {
	mut dest := pathlib.get_dir(path: dest_path, create: true)!
	
	// Generate a file for each schema
	for name, schema in spec.schemas {
		mut file_content := generate_interface(schema)
		mut file_path := pathlib.get_file(path: '${dest.path}/${name}.ts', create: true)!
		file_path.write(file_content) or { panic(err) }
	}

	// Generate the main client file
	mut client_content := generate_client(spec)
	mut client_file_path := pathlib.get_file(path: '${dest.path}/client.ts', create: true)!
	client_file_path.write(client_content) or { panic(err) }
	
	// Copy templates to destination
	mut templates_src := os.dir(@FILE) + '/templates'
	if os.exists(templates_src) {
		// Copy index.html template
		mut index_content := os.read_file('${templates_src}/index.html')!
		mut index_file := pathlib.get_file(path: '${dest.path}/index.html', create: true)!
		index_file.write(index_content)!
		
		// Copy package.json template
		mut package_content := os.read_file('${templates_src}/package.json')!
		mut package_file := pathlib.get_file(path: '${dest.path}/package.json', create: true)!
		package_file.write(package_content)!
		
		// Copy tsconfig.json template
		mut tsconfig_content := os.read_file('${templates_src}/tsconfig.json')!
		mut tsconfig_file := pathlib.get_file(path: '${dest.path}/tsconfig.json', create: true)!
		tsconfig_file.write(tsconfig_content)!
		
		// Copy dev-server.ts template
		mut dev_server_content := os.read_file('${templates_src}/dev-server.ts')!
		mut dev_server_file := pathlib.get_file(path: '${dest.path}/dev-server.ts', create: true)!
		dev_server_file.write(dev_server_content)!
	}
}

fn generate_interface(schema IntermediateSchema) string {
	mut content := 'export interface ${schema.name} {\n'
	for prop in schema.properties {
		content += '  ${prop.name}${if prop.required { '' } else { '?' }}: ${ts_type(prop.type_info)};\n'
	}
	content += '}\n'
	return content
}

fn generate_client(spec IntermediateSpec) string {
    mut methods_str := ''
    for method in spec.methods {
        params_str := method.params.map('${it.name}: ${ts_type(it.type_info)}').join(', ')
        methods_str += '
    async ${texttools.snake_case(method.name)}(params: { ${params_str} }): Promise<${ts_type(method.result.type_info)}> {
        return this.send(\'${method.name}\', params);
    }
'
    }

    mut imports_str := ''
    for schema_name in spec.schemas.keys() {
        imports_str += "import { ${schema_name} } from './${schema_name}';\n"
    }

	return "
import fetch from 'node-fetch';

${imports_str}

export class HeroModelsClient {
    private baseUrl: string;

    constructor(baseUrl: string = '${spec.base_url}') {
        this.baseUrl = baseUrl;
    }

    private async send<T>(method: string, params: any): Promise<T> {
        const response = await fetch(this.baseUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                jsonrpc: '2.0',
                method: method,
                params: params,
                id: 1,
            }),
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${"$"}{response.status}`);
        }

        const jsonResponse:any = await response.json();
        if (jsonResponse.error) {
            throw new Error(`RPC error: ${"$"}{jsonResponse.error.message}`);
        }

        return jsonResponse.result;
    }
${methods_str}
}
"
}


fn ts_type(v_type string) string {
	return match v_type {
		'string' { 'string' }
		'int', 'integer', 'u32', 'u64', 'i64' { 'number' }
		'bool', 'boolean' { 'boolean' }
		'f32', 'f64' { 'number' }
		'[]string' { 'string[]' }
		'[]int' { 'number[]' }
        'array' { 'any[]' }
        else { v_type }
	}
}