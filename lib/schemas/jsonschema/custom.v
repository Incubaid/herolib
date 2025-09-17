module jsonschema

pub fn (schema Schema) type_() string {
	return schema.typ.str()
}

pub fn (schema Schema) example_value() string {
	return ''
}