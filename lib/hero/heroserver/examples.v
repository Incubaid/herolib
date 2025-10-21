module heroserver

import x.json2
import incubaid.herolib.schemas.jsonschema

// ============================================================================
// Constants
// ============================================================================

// max_example_depth controls maximum recursion depth for nested schema examples
// to prevent infinite loops and keep examples readable
const max_example_depth = 4

// max_props_shallow controls maximum number of properties shown in object examples
// at shallow nesting levels (depth <= 2)
const max_props_shallow = 10

// max_props_deep controls maximum number of properties shown in object examples
// at deep nesting levels (depth > 2) to keep examples concise
const max_props_deep = 3

// ============================================================================
// JSON Formatting
// ============================================================================

// prettify_json takes a compact JSON string and returns it with pretty formatting.
// Uses V's built-in json2 module with 3-space indentation for consistent formatting.
// Falls back to the original string if parsing fails.
fn prettify_json(compact_json string) string {
	parsed := json2.decode[json2.Any](compact_json) or { return compact_json }
	return json2.encode(parsed, prettify: true, indent_string: '   ')
}

// ============================================================================
// Request Example Generation
// ============================================================================

fn generate_request_example[T](model T) !string {
	mut field_parts := []string{} // Build JSON manually to avoid type conflicts

	for param in model {
		// Use schema-generated examples (already populated by extract_example_from_schema)
		// The example field contains dynamically generated values based on actual schema
		if param.example.len == 0 || param.example.trim_space() == '' {
			return error('Parameter "${param.name}" has no example - schema may be missing')
		}
		field_parts << '"${param.name}":${param.example}'
	}

	// Build compact JSON string
	if field_parts.len == 0 {
		return '{}'
	}

	compact := '{${field_parts.join(',')}}'

	// Prettify using V's built-in json2 formatter
	return prettify_json(compact)
}

// ============================================================================
// Schema-based Example Generation
// ============================================================================
// These functions generate examples from JSON Schema objects (used for response examples)

// extract_example_from_schema extracts or generates an example value from a SchemaRef.
// After schema inflation, all references should be resolved to Schema objects.
// This function intelligently generates examples based on schema type and constraints.
// Returns a pretty-formatted JSON string for display in documentation.
pub fn extract_example_from_schema(schema_ref jsonschema.SchemaRef) string {
	compact := generate_example_from_schema_with_depth(schema_ref, 0, map[string]bool{})
	return prettify_json(compact)
}

// generate_example_from_schema creates an example value for a parameter or result
pub fn generate_example_from_schema(schema_ref jsonschema.SchemaRef, param_name string) string {
	compact := generate_example_from_schema_with_depth(schema_ref, 0, map[string]bool{})
	return prettify_json(compact)
}

// generate_example_from_schema_with_depth recursively generates example values with depth limiting.
// Prevents infinite recursion from circular references by tracking depth and visited schemas.
// Max depth is controlled by max_example_depth constant to keep examples readable while showing structure.
fn generate_example_from_schema_with_depth(schema_ref jsonschema.SchemaRef, depth int, visited map[string]bool) string {
	// Depth limit to prevent infinite recursion
	// Return null for deeply nested structures to keep JSON valid
	if depth > max_example_depth {
		return 'null'
	}

	schema := match schema_ref {
		jsonschema.Schema {
			schema_ref
		}
		jsonschema.Reference {
			// After inflation, references should be resolved
			// If we still encounter a reference, return a placeholder
			return '"<unresolved_reference>"'
		}
	}

	// Check if schema has an explicit example - use it if available
	// Note: json2.Any.str() returns '[]' or '{}' for empty/null values, so we filter those out
	// We use json_str() instead of str() to get properly JSON-encoded values (with quotes for strings)
	example_str := schema.example.json_str()
	if example_str != '' && example_str != '[]' && example_str != '{}' && example_str != 'null' {
		return example_str
	}

	// Track visited schemas by their ID to prevent circular references
	schema_id := schema.id
	if schema_id != '' {
		if schema_id in visited {
			return 'null'
		}
	}

	// Create a new visited map for this branch
	mut new_visited := visited.clone()
	if schema_id != '' {
		new_visited[schema_id] = true
	}

	// Infer type from schema structure if not explicitly set
	schema_type := if schema.typ != '' {
		schema.typ
	} else if schema.properties.len > 0 {
		'object'
	} else if schema.items != none {
		'array'
	} else {
		''
	}

	// Generate example based on schema type
	match schema_type {
		'string' {
			// Use format hints if available
			return match schema.format {
				'date-time' {
					'"2024-01-15T10:30:00Z"'
				}
				'date' {
					'"2024-01-15"'
				}
				'time' {
					'"10:30:00"'
				}
				'email' {
					'"user@example.com"'
				}
				'uri', 'url' {
					'"https://example.com"'
				}
				'uuid' {
					'"550e8400-e29b-41d4-a716-446655440000"'
				}
				'ipv4' {
					'"192.168.1.1"'
				}
				'ipv6' {
					'"2001:0db8:85a3:0000:0000:8a2e:0370:7334"'
				}
				'hostname' {
					'"example.com"'
				}
				else {
					// Use schema title or description as hint, or generic placeholder
					if schema.title != '' {
						'"${schema.title}"'
					} else if schema.description != '' && schema.description.len < 50 {
						'"${schema.description}"'
					} else {
						'"Sample Text"'
					}
				}
			}
		}
		'integer', 'number' {
			// Use minimum/maximum if specified
			if schema.minimum > 0 {
				return schema.minimum.str()
			}
			if schema.maximum > 0 {
				return schema.maximum.str()
			}
			return '42'
		}
		'boolean' {
			return 'true'
		}
		'null' {
			return 'null'
		}
		'array' {
			// Generate array with one example item (compact format)
			if items := schema.items {
				item_example := if items is jsonschema.SchemaRef {
					generate_example_from_schema_with_depth(items, depth + 1, new_visited)
				} else if items is []jsonschema.SchemaRef {
					if items.len > 0 {
						generate_example_from_schema_with_depth(items[0], depth + 1, new_visited)
					} else {
						'null'
					}
				} else {
					'null'
				}
				return '[${item_example}]'
			}
			return '[]'
		}
		'object' {
			// Generate object with all properties (compact format)
			if schema.properties.len > 0 {
				mut props := []string{}
				// Limit number of properties shown at deep levels
				max_props := if depth > 2 { max_props_deep } else { max_props_shallow }
				mut count := 0

				for prop_name, prop_schema in schema.properties {
					if count >= max_props {
						break
					}
					prop_example := generate_example_from_schema_with_depth(prop_schema,
						depth + 1, new_visited)
					props << '"${prop_name}":${prop_example}'
					count++
				}

				if props.len > 0 {
					return '{${props.join(',')}}'
				}
			}
			// Handle additionalProperties
			if additional := schema.additional_properties {
				value_example := generate_example_from_schema_with_depth(additional, depth + 1,
					new_visited)
				return '{"key":${value_example}}'
			}
			return '{}'
		}
		else {
			// Handle oneOf - use first option
			if schema.one_of.len > 0 {
				return generate_example_from_schema_with_depth(schema.one_of[0], depth + 1,
					new_visited)
			}
			// Unknown type
			return 'null'
		}
	}
}
