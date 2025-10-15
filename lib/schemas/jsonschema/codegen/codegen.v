module codegen

import log
import incubaid.herolib.develop.codetools as code { Alias, Array, Attribute, CodeItem, Object, Struct, StructField, Type, type_from_symbol }
import incubaid.herolib.schemas.jsonschema { Reference, Schema, SchemaRef }

const vtypes = {
	'integer': 'int'
	'number':  'int'
	'string':  'string'
	'u32':     'u32'
	'boolean': 'bool'
}

pub fn schema_to_v(schema Schema) string {
	module_name := 'schema.title.'
	structs := schema_to_structs(schema)
	// todo: report bug: return $tmpl(...)
	encoded := $tmpl('templates/schema.vtemplate')
	return encoded
}

// schema_to_structs encodes a schema into V structs.
// if a schema has nested object type schemas or defines object type schemas,
// recursively encodes object type schemas and pushes to the array of structs.
// returns an array of schemas that have been encoded into V structs.
pub fn schema_to_structs(schema Schema) []string {
	mut schemas := []string{}
	mut properties := ''

	// loop over properties
	for name, property_ in schema.properties {
		mut property := Schema{}
		mut typesymbol := ''

		if property_ is Reference {
			// if reference, set typesymbol as reference name
			ref := property_ as Reference
			typesymbol = ref_to_symbol(ref)
		} else {
			property = property_ as Schema
			typesymbol = schema_to_type(property).symbol()
			// recursively encode property if object
			// todo: handle duplicates
			if property.typ == 'object' {
				structs := schema_to_structs(property)
				schemas << structs
			}
		}

		properties += '\n\t${name} ${typesymbol}'
		if name in schema.required {
			properties += ' @[required]'
		}
	}
	schemas << $tmpl('templates/struct.vtemplate')
	return schemas
}

// schema_to_type generates a typesymbol for the schema
pub fn schema_to_type(schema Schema) Type {
	if schema.typ == 'null' {
		Type{}
	}
	mut property_str := ''
	return match schema.typ {
		'object' {
			if schema.title == '' {
				panic('Object schemas must define a title. ${schema}')
			}
			if schema.properties.len == 0 {
				if additional_props := schema.additional_properties {
					code.Map{code.String{}}
				} else {
					Object{schema.title}
				}
			} else {
				Object{schema.title}
			}
		}
		'array' {
			// todo: handle multiple item schemas
			if items := schema.items {
				if items is []SchemaRef {
					panic('items of type []SchemaRef not implemented')
				}
				Array{
					typ: schemaref_to_type(items as SchemaRef)
				}
			} else {
				panic('items should not be none for arrays')
			}
		}
		else {
			if schema.typ == 'integer' && schema.format != '' {
				match schema.format {
					'int8' { code.type_i8 }
					'uint8' { code.type_u8 }
					'int16' { code.type_i16 }
					'uint16' { code.type_u16 }
					'int32' { code.type_i32 }
					'uint32' { code.type_u32 }
					'int64' { code.type_i64 }
					'uint64' { code.type_u64 }
					else { code.Integer{} } // Default to 'int' if the format doesn't match any known type
				}
			} else if schema.typ in vtypes.keys() {
				type_from_symbol(vtypes[schema.typ])
			} else if schema.title != '' {
				type_from_symbol(schema.title)
			} else {
				panic('unknown type `${schema.typ}` ')
			}
		}
	}
}

pub fn schema_to_code(schema Schema) CodeItem {
	if schema.typ == 'object' {
		return CodeItem(schema_to_struct(schema))
	}
	if schema.typ in vtypes {
		return Alias{
			name: schema.title
			typ:  type_from_symbol(vtypes[schema.typ])
		}
	}
	if schema.typ == 'array' {
		if items := schema.items {
			if items is SchemaRef {
				if items is Schema {
					items_schema := items as Schema
					return Alias{
						name: schema.title
						typ:  type_from_symbol('[]${items_schema.typ}')
					}
				} else if items is Reference {
					items_ref := items as Reference
					return Alias{
						name: schema.title
						typ:  type_from_symbol('[]${ref_to_symbol(items_ref)}')
					}
				}
			}
		} else {
			panic('items of type []SchemaRef not implemented')
		}
	}
	panic('Schema type ${schema.typ} not supported for code generation')
}

pub fn schema_to_struct(schema Schema) Struct {
	mut fields := []StructField{}

	for key, val in schema.properties {
		mut field := ref_to_field(val, key)
		if field.name in schema.required {
			field.attrs << Attribute{
				name: 'required'
			}
		}
		fields << field
	}

	return Struct{
		name:        schema.title
		description: schema.description
		fields:      fields
		is_pub:      true
	}
}

pub fn ref_to_field(schema_ref SchemaRef, name string) StructField {
	if schema_ref is Reference {
		return StructField{
			name: name
			typ:  type_from_symbol(ref_to_symbol(schema_ref))
		}
	} else if schema_ref is Schema {
		mut field := StructField{
			name:        name
			description: schema_ref.description
		}
		if schema_ref.typ == 'object' || schema_ref.typ == 'array' {
			field.typ = schemaref_to_type(schema_ref)
			return field
		} else if schema_ref.typ in vtypes {
			field.typ = type_from_symbol(vtypes[schema_ref.typ])
			return field
		}
		panic('Schema type ${schema_ref.typ} not supported for code generation')
	}
	panic('Schema type not supported for code generation')
}

pub fn schemaref_to_type(schema_ref SchemaRef) Type {
	return if schema_ref is Reference {
		ref_to_type_from_reference(schema_ref as Reference)
	} else {
		schema_to_type(schema_ref as Schema)
	}
}

pub fn ref_to_symbol(reference Reference) string {
	return reference.ref.all_after_last('/')
}

pub fn ref_to_type_from_reference(reference Reference) Type {
	return type_from_symbol(ref_to_symbol(reference))
}
