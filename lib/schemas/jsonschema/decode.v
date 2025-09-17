module jsonschema

import x.json2 { Any }
import json

// decode parses a JSON Schema string into a Schema struct.
// Handles complex fields like properties, additionalProperties, items, and examples
// that require custom parsing beyond standard JSON decoding.
pub fn decode(data string) !Schema {
	schema_map := json2.raw_decode(data)!.as_map()
	mut schema := json.decode(Schema, data)!

	// Process fields that require custom decoding
	for key, value in schema_map {
		if key == 'properties' {
			schema.properties = decode_schemaref_map(value.as_map())!
		} else if key == 'additionalProperties' {
			schema.additional_properties = decode_schemaref(value.as_map())!
		} else if key == 'items' {
			schema.items = decode_items(value)!
		} else if key == 'example' {
			// Manually handle example field since it's marked with @[json: '-'] in the Schema struct
			schema.example = value
		}
	}
	return schema
}

pub fn decode_items(data Any) !Items {
	if data.str().starts_with('{') {
		return decode_schemaref(data.as_map())!
	}
	if !data.str().starts_with('[') {
		return error('items field must either be list of schemarefs or a schemaref')
	}

	mut items := []SchemaRef{}
	for val in data.arr() {
		items << decode_schemaref(val.as_map())!
	}
	return items
}

pub fn decode_schemaref_map(data_map map[string]Any) !map[string]SchemaRef {
	mut schemaref_map := map[string]SchemaRef{}
	for key, val in data_map {
		schemaref_map[key] = decode_schemaref(val.as_map())!
	}
	return schemaref_map
}

// decode_schemaref parses a map into either a Schema or Reference.
// Handles both direct schema definitions and $ref references to external schemas.
pub fn decode_schemaref(data_map map[string]Any) !SchemaRef {
	if ref := data_map['\$ref'] {
		return Reference{
			ref: ref.str()
		}
	}
	// Convert map back to JSON string for proper schema decoding with custom field handling
	json_str := json2.encode(data_map)
	return decode(json_str)!
}
