module codeparser

import incubaid.herolib.core.code

// filter_structs filters structs using a predicate function
// 
// Args:
//   predicate - function that returns true for structs to include
//   module - optional module filter
pub fn (parser CodeParser) filter_structs(predicate: fn(code.Struct) bool, module: string = '') []code.Struct {
	structs := parser.list_structs(module)
	return structs.filter(predicate(it))
}

// filter_functions filters functions using a predicate function
pub fn (parser CodeParser) filter_functions(predicate: fn(code.Function) bool, module: string = '') []code.Function {
	functions := parser.list_functions(module)
	return functions.filter(predicate(it))
}

// filter_public_structs returns only public structs
pub fn (parser CodeParser) filter_public_structs(module: string = '') []code.Struct {
	return parser.filter_structs(fn (s code.Struct) bool {
		return s.is_pub
	}, module)
}

// filter_public_functions returns only public functions
pub fn (parser CodeParser) filter_public_functions(module: string = '') []code.Function {
	return parser.filter_functions(fn (f code.Function) bool {
		return f.is_pub
	}, module)
}

// filter_functions_with_receiver returns functions that have a receiver (methods)
pub fn (parser CodeParser) filter_functions_with_receiver(module: string = '') []code.Function {
	return parser.filter_functions(fn (f code.Function) bool {
		return f.receiver.name != ''
	}, module)
}

// filter_functions_returning_error returns functions that return error type (${ error type with ! })
pub fn (parser CodeParser) filter_functions_returning_error(module: string = '') []code.Function {
	return parser.filter_functions(fn (f code.Function) bool {
		return f.has_return || f.result.is_result
	}, module)
}

// filter_structs_with_field returns structs that have a field of a specific type
pub fn (parser CodeParser) filter_structs_with_field(field_type: string, module: string = '') []code.Struct {
	return parser.filter_structs(fn [field_type] (s code.Struct) bool {
		for field in s.fields {
			if field.typ.symbol() == field_type {
				return true
			}
		}
		return false
	}, module)
}

// filter_by_name_pattern returns items matching a name pattern (substring match)
pub fn (parser CodeParser) filter_structs_by_name(pattern: string, module: string = '') []code.Struct {
	return parser.filter_structs(fn [pattern] (s code.Struct) bool {
		return s.name.contains(pattern)
	}, module)
}

// filter_functions_by_name returns functions matching a name pattern
pub fn (parser CodeParser) filter_functions_by_name(pattern: string, module: string = '') []code.Function {
	return parser.filter_functions(fn [pattern] (f code.Function) bool {
		return f.name.contains(pattern)
	}, module)
}