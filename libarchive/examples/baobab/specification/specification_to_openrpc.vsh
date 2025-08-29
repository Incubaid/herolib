#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import json
import freeflowuniverse.herolib.baobab.specification
import freeflowuniverse.herolib.core.code
import freeflowuniverse.herolib.schemas.jsonschema
import freeflowuniverse.herolib.schemas.openrpc
import os

const actor_specification = specification.ActorSpecification{
	name:       'PetStore'
	structure:  code.Struct{}
	interfaces: [.openrpc]
	methods:    [
		specification.ActorMethod{
			name:        'GetPets'
			description: 'finds pets in the system that the user has access to by tags and within a limit'
			parameters:  [
				openrpc.ContentDescriptor{
					name:        'tags'
					description: 'tags to filter by'
					schema:      jsonschema.SchemaRef(jsonschema.Schema{
						typ:   'array'
						items: jsonschema.Items(jsonschema.SchemaRef(jsonschema.Schema{
							typ: 'string'
						}))
					})
				},
				openrpc.ContentDescriptor{
					name:        'limit'
					description: 'maximum number of results to return'
					schema:      jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'integer'
					})
				},
			]
			result:      openrpc.ContentDescriptor{
				name:        'pet_list'
				description: 'all pets from the system, that matches the tags'
				schema:      jsonschema.SchemaRef(jsonschema.Reference{
					ref: '#/components/schemas/Pet'
				})
			}
		},
		specification.ActorMethod{
			name:        'CreatePet'
			description: 'creates a new pet in the store. Duplicates are allowed.'
			parameters:  [
				openrpc.ContentDescriptor{
					name:        'new_pet'
					description: 'Pet to add to the store.'
					schema:      jsonschema.SchemaRef(jsonschema.Reference{
						ref: '#/components/schemas/NewPet'
					})
				},
			]
			result:      openrpc.ContentDescriptor{
				name:        'pet'
				description: 'the newly created pet'
				schema:      jsonschema.SchemaRef(jsonschema.Reference{
					ref: '#/components/schemas/Pet'
				})
			}
		},
		specification.ActorMethod{
			name:        'GetPetById'
			description: 'gets a pet based on a single ID, if the user has access to the pet'
			parameters:  [
				openrpc.ContentDescriptor{
					name:        'id'
					description: 'ID of pet to fetch'
					schema:      jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'integer'
					})
				},
			]
			result:      openrpc.ContentDescriptor{
				name:        'pet'
				description: 'pet response'
				schema:      jsonschema.SchemaRef(jsonschema.Reference{
					ref: '#/components/schemas/Pet'
				})
			}
		},
		specification.ActorMethod{
			name:        'DeletePetById'
			description: 'deletes a single pet based on the ID supplied'
			parameters:  [
				openrpc.ContentDescriptor{
					name:        'id'
					description: 'ID of pet to delete'
					schema:      jsonschema.SchemaRef(jsonschema.Schema{
						typ: 'integer'
					})
				},
			]
			result:      openrpc.ContentDescriptor{
				name:        'pet'
				description: 'pet deleted'
				schema:      jsonschema.SchemaRef(jsonschema.Schema{
					typ: 'null'
				})
			}
		},
	]
}

openrpc_specification := actor_specification.to_openrpc()
println(json.encode_pretty(openrpc_specification))
