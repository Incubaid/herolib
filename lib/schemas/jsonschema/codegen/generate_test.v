module codegen

import log
import freeflowuniverse.herolib.develop.codetools as code

fn test_struct_to_schema() {
	struct_ := code.Struct{
		name:        'test_name'
		description: 'a codemodel struct to test struct to schema serialization'
		fields:      [
			code.StructField{
				name:        'test_field'
				description: 'a field of the test struct to test fields serialization into schema'
				typ:         code.String{}
			},
		]
	}

	schema := struct_to_schema(struct_)
	log.debug(schema.str())
}
