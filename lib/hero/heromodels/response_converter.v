module heromodels

import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import json

// ResponseConverter provides generic conversion from internal models to RPC response format
pub struct ResponseConverter {
pub mut:
	db &db.DB @[skip; str: skip]
}

// Convert timestamp fields in a JSON string from int to string format
pub fn (mut self ResponseConverter) convert_timestamps_in_json(json_str string) !string {
	mut result := json_str

	// Find and replace timestamp patterns using simple string replacement
	timestamp_fields := ['created_at', 'updated_at', 'start_time', 'end_time', 'start_date',
		'end_date', 'due_date', 'deadline', 'last_activity']

	for field in timestamp_fields {
		// Look for patterns like: "created_at":	1759397869,
		// Use a more direct approach with string splitting
		lines := result.split('\n')
		mut new_lines := []string{}

		for line in lines {
			mut new_line := line
			if line.contains('"${field}":') {
				// Extract the timestamp value from this line
				parts := line.split('"${field}":')
				if parts.len >= 2 {
					// Get the part after the field name
					after_colon := parts[1].trim_space().trim('\t')

					// Find where the number ends (look for comma or closing brace)
					mut number_part := ''
					for ch in after_colon {
						if ch.is_digit() {
							number_part += ch.ascii_str()
						} else {
							break
						}
					}

					if number_part.len > 0 && number_part.is_int() {
						timestamp_val := number_part.i64()
						if timestamp_val > 0 {
							time_str := ourtime.new_from_epoch(u64(timestamp_val)).str()
							// Replace the number with quoted string
							new_line = line.replace('${number_part}', '"${time_str}"')
						}
					}
				}
			}
			new_lines << new_line
		}

		result = new_lines.join('\n')
	}

	return result
}

// Convert tags field in a JSON string from int to string array format
pub fn (mut self ResponseConverter) convert_tags_in_json(json_str string) !string {
	mut result := json_str

	// Look for patterns like: "tags":	0, or "tags": 123,
	// Handle both spaces and tabs after the colon
	patterns := ['"tags": ', '"tags":	', '"tags":']

	for pattern in patterns {
		if result.contains(pattern) {
			// Use line-by-line approach similar to timestamps
			lines := result.split('\n')
			mut new_lines := []string{}

			for line in lines {
				mut new_line := line
				if line.contains(pattern) {
					// Extract the tags value from this line
					parts := line.split(pattern)
					if parts.len >= 2 {
						// Get the part after "tags":
						after_colon := parts[1].trim_space().trim('\t')

						// Find where the number ends (look for comma or closing brace)
						mut number_part := ''
						for ch in after_colon {
							if ch.is_digit() {
								number_part += ch.ascii_str()
							} else {
								break
							}
						}

						if number_part.len > 0 && number_part.is_int() {
							tags_val := number_part.u32()
							if tags_val > 0 {
								// Convert tag ID to string array
								tags_strings := self.db.tags_to_strings(tags_val)!
								tags_json := json.encode(tags_strings)
								new_line = line.replace('${number_part}', '${tags_json}')
							} else {
								// Convert 0 to empty array
								new_line = line.replace('${number_part}', '[]')
							}
						}
					}
				}
				new_lines << new_line
			}

			result = new_lines.join('\n')
		}
	}

	return result
}

// Convert any model to RPC response format with string timestamps and tags
pub fn (mut self ResponseConverter) convert_model_to_response[T](model T) !string {
	// Encode the model to JSON first
	json_str := json.encode_pretty(model)

	// Convert timestamps to strings
	mut result := self.convert_timestamps_in_json(json_str)!

	// Convert tags to string arrays
	result = self.convert_tags_in_json(result)!

	return result
}

// Convert a list of models to RPC response format
pub fn (mut self ResponseConverter) convert_list_to_response[T](models []T) !string {
	mut converted_models := []string{}
	for model in models {
		converted_json := self.convert_model_to_response(model)!
		converted_models << converted_json
	}

	// Join the converted models into a JSON array
	return '[${converted_models.join(',')}]'
}
