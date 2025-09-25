import json
import os

def to_snake_case(name):
    import re
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

def ts_type(v_type):
    if v_type in ['string']:
        return 'string'
    if v_type in ['int', 'integer', 'u32', 'u64', 'i64', 'f32', 'f64']:
        return 'number'
    if v_type in ['bool', 'boolean']:
        return 'boolean'
    if v_type.startswith('[]'):
        return ts_type(v_type[2:]) + '[]'
    if v_type == 'array':
        return 'any[]'
    return v_type

def generate_interface(schema_name, schema):
    content = f'export interface {schema_name} {{\n'
    if 'properties' in schema:
        for prop_name, prop_schema in schema.get('properties', {}).items():
            prop_type = ts_type(prop_schema.get('type', 'any'))
            if '$ref' in prop_schema:
                prop_type = prop_schema['$ref'].split('/')[-1]
            required = '?' if prop_name not in schema.get('required', []) else ''
            content += f'  {prop_name}{required}: {prop_type};\n'
    if schema.get('allOf'):
        for item in schema['allOf']:
            if '$ref' in item:
                ref_name = item['$ref'].split('/')[-1]
                content += f'  // Properties from {ref_name} are inherited\n'


    content += '}\n'
    return content

def generate_client(spec):
    methods_str = ''
    for method in spec['methods']:
        params = []
        if 'params' in method:
            for param in method['params']:
                param_type = 'any'
                if 'schema' in param:
                    if '$ref' in param['schema']:
                        param_type = param['schema']['$ref'].split('/')[-1]
                    else:
                        param_type = ts_type(param['schema'].get('type', 'any'))

                params.append(f"{param['name']}: {param_type}")
        
        params_str = ', '.join(params)

        result_type = 'any'
        if 'result' in method and 'schema' in method['result']:
             if '$ref' in method['result']['schema']:
                result_type = method['result']['schema']['$ref'].split('/')[-1]
             else:
                result_type = ts_type(method['result']['schema'].get('type', 'any'))

        method_name_snake = to_snake_case(method['name'])

        methods_str += f"""
    async {method_name_snake}(params: {{ {params_str} }}): Promise<{result_type}> {{
        return this.send('{method['name']}', params);
    }}
"""

    schemas = spec.get('components', {}).get('schemas', {})
    imports_str = '\n'.join([f"import {{ {name} }} from './{name}';" for name in schemas.keys()])

    base_url = 'http://localhost:8086/api/heromodels'
    client_class = f"""
import fetch from 'node-fetch';

{imports_str}

export class HeroModelsClient {{
    private baseUrl: string;

    constructor(baseUrl: string = '{base_url}') {{
        this.baseUrl = baseUrl;
    }}

    private async send<T>(method: string, params: any): Promise<T> {{
        const response = await fetch(this.baseUrl, {{
            method: 'POST',
            headers: {{
                'Content-Type': 'application/json',
            }},
            body: JSON.stringify({{
                jsonrpc: '2.0',
                method: method,
                params: params,
                id: 1,
            }}),
        }});

        if (!response.ok) {{
            throw new Error(`HTTP error! status: ${{response.status}}`);
        }}

        const jsonResponse:any = await response.json();
        if (jsonResponse.error) {{
            throw new Error(`RPC error: ${{jsonResponse.error.message}}`);
        }}

        return jsonResponse.result;
    }}
{methods_str}
}}
"""
    return client_class

def main():
    script_dir = os.path.dirname(__file__)
    openrpc_path = os.path.abspath(os.path.join(script_dir, '..', '..', 'hero', 'heromodels', 'openrpc.json'))
    output_dir = os.path.join(script_dir, 'generated_ts_client')

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    with open(openrpc_path, 'r') as f:
        spec = json.load(f)

    schemas = spec.get('components', {}).get('schemas', {})
    for name, schema in schemas.items():
        interface_content = generate_interface(name, schema)
        with open(os.path.join(output_dir, f'{name}.ts'), 'w') as f:
            f.write(interface_content)

    client_content = generate_client(spec)
    with open(os.path.join(output_dir, 'client.ts'), 'w') as f:
        f.write(client_content)
    
    print(f"TypeScript client generated successfully in {output_dir}")

if __name__ == '__main__':
    main()