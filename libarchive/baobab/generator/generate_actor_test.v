module generator

import freeflowuniverse.herolib.core.code
import freeflowuniverse.herolib.baobab.specification
import freeflowuniverse.herolib.schemas.openrpc
import freeflowuniverse.herolib.schemas.jsonschema
import os
import x.json2 as json

const actor_spec = specification.ActorSpecification{
	name:        'Pet Store'
	description: 'A sample API for a pet store'
	structure:   code.Struct{}
	interfaces:  [.openapi]
	methods:     [
		specification.ActorMethod{
			name:       'listPets'
			summary:    'List all pets'
			example:    openrpc.ExamplePairing{
				params: [
					openrpc.ExampleRef(openrpc.Example{
						name:        'Example limit'
						description: 'Example Maximum number of pets to return'
						value:       10
					}),
				]
				result: openrpc.ExampleRef(openrpc.Example{
					name:  'Example response'
					value: json.raw_decode('[
                        {"id": 1, "name": "Fluffy", "tag": "dog"},
                        {"id": 2, "name": "Whiskers", "tag": "cat"}
                    ]')!
				})
			}
			parameters: [
				openrpc.ContentDescriptor{
					name:        'limit'
					summary:     'Maximum number of pets to return'
					description: 'Maximum number of pets to return'
					required:    false
					schema:      jsonschema.SchemaRef(jsonschema.Schema{
						...jsonschema.schema_u32
						example: 10
					})
				},
			]
			result:     openrpc.ContentDescriptor{
				name:        'pets'
				description: 'A paged array of pets'
				schema:      jsonschema.SchemaRef(jsonschema.Schema{
					typ:   'array'
					items: jsonschema.Items(jsonschema.SchemaRef(jsonschema.Schema{
						id:         'pet'
						title:      'Pet'
						typ:        'object'
						properties: {
							'id':   jsonschema.SchemaRef(jsonschema.Reference{
								ref: '#/components/schemas/PetId'
							})
							'name': jsonschema.SchemaRef(jsonschema.Schema{
								typ: 'string'
							})
							'tag':  jsonschema.SchemaRef(jsonschema.Schema{
								typ: 'string'
							})
						}
						required:   [
							'id',
							'name',
						]
					}))
				})
			}
			errors:     [
				openrpc.ErrorSpec{
					code:    400
					message: 'Invalid request'
				},
			]
		},
		specification.ActorMethod{
			name:       'newPet'
			summary:    'Create a new pet'
			parameters: [
				openrpc.ContentDescriptor{
					name:        'result'
					description: 'The response of the operation.'
					required:    true
					schema:      jsonschema.SchemaRef(jsonschema.Schema{
						id:         'pet'
						title:      'Pet'
						typ:        'object'
						properties: {
							'id':   jsonschema.SchemaRef(jsonschema.Reference{
								ref: '#/components/schemas/PetId'
							})
							'name': jsonschema.SchemaRef(jsonschema.Schema{
								typ: 'string'
							})
							'tag':  jsonschema.SchemaRef(jsonschema.Schema{
								typ: 'string'
							})
						}
						required:   ['id', 'name']
					})
				},
			]
			example:    openrpc.ExamplePairing{
				result: openrpc.ExampleRef(openrpc.Example{
					name:  'Example response'
					value: '[]'
				})
			}
			result:     openrpc.ContentDescriptor{
				name:        'petId'
				summary:     'ID of the created pet'
				description: 'ID of the created pet'
				required:    true
				schema:      jsonschema.SchemaRef(jsonschema.Schema{
					...jsonschema.schema_u32
					example: 1
				})
			}
			errors:     [
				openrpc.ErrorSpec{
					code:    400
					message: 'Invalid input'
				},
			]
		},
		specification.ActorMethod{
			name:       'getPet'
			summary:    'Get a pet by ID'
			example:    openrpc.ExamplePairing{
				params: [
					openrpc.ExampleRef(openrpc.Example{
						name:        'Example petId'
						description: 'Example ID of the pet to retrieve'
						value:       1
					}),
				]
				result: openrpc.ExampleRef(openrpc.Example{
					name:  'Example response'
					value: json.raw_decode('{"id": 1, "name": "Fluffy", "tag": "dog"}')!
				})
			}
			parameters: [
				openrpc.ContentDescriptor{
					name:        'petId'
					summary:     'ID of the pet to retrieve'
					description: 'ID of the pet to retrieve'
					required:    true
					schema:      jsonschema.SchemaRef(jsonschema.Schema{
						...jsonschema.schema_u32
						format:  'uint32'
						example: 1
					})
				},
			]
			result:     openrpc.ContentDescriptor{
				name:        'result'
				description: 'The response of the operation.'
				required:    true
				schema:      jsonschema.SchemaRef(jsonschema.Reference{
					ref: '#/components/schemas/Pet'
				})
			}
			errors:     [
				openrpc.ErrorSpec{
					code:    404
					message: 'Pet not found'
				},
			]
		},
		specification.ActorMethod{
			name:       'deletePet'
			summary:    'Delete a pet by ID'
			example:    openrpc.ExamplePairing{
				params: [
					openrpc.ExampleRef(openrpc.Example{
						name:        'Example petId'
						description: 'Example ID of the pet to delete'
						value:       1
					}),
				]
			}
			parameters: [
				openrpc.ContentDescriptor{
					name:        'petId'
					summary:     'ID of the pet to delete'
					description: 'ID of the pet to delete'
					required:    true
					schema:      jsonschema.SchemaRef(jsonschema.Schema{
						...jsonschema.schema_u32
						example: 1
					})
				},
			]
			result:     openrpc.ContentDescriptor{
				name:        'result'
				description: 'The response of the operation.'
				required:    true
			}
			errors:     [
				openrpc.ErrorSpec{
					code:    404
					message: 'Pet not found'
				},
			]
		},
	]
	objects:     [
		specification.BaseObject{
			schema: jsonschema.Schema{
				title:      'Pet'
				typ:        'object'
				properties: {
					'id':   jsonschema.schema_u32
					'name': jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'string'
					})
					'tag':  jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'string'
					})
				}
				required:   ['id', 'name']
			}
		},
	]
}

const destination = '${os.dir(@FILE)}/testdata'

fn test_generate_plain_actor_module() {
	// plain actor module without interfaces
	actor_module := generate_actor_module(actor_spec)!
	actor_module.write(destination,
		format:    true
		overwrite: true
		test:      true
	)!
}

fn test_generate_actor_module_with_openrpc_interface() {
	// plain actor module without interfaces
	actor_module := generate_actor_module(actor_spec, interfaces: [.openrpc])!
	actor_module.write(destination,
		format:    true
		overwrite: true
		test:      true
	)!
}

fn test_generate_actor_module_with_openapi_interface() {
	// plain actor module without interfaces
	actor_module := generate_actor_module(actor_spec,
		interfaces: [.openapi]
	)!
	actor_module.write(destination,
		format:    true
		overwrite: true
		test:      true
	)!
}

fn test_generate_actor_module_with_all_interfaces() {
	// plain actor module without interfaces
	actor_module := generate_actor_module(actor_spec,
		interfaces: [.openapi, .openrpc, .http]
	)!
	actor_module.write(destination,
		format:    true
		overwrite: true
		test:      true
	)!
}
