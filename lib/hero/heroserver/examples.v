module heroserver

import rand

fn generate_request_example[T](model T) !string {
	mut field_parts := []string{} // Build JSON manually to avoid type conflicts

	for param in model {
		// Prioritize user-provided examples over generated ones
		// Check for meaningful examples (not empty, not just [], not just {})
		value := if param.example.len > 0 && param.example != '[]' && param.example != '{}'
			&& param.example.trim_space() != '' {
			param.example
		} else {
			generate_example_value(param.type_info)!
		}
		field_parts << '"${param.name}": ${value}'
	}

	return '{${field_parts.join(', ')}}'
}

// Generate dynamic example values based on type
fn generate_example_value(type_info string) !string {
	type_lower := type_info.to_lower()

	// Handle array types first (including array[type] format)
	if type_lower.starts_with('array') || type_lower.starts_with('[') {
		return generate_array_example(type_info)!
	}

	// Handle object types (including object[type] format)
	if type_lower.starts_with('object') {
		return if type_info.contains('[') {
			generate_map_example(type_info)!
		} else {
			generate_object_example()!
		}
	}

	// Handle basic types
	return match type_lower {
		'string', 'str', 'text' {
			'"${rand.string(8)}"'
		}
		'integer', 'int', 'number' {
			'${rand.intn(1000)!}'
		}
		'boolean', 'bool' {
			if rand.intn(2)! == 0 {
				'false'
			} else {
				'true'
			}
		}
		else {
			// Handle other complex types like map[string]int, etc.
			if type_info.contains('map') || type_info.starts_with('map[') {
				generate_map_example(type_info)!
			} else {
				'"example_value"'
			}
		}
	}
}

// Generate example array based on type
fn generate_array_example(type_info string) !string {
	// Extract item type from array notation: array[integer] -> integer
	item_type := if type_info.contains('[') && type_info.contains(']') {
		start := type_info.index('[') or { 0 } + 1
		end := type_info.last_index(']') or { type_info.len }
		if start < end {
			type_info[start..end]
		} else {
			'string'
		}
	} else {
		'string' // default for plain "array" type
	}

	// Generate 2-3 sample items based on the item type
	count := rand.intn(2)! + 2 // 2 or 3 items
	mut items := []string{}
	for _ in 0 .. count {
		items << generate_example_value(item_type)!
	}
	return '[${items.join(', ')}]'
}

// Generate example map/object
fn generate_map_example(type_info string) !string {
	// Extract value type from map notation: map[string]int -> int
	value_type := if type_info.contains(']') {
		parts := type_info.split(']')
		if parts.len > 1 {
			parts[1]
		} else {
			'string'
		}
	} else {
		'string' // default
	}

	// Generate 2-3 sample key-value pairs
	count := rand.intn(2)! + 2 // 2 or 3 pairs
	mut pairs := []string{}
	for i in 0 .. count {
		key := '"key${i + 1}"'
		value := generate_example_value(value_type)!
		pairs << '${key}: ${value}'
	}
	return '{${pairs.join(', ')}}'
}

// Generate generic object example
fn generate_object_example() !string {
	sample_props := [
		'"id": ${rand.intn(1000)!}',
		'"name": "${rand.string(6)}"',
		'"active": ${if rand.intn(2)! == 0 { 'false' } else { 'true' }}',
	]
	return '{${sample_props.join(', ')}}'
}

fn generate_response_example[T](model T) !string {
	println('response model: ${model}')
	return 'xxxx'
}
