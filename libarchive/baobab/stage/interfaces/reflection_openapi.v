module interfaces

// import os
// import time
// import veb
// import x.json2 {Any}
// import net.http
import freeflowuniverse.herolib.baobab.stage { Action }
import freeflowuniverse.herolib.schemas.openapi { Request }

pub fn openapi_request_to_action(request Request) Action {
	// // Convert incoming OpenAPI request to a procedure call
	// mut params := []Any{}

	// if request.arguments.len > 0 {
	//     params << request.arguments.values().map(it.str()).clone()
	// }

	// if request.body != '' {
	//     params << request.body
	// }

	// if request.parameters != '' {
	//     params << request.body
	// }

	// if request.parameters.len != 0 {
	//     mut param_map := map[string]Any{} // Store parameters with correct types

	//     for param_name, param_value in request.parameters {
	//         operation_param := request.operation.parameters.filter(it.name == param_name)
	//         if operation_param.len > 0 {
	//             param_schema := operation_param[0].schema as Schema
	//             param_type := param_schema.typ
	//             param_format := param_schema.format

	//             // Convert parameter value to corresponding type
	//             match param_type {
	//                 'integer' {
	//                     match param_format {
	//                         'int32' {
	//                             param_map[param_name] = param_value.int() // Convert to int
	//                         }
	//                         'int64' {
	//                             param_map[param_name] = param_value.i64() // Convert to i64
	//                         }
	//                         else {
	//                             param_map[param_name] = param_value.int() // Default to int
	//                         }
	//                     }
	//                 }
	//                 'string' {
	//                     param_map[param_name] = param_value // Already a string
	//                 }
	//                 'boolean' {
	//                     param_map[param_name] = param_value.bool() // Convert to bool
	//                 }
	//                 'number' {
	//                     match param_format {
	//                         'float' {
	//                             param_map[param_name] = param_value.f32() // Convert to float
	//                         }
	//                         'double' {
	//                             param_map[param_name] = param_value.f64() // Convert to double
	//                         }
	//                         else {
	//                             param_map[param_name] = param_value.f64() // Default to double
	//                         }
	//                     }
	//                 }
	//                 else {
	//                     param_map[param_name] = param_value // Leave as string for unknown types
	//                 }
	//             }
	//         } else {
	//             // If the parameter is not defined in the OpenAPI operation, skip or log it
	//             println('Unknown parameter: $param_name')
	//         }
	//     }

	//     // Encode the parameter map to JSON if needed
	//     params << json.encode(param_map.str())
	// }

	// call := Action{
	//     name: request.operation.operation_id
	//     params_json: json2.encode(params.str()) // Keep as a string since ProcedureCall expects a string
	// }
	// return call
	return Action{}
}
