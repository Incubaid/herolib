module codegen

import incubaid.herolib.develop.codetools as code
import incubaid.herolib.core.texttools
import incubaid.herolib.schemas.jsonschema { Reference, Schema, SchemaRef }
import incubaid.herolib.schemas.jsonschema.codegen
import incubaid.herolib.schemas.openrpc.codegen as openrpc_codegen
import incubaid.herolib.schemas.openapi { Operation, ResponseSpec }
import incubaid.herolib.baobab.specification
import net.http

const test_operation = Operation{
	summary:      'List all pets'
	operation_id: 'listPets'
	parameters:   [
		openapi.Parameter{
			name:        'limit'
			in_:         'query'
			description: 'Maximum number of pets to return'
			required:    false
			schema:      Schema{
				typ:    'integer'
				format: 'int32'
			}
		},
	]
	responses:    {
		'200': ResponseSpec{
			description: 'A paginated list of pets'
			content:     {
				'application/json': openapi.MediaType{
					schema: Schema{
						typ:   'array'
						items: SchemaRef(Reference{
							ref: '#/components/schemas/Pet'
						})
					}
				}
			}
		}
		'400': ResponseSpec{
			description: 'Invalid request'
		}
	}
}

const test_path = '/pets'

fn test_ts_client_fn() {
	assert ts_client_fn(test_operation, test_path, .get) == 'async listPets(limit: number): Promise<Pet[]> {}'
	assert ts_client_fn(test_operation, test_path, .get,
		body_generator: body_generator
	) == 'async listPets(limit: number): Promise<Pet[]> {console.log("implement")}'
}

fn body_generator(op Operation, path string, method http.Method) string {
	return 'console.log("implement")'
}
