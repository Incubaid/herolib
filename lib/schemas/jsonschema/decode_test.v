module jsonschema

import os
import incubaid.herolib.core.pathlib

const testdata = '${os.dir(@FILE)}/testdata'

struct Pet {
	name string
}

fn test_decode() ! {
	mut pet_schema_file := pathlib.get_file(
		path: '${testdata}/pet.json'
	)!
	pet_schema_str := pet_schema_file.read()!
	pet_schema := decode(pet_schema_str)!
	assert pet_schema == Schema{
		typ:        'object'
		properties: {
			'name': Schema{
				typ: 'string'
			}
		}
		required:   ['name']
	}
}

fn test_decode_schemaref() ! {
	mut pet_schema_file := pathlib.get_file(
		path: '${testdata}/pet.json'
	)!
	pet_schema_str := pet_schema_file.read()!
	pet_schemaref := decode(pet_schema_str)!
	assert pet_schemaref == Schema{
		typ:        'object'
		properties: {
			'name': Schema{
				typ: 'string'
			}
		}
		required:   ['name']
	}
}

fn test_decode_with_example() ! {
	// Test schema with example field
	schema_with_example := '{
		"type": "string",
		"description": "A test string",
		"example": "test_value"
	}'

	schema := decode(schema_with_example)!
	assert schema.typ == 'string'
	assert schema.description == 'A test string'
	assert schema.example.str() == 'test_value'
}

fn test_decode_with_object_example() ! {
	// Test schema with object example
	schema_with_object_example := '{
		"type": "object",
		"description": "A test object",
		"example": {
			"name": "test",
			"value": 123
		}
	}'

	schema := decode(schema_with_object_example)!
	assert schema.typ == 'object'
	assert schema.description == 'A test object'
	// Object examples are stored as json2.Any and need special handling
	assert schema.example.str().contains('test')
}

fn test_decode_without_example() ! {
	// Test schema without example field
	schema_without_example := '{
		"type": "integer",
		"description": "A test integer"
	}'

	schema := decode(schema_without_example)!
	assert schema.typ == 'integer'
	assert schema.description == 'A test integer'
	// Should have empty example
	assert schema.example.str() == '[]'
}
