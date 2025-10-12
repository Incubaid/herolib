module codegen

import log
import incubaid.herolib.schemas.jsonschema { Reference, Schema }

fn test_schema_to_structs_simple() ! {
	struct_str := '
// person struct used for test schema encoding
struct TestPerson {
	name string
	age int
}'

	schema := Schema{
		schema:      'test'
		title:       'TestPerson'
		description: 'person struct used for test schema encoding'
		typ:         'object'
		properties:  {
			'name': Schema{
				typ:         'string'
				description: 'name of the test person'
			}
			'age':  Schema{
				typ:         'integer'
				description: 'age of the test person'
			}
		}
	}
	encoded := schema_to_structs(schema)
	assert encoded.len == 1
	assert encoded[0].trim_space() == struct_str.trim_space()
}

fn test_schema_to_structs_with_reference() ! {
	struct_str := '
// person struct used for test schema encoding
struct TestPerson {
	name string
	age int
	friend Friend
}'

	schema := Schema{
		schema:      'test'
		title:       'TestPerson'
		description: 'person struct used for test schema encoding'
		typ:         'object'
		properties:  {
			'name':   Schema{
				typ:         'string'
				description: 'name of the test person'
			}
			'age':    Schema{
				typ:         'integer'
				description: 'age of the test person'
			}
			'friend': Reference{
				ref: '#components/schemas/Friend'
			}
		}
	}
	encoded := schema_to_structs(schema)
	assert encoded.len == 1
	assert encoded[0].trim_space() == struct_str.trim_space()
}

fn test_schema_to_structs_recursive() ! {
	schema := Schema{
		schema:      'test'
		title:       'TestPerson'
		description: 'person struct used for test schema encoding'
		typ:         'object'
		properties:  {
			'name':   Schema{
				typ:         'string'
				description: 'name of the test person'
			}
			'age':    Schema{
				typ:         'integer'
				description: 'age of the test person'
			}
			'friend': Schema{
				title:       'TestFriend'
				typ:         'object'
				description: 'friend of the test person'
				properties:  {
					'name': Schema{
						typ:         'string'
						description: 'name of the test friend person'
					}
					'age':  Schema{
						typ:         'integer'
						description: 'age of the test friend person'
					}
				}
			}
		}
	}
	encoded := schema_to_structs(schema)
	log.debug(encoded.str())
}
