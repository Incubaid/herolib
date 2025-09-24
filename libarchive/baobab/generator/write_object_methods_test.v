module generator

import freeflowuniverse.herolib.core.code
import os

// // generate_object_methods generates CRUD actor methods for a provided structure
// pub fn (generator ActorGenerator) generate_object_methods(structure code.Struct) []code.Function {
// 	return [
// 		generator.generate_get_method(structure),
// 		// generator.generate_set_method(structure),
// 		// generator.generate_delete_method(structure),
// 		// generator.generate_get_method(structure),
// 	]
// }

// generate_object_methods generates CRUD actor methods for a provided structure
pub fn test_generate_get_method() {
	generator := ActorGenerator{'test'}
	actor_struct := code.Struct{
		name:   'TestActor'
		fields: [
			code.StructField{
				name: 'test_struct_map'
				typ:  code.Type{
					symbol: 'map[string]&TestStruct'
				}
			},
		]
	}

	test_struct := code.Struct{
		name: 'TestStruct'
	}
	field := get_child_field(
		parent: actor_struct
		child:  test_struct
	)

	method := generator.generate_get_method(
		actor_name:  actor_struct.name
		actor_field: field
		root_struct: test_struct
	)
}

// // generate_object_methods generates CRUD actor methods for a provided structure
// pub fn (generator ActorGenerator) generate_set_method(structure code.Struct) code.Function {
// 	params_getter := "id := params.get('id')!"
// 	field := generator.get_object_field(structure)
// 	object_getter := 'object := actor.${field.name}[id]'
// 	body := '${params_getter}\n${object_getter}\nreturn object'
// 	get_method := code.Function{
// 		name: 'get_${generator.model_name}'
// 		description: 'gets the ${structure.name} with the given object id'
// 		receiver: code.Param{
// 			name: 'actor'
// 			struct_: generator.actor_struct
// 		}
// 		params: [
// 			code.Param{
// 				name: 'id'
// 				typ: code.Type{
// 					symbol: 'string'
// 				}
// 			},
// 		]
// 		result: code.Result{
// 			structure: structure
// 		}
// 		body: body
// 	}
// 	return get_method
// }

// // generate_object_methods generates CRUD actor methods for a provided structure
// pub fn (generator ActorGenerator) generate_get_method(structure code.Struct) code.Function {
// 	params_getter := "id := params.get('id')!"
// 	field := generator.get_object_field(structure)
// 	object_getter := 'object := actor.${field.name}[id]'
// 	body := '${params_getter}\n${object_getter}\nreturn object'
// 	get_method := code.Function{
// 		name: 'get_${generator.model_name}'
// 		description: 'gets the ${structure.name} with the given object id'
// 		receiver: code.Param{
// 			name: 'actor'
// 			struct_: generator.actor_struct
// 		}
// 		params: [
// 			code.Param{
// 				name: 'id'
// 				typ: code.Type{
// 					symbol: 'string'
// 				}
// 			},
// 		]
// 		result: code.Result{
// 			structure: structure
// 		}
// 		body: body
// 	}
// 	return get_method
// }

// // generate_object_methods generates CRUD actor methods for a provided structure
// pub fn (generator ActorGenerator) generate_delete_method(structure code.Struct) code.Function {
// 	params_getter := "id := params.get('id')!"
// 	field := generator.get_object_field(structure)
// 	object_getter := 'object := actor.${field.name}[id]'
// 	body := '${params_getter}\n${object_getter}\nreturn object'
// 	get_method := code.Function{
// 		name: 'get_${generator.model_name}'
// 		description: 'gets the ${structure.name} with the given object id'
// 		receiver: code.Param{
// 			name: 'actor'
// 			struct_: generator.actor_struct
// 		}
// 		params: [
// 			code.Param{
// 				name: 'id'
// 				typ: code.Type{
// 					symbol: 'string'
// 				}
// 			},
// 		]
// 		result: code.Result{
// 			structure: structure
// 		}
// 		body: body
// 	}
// 	return get_method
// }

// pub fn (generator ActorGenerator) get_object_field(structure code.Struct) code.StructField {
// 	fields := generator.actor_struct.fields.filter(it.typ.symbol == 'map[string]&${structure.name}')
// 	if fields.len != 1 {
// 		panic('this should never happen')
// 	}
// 	return fields[0]
// }
