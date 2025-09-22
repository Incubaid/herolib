module heroserver

import rand

fn generate_request_example[T](model T) !string {
	mut field_parts := []string{} // Build JSON manually to avoid type conflicts

	for param in model {
		value := match param.type_info.to_lower() {
			'string', 'str', 'text' {
				'"${rand.string(10)}"'
			}
			'integer', 'int', 'number' {
				'${rand.intn(1000)!}'
			}
			'boolean', 'bool' {
				if rand.intn(2)! == 0 { 'false' } else { 'true' }
			}
			'array', '[]' {
				'[]'
			}
			'object' {
				'{}'
			}
			else {
				// handle generic cases like `[int]`, `[string]`, `map[string]int`, etc.
				if param.type_info.starts_with('[') {
					'[]'
				} else if param.type_info.starts_with('map') {
					'{}'
				} else {
					'"example_value"'
				}
			}
		}
		field_parts << '"${param.name}": ${value}'
	}

	return '{${field_parts.join(', ')}}'
}

fn generate_response_example[T](model T) !string {
	println('response model: ${model}')
	return 'xxxx'
}
