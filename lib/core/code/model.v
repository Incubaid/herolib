module code

// Code is a list of statements
// pub type Code = []CodeItem

pub type CodeItem = Alias
	| Comment
	| CustomCode
	| Function
	| Import
	| Struct
	| Sumtype
	| Interface
	| Enum

// item for adding custom code in
pub struct CustomCode {
pub:
	text string
}

pub struct Comment {
pub:
	text     string
	is_multi bool
}

pub struct Sumtype {
pub:
	name        string
	description string
	types       []Type
}

pub struct Enum {
pub mut:
	name        string
	description string
	is_pub      bool
	values      []EnumValue
}

pub struct EnumValue {
pub:
	name        string
	value       string
	description string
}

pub struct Attribute {
pub:
	name    string // [name]
	has_arg bool
	arg     string // [name: arg]
}
