module specification

import x.json2 as json
import freeflowuniverse.herolib.core.code { Struct }
import freeflowuniverse.herolib.schemas.openrpc { ContentDescriptor, ErrorSpec }
import freeflowuniverse.herolib.schemas.openapi { Components, Info, OpenAPI, Operation, PathItem, ServerSpec }
import freeflowuniverse.herolib.schemas.jsonschema { Reference, Schema, SchemaRef }

const openapi_spec = OpenAPI{
	openapi:    '3.0.3'
	info:       Info{
		title:       'Pet Store API'
		description: 'A sample API for a pet store'
		version:     '1.0.0'
	}
	servers:    [
		ServerSpec{
			url:         'https://api.petstore.example.com/v1'
			description: 'Production server'
		},
		ServerSpec{
			url:         'https://staging.petstore.example.com/v1'
			description: 'Staging server'
		},
	]
	paths:      {
		'/pets':         PathItem{
			get:  Operation{
				summary:      'List all pets'
				operation_id: 'listPets'
				parameters:   [
					openapi.Parameter{
						name:        'limit'
						in_:         'query'
						description: 'Maximum number of pets to return'
						required:    false
						schema:      Schema{
							typ:     'integer'
							format:  'int32'
							example: 10
						}
					},
				]
				responses:    {
					'200': openapi.ResponseSpec{
						description: 'A paginated list of pets'
						content:     {
							'application/json': openapi.MediaType{
								schema:  Reference{
									ref: '#/components/schemas/Pets'
								}
								example: json.raw_decode('[
									{ "id": 1, "name": "Fluffy", "tag": "dog" },
									{ "id": 2, "name": "Whiskers", "tag": "cat" }
								]')!
							}
						}
					}
					'400': openapi.ResponseSpec{
						description: 'Invalid request'
					}
				}
			}
			post: Operation{
				summary:      'Create a new pet'
				operation_id: 'createPet'
				request_body: openapi.RequestBody{
					required: true
					content:  {
						'application/json': openapi.MediaType{
							schema:  Reference{
								ref: '#/components/schemas/NewPet'
							}
							example: json.raw_decode('{ "name": "Bella", "tag": "dog" }')!
						}
					}
				}
				responses:    {
					'201': openapi.ResponseSpec{
						description: 'Pet created'
						content:     {
							'application/json': openapi.MediaType{
								schema:  Reference{
									ref: '#/components/schemas/Pet'
								}
								example: json.raw_decode('{ "id": 3, "name": "Bella", "tag": "dog" }')!
							}
						}
					}
					'400': openapi.ResponseSpec{
						description: 'Invalid input'
					}
				}
			}
		}
		'/pets/{petId}': PathItem{
			get:    Operation{
				summary:      'Get a pet by ID'
				operation_id: 'getPet'
				parameters:   [
					openapi.Parameter{
						name:        'petId'
						in_:         'path'
						description: 'ID of the pet to retrieve'
						required:    true
						schema:      Schema{
							typ:     'integer'
							format:  'int64'
							example: 1
						}
					},
				]
				responses:    {
					'200': openapi.ResponseSpec{
						description: 'A pet'
						content:     {
							'application/json': openapi.MediaType{
								schema:  Reference{
									ref: '#/components/schemas/Pet'
								}
								example: json.raw_decode('{ "id": 1, "name": "Fluffy", "tag": "dog" }')!
							}
						}
					}
					'404': openapi.ResponseSpec{
						description: 'Pet not found'
					}
				}
			}
			delete: Operation{
				summary:      'Delete a pet by ID'
				operation_id: 'deletePet'
				parameters:   [
					openapi.Parameter{
						name:        'petId'
						in_:         'path'
						description: 'ID of the pet to delete'
						required:    true
						schema:      Schema{
							typ:     'integer'
							format:  'int64'
							example: 1
						}
					},
				]
				responses:    {
					'204': openapi.ResponseSpec{
						description: 'Pet deleted'
					}
					'404': openapi.ResponseSpec{
						description: 'Pet not found'
					}
				}
			}
		}
	}
	components: Components{
		schemas: {
			'Pet':    SchemaRef(Schema{
				typ:        'object'
				required:   ['id', 'name']
				properties: {
					'id':   SchemaRef(Schema{
						typ:    'integer'
						format: 'int64'
					})
					'name': SchemaRef(Schema{
						typ: 'string'
					})
					'tag':  SchemaRef(Schema{
						typ: 'string'
					})
				}
			})
			'NewPet': SchemaRef(Schema{
				typ:        'object'
				required:   ['name']
				properties: {
					'name': SchemaRef(Schema{
						typ: 'string'
					})
					'tag':  SchemaRef(Schema{
						typ: 'string'
					})
				}
			})
			'Pets':   SchemaRef(Schema{
				typ:   'array'
				items: SchemaRef(Reference{
					ref: '#/components/schemas/Pet'
				})
			})
		}
	}
}

const actor_spec = ActorSpecification{
	name:        'Pet Store API'
	description: 'A sample API for a pet store'
	structure:   Struct{}
	interfaces:  [.openapi]
	methods:     [
		ActorMethod{
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
				ContentDescriptor{
					name:        'limit'
					summary:     'Maximum number of pets to return'
					description: 'Maximum number of pets to return'
					required:    false
					schema:      SchemaRef(Schema{
						typ:     'integer'
						format:  'int32'
						example: 10
					})
				},
			]
			result:     ContentDescriptor{
				name:        'result'
				description: 'The response of the operation.'
				required:    true
				schema:      SchemaRef(Reference{
					ref: '#/components/schemas/Pets'
				})
			}
			errors:     [
				ErrorSpec{
					code:    400
					message: 'Invalid request'
				},
			]
		},
		ActorMethod{
			name:    'createPet'
			summary: 'Create a new pet'
			example: openrpc.ExamplePairing{
				result: openrpc.ExampleRef(openrpc.Example{
					name:  'Example response'
					value: '[]'
				})
			}
			result:  ContentDescriptor{
				name:        'result'
				description: 'The response of the operation.'
				required:    true
			}
			errors:  [
				ErrorSpec{
					code:    400
					message: 'Invalid input'
				},
			]
		},
		ActorMethod{
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
				ContentDescriptor{
					name:        'petId'
					summary:     'ID of the pet to retrieve'
					description: 'ID of the pet to retrieve'
					required:    true
					schema:      SchemaRef(Schema{
						typ:     'integer'
						format:  'int64'
						example: 1
					})
				},
			]
			result:     ContentDescriptor{
				name:        'result'
				description: 'The response of the operation.'
				required:    true
				schema:      SchemaRef(Reference{
					ref: '#/components/schemas/Pet'
				})
			}
			errors:     [
				ErrorSpec{
					code:    404
					message: 'Pet not found'
				},
			]
		},
		ActorMethod{
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
				ContentDescriptor{
					name:        'petId'
					summary:     'ID of the pet to delete'
					description: 'ID of the pet to delete'
					required:    true
					schema:      SchemaRef(Schema{
						typ:     'integer'
						format:  'int64'
						example: 1
					})
				},
			]
			result:     ContentDescriptor{
				name:        'result'
				description: 'The response of the operation.'
				required:    true
			}
			errors:     [
				ErrorSpec{
					code:    404
					message: 'Pet not found'
				},
			]
		},
	]
	objects:     [
		BaseObject{
			schema: Schema{
				typ:        'object'
				properties: {
					'id':   SchemaRef(Schema{
						typ:    'integer'
						format: 'int64'
					})
					'name': SchemaRef(Schema{
						typ: 'string'
					})
					'tag':  SchemaRef(Schema{
						typ: 'string'
					})
				}
				required:   ['id', 'name']
			}
		},
		BaseObject{
			schema: Schema{
				typ:        'object'
				properties: {
					'name': SchemaRef(Schema{
						typ: 'string'
					})
					'tag':  SchemaRef(Schema{
						typ: 'string'
					})
				}
				required:   ['name']
			}
		},
		BaseObject{
			schema: Schema{
				typ:   'array'
				items: jsonschema.Items(SchemaRef(Reference{
					ref: '#/components/schemas/Pet'
				}))
			}
		},
	]
}

pub fn test_from_openapi() ! {
	// panic(from_openapi(openapi_spec)!)
	assert from_openapi(openapi_spec)! == actor_spec
}
