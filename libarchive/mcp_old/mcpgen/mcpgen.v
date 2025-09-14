module mcpgen

import freeflowuniverse.herolib.core.code
import freeflowuniverse.herolib.mcp
import freeflowuniverse.herolib.schemas.jsonschema
import freeflowuniverse.herolib.schemas.jsonschema.codegen
import os

pub struct FunctionPointer {
	name        string // name of function
	module_path string // path to module
}

// create_mcp_tool_code receives the name of a V language function string, and the path to the module in which it exists.
// returns an MCP Tool code in v for attaching the function to the mcp server
// function_pointers: A list of function pointers to generate tools for
pub fn (d &MCPGen) create_mcp_tools_code(function_pointers []FunctionPointer) !string {
	mut str := ''

	for function_pointer in function_pointers {
		str += d.create_mcp_tool_code(function_pointer.name, function_pointer.module_path)!
	}

	return str
}

// create_mcp_tool_code receives the name of a V language function string, and the path to the module in which it exists.
// returns an MCP Tool code in v for attaching the function to the mcp server
pub fn (d &MCPGen) create_mcp_tool_code(function_name string, module_path string) !string {
	if !os.exists(module_path) {
		return error('Module path does not exist: ${module_path}')
	}

	function := code.get_function_from_module(module_path, function_name) or {
		return error('Failed to get function ${function_name} from module ${module_path}\n${err}')
	}

	mut types := map[string]string{}
	for param in function.params {
		// Check if the type is an Object (struct)
		if param.typ is code.Object {
			types[param.typ.symbol()] = code.get_type_from_module(module_path, param.typ.symbol())!
		}
	}

	// Get the result type if it's a struct
	mut result_ := ''
	if function.result.typ is code.Result {
		result_type := (function.result.typ as code.Result).typ
		if result_type is code.Object {
			result_ = code.get_type_from_module(module_path, result_type.symbol())!
		}
	} else if function.result.typ is code.Object {
		result_ = code.get_type_from_module(module_path, function.result.typ.symbol())!
	}

	tool_name := function.name
	tool := d.create_mcp_tool(function, types)!
	handler := d.create_mcp_tool_handler(function, types, result_)!
	str := $tmpl('./templates/tool_code.v.template')
	return str
}

// create_mcp_tool parses a V language function string and returns an MCP Tool struct
// function: The V function string including preceding comments
// types: A map of struct names to their definitions for complex parameter types
// result: The type of result of the create_mcp_tool function. Could be simply string, or struct {...}
pub fn (d &MCPGen) create_mcp_tool_handler(function code.Function, types map[string]string, result_ string) !string {
	decode_stmts := function.params.map(argument_decode_stmt(it)).join_lines()

	function_call := 'd.${function.name}(${function.params.map(it.name).join(',')})'
	result := code.parse_type(result_)
	str := $tmpl('./templates/tool_handler.v.template')
	return str
}

pub fn argument_decode_stmt(param code.Param) string {
	return if param.typ is code.Integer {
		'${param.name} := arguments["${param.name}"].int()'
	} else if param.typ is code.Boolean {
		'${param.name} := arguments["${param.name}"].bool()'
	} else if param.typ is code.String {
		'${param.name} := arguments["${param.name}"].str()'
	} else if param.typ is code.Object {
		'${param.name} := json.decode[${param.typ.symbol()}](arguments["${param.name}"].str())!'
	} else if param.typ is code.Array {
		'${param.name} := json.decode[${param.typ.symbol()}](arguments["${param.name}"].str())!'
	} else if param.typ is code.Map {
		'${param.name} := json.decode[${param.typ.symbol()}](arguments["${param.name}"].str())!'
	} else {
		panic('Unsupported type: ${param.typ}')
	}
}

/*
in @generate_mcp.v , implement a create_mpc_tool_handler function that given a vlang function string and the types  that map to their corresponding type definitions (for instance struct some_type: SomeType{...}), generates a vlang function such as the following:

ou
pub fn (d &MCPGen) create_mcp_tool_tool_handler(arguments map[string]Any) !mcp.Tool {
	function := arguments['function'].str()
	types := json.decode[map[string]string](arguments['types'].str())!
	return d.create_mcp_tool(function, types)
}
*/

// create_mcp_tool parses a V language function string and returns an MCP Tool struct
// function: The V function string including preceding comments
// types: A map of struct names to their definitions for complex parameter types
pub fn (d MCPGen) create_mcp_tool(function code.Function, types map[string]string) !mcp.Tool {
	// Create input schema for parameters
	mut properties := map[string]jsonschema.SchemaRef{}
	mut required := []string{}

	for param in function.params {
		// Add to required parameters
		required << param.name

		// Create property for this parameter
		mut property := jsonschema.SchemaRef{}

		// Check if this is a complex type defined in the types map
		if param.typ.symbol() in types {
			// Parse the struct definition to create a nested schema
			struct_def := types[param.typ.symbol()]
			struct_schema := codegen.struct_to_schema(code.parse_struct(struct_def)!)
			if struct_schema is jsonschema.Schema {
				property = struct_schema
			} else {
				return error('Unsupported type: ${param.typ}')
			}
		} else {
			// Handle primitive types
			property = codegen.typesymbol_to_schema(param.typ.symbol())
		}

		properties[param.name] = property
	}

	// Create the input schema
	input_schema := jsonschema.Schema{
		typ:        'object'
		properties: properties
		required:   required
	}

	// Create and return the Tool
	return mcp.Tool{
		name:         function.name
		description:  function.description
		input_schema: input_schema
	}
}

// // create_mcp_tool_input_schema creates a jsonschema.Schema for a given input type
// // input: The input type string
// // returns: A jsonschema.Schema for the given input type
// // errors: Returns an error if the input type is not supported
// pub fn (d MCPGen) create_mcp_tool_input_schema(input string) !jsonschema.Schema {

// 	// if input is a primitive type, return a mcp jsonschema.Schema with that type
// 	if input == 'string' {
// 		return jsonschema.Schema{
// 			typ: 'string'
// 		}
// 	} else if input == 'int' {
// 		return jsonschema.Schema{
// 			typ: 'integer'
// 		}
// 	} else if input == 'float' {
// 		return jsonschema.Schema{
// 			typ: 'number'
// 		}
// 	} else if input == 'bool' {
// 		return jsonschema.Schema{
// 			typ: 'boolean'
// 		}
// 	}

// 	// if input is a struct, return a mcp jsonschema.Schema with typ 'object' and properties for each field in the struct
// 	if input.starts_with('pub struct ') {
// 		struct_name := input[11..].split(' ')[0]
// 		fields := parse_struct_fields(input)
// 		mut properties := map[string]jsonschema.Schema{}

// 		for field_name, field_type in fields {
// 			property := jsonschema.Schema{
// 				typ: d.create_mcp_tool_input_schema(field_type)!.typ
// 			}
// 			properties[field_name] = property
// 		}

// 		return jsonschema.Schema{
// 			typ: 'object',
// 			properties: properties
// 		}
// 	}

// 	// if input is an array, return a mcp jsonschema.Schema with typ 'array' and items of the item type
// 	if input.starts_with('[]') {
// 		item_type := input[2..]

// 		// For array types, we create a schema with type 'array'
// 		// The actual item type is determined by the primitive type
// 		mut item_type_str := 'string' // default
// 		if item_type == 'int' {
// 			item_type_str = 'integer'
// 		} else if item_type == 'float' {
// 			item_type_str = 'number'
// 		} else if item_type == 'bool' {
// 			item_type_str = 'boolean'
// 		}

// 		// Create a property for the array items
// 		mut property := jsonschema.Schema{
// 			typ: 'array'
// 		}

// 		// Add the property to the schema
// 		mut properties := map[string]jsonschema.Schema{}
// 		properties['items'] = property

// 		return jsonschema.Schema{
// 			typ: 'array',
// 			properties: properties
// 		}
// 	}

// 	// Default to string type for unknown types
// 	return jsonschema.Schema{
// 		typ: 'string'
// 	}
// }

// parse_struct_fields parses a V language struct definition string and returns a map of field names to their types
fn parse_struct_fields(struct_def string) map[string]string {
	mut fields := map[string]string{}

	// Find the opening and closing braces of the struct definition
	start_idx := struct_def.index('{') or { return fields }
	end_idx := struct_def.last_index('}') or { return fields }

	// Extract the content between the braces
	struct_content := struct_def[start_idx + 1..end_idx].trim_space()

	// Split the content by newlines to get individual field definitions
	field_lines := struct_content.split('
')

	for line in field_lines {
		trimmed_line := line.trim_space()

		// Skip empty lines and comments
		if trimmed_line == '' || trimmed_line.starts_with('//') {
			continue
		}

		// Handle pub: or mut: prefixes
		mut field_def := trimmed_line
		if field_def.starts_with('pub:') || field_def.starts_with('mut:') {
			field_def = field_def.all_after(':').trim_space()
		}

		// Split by whitespace to separate field name and type
		parts := field_def.split_any(' 	')
		if parts.len < 2 {
			continue
		}

		field_name := parts[0]
		field_type := parts[1..].join(' ')

		// Handle attributes like @[json: 'name']
		if field_name.contains('@[') {
			continue
		}

		fields[field_name] = field_type
	}

	return fields
}
