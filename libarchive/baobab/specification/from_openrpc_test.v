module specification

import freeflowuniverse.herolib.core.code { Struct }
import freeflowuniverse.herolib.schemas.openrpc { ContentDescriptor }
import freeflowuniverse.herolib.schemas.openapi { Components, Info }
import freeflowuniverse.herolib.schemas.jsonschema { Reference, Schema, SchemaRef }

const openrpc_spec = openrpc.OpenRPC{
	openrpc:    '1.0.0-rc1'
	info:       openrpc.Info{
		title:   'Petstore'
		license: openrpc.License{
			name: 'MIT'
		}
		version: '1.0.0'
	}
	servers:    [
		openrpc.Server{
			name: 'localhost'
			url:  openrpc.RuntimeExpression('http://localhost:8080')
		},
	]
	methods:    [
		openrpc.Method{
			name:     'list_pets'
			summary:  'List all pets'
			params:   [
				openrpc.ContentDescriptorRef(ContentDescriptor{
					name:        'limit'
					description: 'How many items to return at one time (max 100)'
					required:    false
					schema:      SchemaRef(Schema{
						typ:     'integer'
						minimum: 1
					})
				}),
			]
			result:   openrpc.ContentDescriptorRef(ContentDescriptor{
				name:        'pets'
				description: 'A paged array of pets'
				schema:      SchemaRef(Schema{
					typ:   'array'
					items: jsonschema.Items(SchemaRef(Reference{
						ref: '#/components/schemas/Pet'
					}))
				})
			})
			examples: [
				openrpc.ExamplePairing{
					name:        'listPetExample'
					description: 'List pet example'
				},
			]
		},
		openrpc.Method{
			name:     'create_pet'
			summary:  'Create a pet'
			params:   [
				openrpc.ContentDescriptorRef(ContentDescriptor{
					name:        'newPetName'
					description: 'Name of pet to create'
					required:    true
					schema:      SchemaRef(Schema{
						typ: 'string'
					})
				}),
				openrpc.ContentDescriptorRef(ContentDescriptor{
					name:        'newPetTag'
					description: 'Pet tag to create'
					schema:      SchemaRef(Schema{
						typ: 'string'
					})
				}),
			]
			result:   openrpc.ContentDescriptorRef(Reference{
				ref: '#/components/contentDescriptors/PetId'
			})
			examples: [
				openrpc.ExamplePairing{
					name:        'createPetExample'
					description: 'Create pet example'
				},
			]
		},
		openrpc.Method{
			name:     'get_pet'
			summary:  'Info for a specific pet'
			params:   [
				openrpc.ContentDescriptorRef(Reference{
					ref: '#/components/contentDescriptors/PetId'
				}),
			]
			result:   openrpc.ContentDescriptorRef(ContentDescriptor{
				name:        'pet'
				description: 'Expected response to a valid request'
				schema:      SchemaRef(Reference{
					ref: '#/components/schemas/Pet'
				})
			})
			examples: [
				openrpc.ExamplePairing{
					name:        'getPetExample'
					description: 'Get pet example'
				},
			]
		},
		openrpc.Method{
			name:     'update_pet'
			summary:  'Update a pet'
			params:   [
				openrpc.ContentDescriptorRef(Reference{
					ref: '#/components/contentDescriptors/PetId'
				}),
				openrpc.ContentDescriptorRef(ContentDescriptor{
					name:        'updatedPetName'
					description: 'New name for the pet'
					required:    true
					schema:      SchemaRef(Schema{
						typ: 'string'
					})
				}),
				openrpc.ContentDescriptorRef(ContentDescriptor{
					name:        'updatedPetTag'
					description: 'New tag for the pet'
					schema:      SchemaRef(Schema{
						typ: 'string'
					})
				}),
			]
			result:   openrpc.ContentDescriptorRef(ContentDescriptor{
				name:        'pet'
				description: 'Updated pet object'
				schema:      SchemaRef(Reference{
					ref: '#/components/schemas/Pet'
				})
			})
			examples: [
				openrpc.ExamplePairing{
					name:        'updatePetExample'
					description: 'Update pet example'
				},
			]
		},
		openrpc.Method{
			name:     'delete_pet'
			summary:  'Delete a pet'
			params:   [
				openrpc.ContentDescriptorRef(Reference{
					ref: '#/components/contentDescriptors/PetId'
				}),
			]
			result:   openrpc.ContentDescriptorRef(ContentDescriptor{
				name:        'success'
				description: 'Boolean indicating success'
				schema:      SchemaRef(Schema{
					typ: 'boolean'
				})
			})
			examples: [
				openrpc.ExamplePairing{
					name:        'deletePetExample'
					description: 'Delete pet example'
				},
			]
		},
	]
	components: openrpc.Components{
		content_descriptors: {
			'PetId': openrpc.ContentDescriptorRef(ContentDescriptor{
				name:        'petId'
				description: 'The ID of the pet'
				required:    true
				schema:      SchemaRef(Reference{
					ref: '#/components/schemas/PetId'
				})
			})
		}
		schemas:             {
			'PetId': SchemaRef(Schema{
				typ:     'integer'
				minimum: 0
			})
			'Pet':   SchemaRef(Schema{
				typ:        'object'
				properties: {
					'id':   SchemaRef(Reference{
						ref: '#/components/schemas/PetId'
					})
					'name': SchemaRef(Schema{
						typ: 'string'
					})
					'tag':  SchemaRef(Schema{
						typ: 'string'
					})
				}
				required:   ['id', 'name']
			})
		}
	}
}

const actor_spec = ActorSpecification{
	name:       'Petstore'
	structure:  Struct{
		is_pub: false
	}
	interfaces: [.openrpc]
	methods:    [
		ActorMethod{
			name:       'list_pets'
			summary:    'List all pets'
			parameters: [
				ContentDescriptor{
					name:        'limit'
					description: 'How many items to return at one time (max 100)'
					required:    false
					schema:      SchemaRef(Schema{
						typ:     'integer'
						minimum: 1
					})
				},
			]
			result:     ContentDescriptor{
				name:        'pets'
				description: 'A paged array of pets'
				schema:      SchemaRef(Schema{
					typ:   'array'
					items: jsonschema.Items(SchemaRef(Schema{
						typ:        'object'
						properties: {
							'id':   SchemaRef(Reference{
								ref: '#/components/schemas/PetId'
							})
							'name': SchemaRef(Schema{
								typ: 'string'
							})
							'tag':  SchemaRef(Schema{
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
		},
		ActorMethod{
			name:       'create_pet'
			summary:    'Create a pet'
			parameters: [
				ContentDescriptor{
					name:        'newPetName'
					description: 'Name of pet to create'
					required:    true
					schema:      SchemaRef(Schema{
						typ: 'string'
					})
				},
				ContentDescriptor{
					name:        'newPetTag'
					description: 'Pet tag to create'
					schema:      SchemaRef(Schema{
						typ: 'string'
					})
				},
			]
		},
		ActorMethod{
			name:    'get_pet'
			summary: 'Info for a specific pet'
			result:  ContentDescriptor{
				name:        'pet'
				description: 'Expected response to a valid request'
				schema:      SchemaRef(Schema{
					typ:        'object'
					properties: {
						'id':   SchemaRef(Reference{
							ref: '#/components/schemas/PetId'
						})
						'name': SchemaRef(Schema{
							typ: 'string'
						})
						'tag':  SchemaRef(Schema{
							typ: 'string'
						})
					}
					required:   [
						'id',
						'name',
					]
				})
			}
		},
		ActorMethod{
			name:       'update_pet'
			summary:    'Update a pet'
			parameters: [
				ContentDescriptor{
					name:        'updatedPetName'
					description: 'New name for the pet'
					required:    true
					schema:      SchemaRef(Schema{
						typ: 'string'
					})
				},
				ContentDescriptor{
					name:        'updatedPetTag'
					description: 'New tag for the pet'
					schema:      SchemaRef(Schema{
						typ: 'string'
					})
				},
			]
			result:     ContentDescriptor{
				name:        'pet'
				description: 'Updated pet object'
				schema:      SchemaRef(Schema{
					typ:        'object'
					properties: {
						'id':   SchemaRef(Reference{
							ref: '#/components/schemas/PetId'
						})
						'name': SchemaRef(Schema{
							typ: 'string'
						})
						'tag':  SchemaRef(Schema{
							typ: 'string'
						})
					}
					required:   [
						'id',
						'name',
					]
				})
			}
		},
		ActorMethod{
			name:    'delete_pet'
			summary: 'Delete a pet'
			result:  ContentDescriptor{
				name:        'success'
				description: 'Boolean indicating success'
				schema:      SchemaRef(Schema{
					typ: 'boolean'
				})
			}
		},
	]
	objects:    [
		BaseObject{
			schema: Schema{
				id:         'pet'
				title:      'Pet'
				typ:        'object'
				properties: {
					'id':   SchemaRef(Reference{
						ref: '#/components/schemas/PetId'
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
	]
}

pub fn test_from_openrpc() ! {
	actor_spec_ := from_openrpc(openrpc_spec)!
	assert actor_spec_.methods.len == actor_spec.methods.len
	assert_methods_match(actor_spec_.methods[0], actor_spec.methods[0])

	// assert from_openrpc(openrpc_spec)! == actor_spec
}

fn assert_methods_match(a ActorMethod, b ActorMethod) {
	// Compare method names
	assert a.name == b.name, 'Method names do not match: ${a.name} != ${b.name}'

	// Compare summaries
	assert a.summary == b.summary, 'Method summaries do not match for method ${a.name}.'

	// Compare descriptions
	assert a.description == b.description, 'Method descriptions do not match for method ${a.name}.'

	// Compare parameters count
	assert a.parameters.len == b.parameters.len, 'Parameter counts do not match for method ${a.name}.'

	// Compare each parameter
	for i, param_a in a.parameters {
		assert_params_match(param_a, b.parameters[i], a.name)
	}

	// Compare result
	assert_params_match(a.result, b.result, a.name)
}

fn assert_params_match(a ContentDescriptor, b ContentDescriptor, method_name string) {
	// Compare parameter names
	assert a.name == b.name, 'Parameter names do not match in method ${method_name}: ${a.name} != ${b.name}'

	// Compare summaries
	assert a.summary == b.summary, 'Parameter summaries do not match in method ${method_name}: ${a.name}'

	// Compare descriptions
	assert a.description == b.description, 'Parameter descriptions do not match in method ${method_name}: ${a.name}'

	// Compare required flags
	assert a.required == b.required, 'Required flags do not match in method ${method_name}: ${a.name}'

	// Compare schemas
	// assert_schemas_match(a.schema, b.schema, method_name, a.name)
}

// fn assert_schemas_match(a jsonschema.SchemaRef, b jsonschema.SchemaRef, method_name string, param_name string) {
//     if a is Schema &&
//     // Compare schema types
//     assert a.typ == b.typ, 'Schema types do not match for parameter ${param_name} in method ${method_name}: ${a.typ} != ${b.typ}'

//     // Compare schema titles
//     assert a.title == b.title, 'Schema titles do not match for parameter ${param_name} in method ${method_name}.'

//     // Compare schema descriptions
//     assert a.description == b.description, 'Schema descriptions do not match for parameter ${param_name} in method ${method_name}.'

//     // Compare other schema fields as needed (e.g., properties, additional properties, items, etc.)
//     // Add more checks here if needed for deeper schema comparisons
// }
