module specification

import freeflowuniverse.herolib.core.code
import freeflowuniverse.herolib.schemas.jsonschema { Schema, SchemaRef }
import freeflowuniverse.herolib.schemas.openapi
import freeflowuniverse.herolib.schemas.openrpc

const actor_spec = ActorSpecification{
	name:       'Petstore'
	structure:  code.Struct{
		is_pub: false
	}
	interfaces: [.openrpc]
	methods:    [
		ActorMethod{
			name:       'list_pets'
			summary:    'List all pets'
			parameters: [
				openrpc.ContentDescriptor{
					name:        'limit'
					description: 'How many items to return at one time (max 100)'
					required:    false
					schema:      SchemaRef(Schema{
						typ:     'integer'
						minimum: 1
					})
				},
			]
			result:     openrpc.ContentDescriptor{
				name:        'pets'
				description: 'A paged array of pets'
				schema:      SchemaRef(Schema{
					typ:   'array'
					items: jsonschema.Items(SchemaRef(Schema{
						typ:        'object'
						properties: {
							'id':   SchemaRef(jsonschema.Reference{
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
				openrpc.ContentDescriptor{
					name:        'newPetName'
					description: 'Name of pet to create'
					required:    true
					schema:      SchemaRef(Schema{
						typ: 'string'
					})
				},
				openrpc.ContentDescriptor{
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
			result:  openrpc.ContentDescriptor{
				name:        'pet'
				description: 'Expected response to a valid request'
				schema:      SchemaRef(Schema{
					typ:        'object'
					properties: {
						'id':   SchemaRef(jsonschema.Reference{
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
				openrpc.ContentDescriptor{
					name:        'updatedPetName'
					description: 'New name for the pet'
					required:    true
					schema:      SchemaRef(Schema{
						typ: 'string'
					})
				},
				openrpc.ContentDescriptor{
					name:        'updatedPetTag'
					description: 'New tag for the pet'
					schema:      SchemaRef(Schema{
						typ: 'string'
					})
				},
			]
			result:     openrpc.ContentDescriptor{
				name:        'pet'
				description: 'Updated pet object'
				schema:      SchemaRef(Schema{
					typ:        'object'
					properties: {
						'id':   SchemaRef(jsonschema.Reference{
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
			result:  openrpc.ContentDescriptor{
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
					'id':   SchemaRef(jsonschema.Reference{
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

// Converts ActorSpecification to OpenAPI
pub fn test_specification_to_openapi() {
	panic(actor_spec.to_openapi())
}
