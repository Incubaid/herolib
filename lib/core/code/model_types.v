module code

struct Float {
	bytes int
}

// Integer types
pub const type_i8 = Integer{
	bytes: 8
}

pub const type_u8 = Integer{
	bytes:  8
	signed: false
}

pub const type_i16 = Integer{
	bytes: 16
}

pub const type_u16 = Integer{
	bytes:  16
	signed: false
}

pub const type_i32 = Integer{
	bytes: 32
}

pub const type_u32 = Integer{
	bytes:  32
	signed: false
}

pub const type_i64 = Integer{
	bytes: 64
}

pub const type_u64 = Integer{
	bytes:  64
	signed: false
}

// Floating-point types
pub const type_f32 = Float{
	bytes: 32
}

pub const type_f64 = Float{
	bytes: 64
}

pub type Type = Void
	| Map
	| Array
	| Object
	| Result
	| Integer
	| Alias
	| String
	| Boolean
	| Function

pub struct Alias {
pub:
	name        string
	description string
	typ         Type
}

pub struct Boolean {}

pub struct Void {}

pub struct Integer {
	bytes  u8
	signed bool = true
}

pub fn type_from_symbol(symbol_ string) Type {
	mut symbol := symbol_.trim_space()
	if symbol.starts_with('[]') {
		return Array{type_from_symbol(symbol.all_after('[]'))}
	} else if symbol == 'int' {
		return Integer{}
	} else if symbol == 'string' {
		return String{}
	} else if symbol == 'bool' || symbol == 'boolean' {
		return Boolean{}
	}
	return Object{symbol}
}

pub fn (t Array) symbol() string {
	return '[]${t.typ.symbol()}'
}

pub fn (t Object) symbol() string {
	return t.name
}

pub fn (t Result) symbol() string {
	return '!${t.typ.symbol()}'
}

pub fn (t Integer) symbol() string {
	mut str := ''
	if !t.signed {
		str += 'u'
	}
	if t.bytes != 0 {
		return '${str}${t.bytes}'
	} else {
		return '${str}int'
	}
}

pub fn (t Alias) symbol() string {
	return t.name
}

pub fn (t String) symbol() string {
	return 'string'
}

pub fn (t Boolean) symbol() string {
	return 'bool'
}

pub fn (t Map) symbol() string {
	return 'map[string]${t.typ.symbol()}'
}

pub fn (t Function) symbol() string {
	return 'fn ()'
}

pub fn (t Void) symbol() string {
	return ''
}

pub fn (t Type) symbol() string {
	return match t {
		Array { t.symbol() }
		Object { t.symbol() }
		Result { t.symbol() }
		Integer { t.symbol() }
		Alias { t.symbol() }
		String { t.symbol() }
		Boolean { t.symbol() }
		Map { t.symbol() }
		Function { t.symbol() }
		Void { t.symbol() }
	}
}

pub struct String {}

pub struct Array {
pub:
	typ Type
}

pub struct Map {
pub:
	typ Type
}

pub struct Object {
pub:
	name string
}

pub struct Result {
pub:
	typ Type
}

pub fn (t Type) typescript() string {
	return match t {
		Map { 'Record<string, ${t.typ.typescript()}>' }
		Array { '${t.typ.typescript()}[]' }
		Object { t.name }
		Result { '${t.typ.typescript()}' }
		Boolean { 'boolean' }
		Integer { 'number' }
		Alias { t.name }
		String { 'string' }
		Function { 'func' }
		Void { '' }
	}
}

// TODO: enfore that cant be both mutable and shared
pub fn (t Type) vgen() string {
	return t.symbol()
}

pub fn (t Type) empty_value() string {
	return match t {
		Map {
			'{}'
		}
		Array {
			'[]${t.typ.symbol()}{}'
		}
		Object {
			if t.name != '' {
				'${t.name}{}'
			} else {
				''
			}
		}
		Result {
			t.typ.empty_value()
		}
		Boolean {
			'false'
		}
		Integer {
			'0'
		}
		Alias {
			''
		}
		String {
			"''"
		}
		Function {
			''
		}
		Void {
			''
		}
	}
}

// parse_type parses a type string into a Type struct
pub fn parse_type(type_str string) Type {
	mut type_str_cleaned := type_str.trim_space()

	// Remove inline comments
	if type_str_cleaned.contains('//') {
		type_str_cleaned = type_str_cleaned.all_before('//').trim_space()
	}

	// Remove default values
	if type_str_cleaned.contains('=') {
		type_str_cleaned = type_str_cleaned.all_before('=').trim_space()
	}

	// Handle struct definitions by extracting just the struct name
	if type_str_cleaned.contains('struct ') {
		lines := type_str_cleaned.split_into_lines()
		for line in lines {
			if line.contains('struct ') {
				mut struct_name := ''
				if line.contains('pub struct ') {
					struct_name = line.all_after('pub struct ').all_before('{')
				} else {
					struct_name = line.all_after('struct ').all_before('{')
				}
				struct_name = struct_name.trim_space()
				return Object{struct_name}
			}
		}
	}

	// Check for simple types first
	if type_str_cleaned == 'string' {
		return String{}
	} else if type_str_cleaned == 'bool' || type_str_cleaned == 'boolean' {
		return Boolean{}
	} else if type_str_cleaned == 'int' {
		return Integer{}
	} else if type_str_cleaned == 'u8' {
		return Integer{
			bytes:  8
			signed: false
		}
	} else if type_str_cleaned == 'u16' {
		return Integer{
			bytes:  16
			signed: false
		}
	} else if type_str_cleaned == 'u32' {
		return Integer{
			bytes:  32
			signed: false
		}
	} else if type_str_cleaned == 'u64' {
		return Integer{
			bytes:  64
			signed: false
		}
	} else if type_str_cleaned == 'i8' {
		return Integer{
			bytes: 8
		}
	} else if type_str_cleaned == 'i16' {
		return Integer{
			bytes: 16
		}
	} else if type_str_cleaned == 'i32' {
		return Integer{
			bytes: 32
		}
	} else if type_str_cleaned == 'i64' {
		return Integer{
			bytes: 64
		}
	}

	// Check for array types
	if type_str_cleaned.starts_with('[]') {
		elem_type := type_str_cleaned.all_after('[]')
		return Array{parse_type(elem_type)}
	}

	// Check for map types
	if type_str_cleaned.starts_with('map[') && type_str_cleaned.contains(']') {
		value_type := type_str_cleaned.all_after(']')
		return Map{parse_type(value_type)}
	}

	// Check for result types
	if type_str_cleaned.starts_with('!') {
		result_type := type_str_cleaned.all_after('!')
		return Result{parse_type(result_type)}
	}

	// If no other type matches, treat as an object/struct type
	return Object{type_str_cleaned}
}
