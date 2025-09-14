module utils

// Helper function to extract code blocks from the response
pub fn extract_code_block(response string, identifier string, language string) string {
	// Find the start marker for the code block
	mut start_marker := '```${language}\n// ${identifier}'
	if language == '' {
		start_marker = '```\n// ${identifier}'
	}

	start_index := response.index(start_marker) or {
		// Try alternative format
		mut alt_marker := '```${language}\n${identifier}'
		if language == '' {
			alt_marker = '```\n${identifier}'
		}

		response.index(alt_marker) or { return '' }
	}

	// Find the end marker
	end_marker := '```'
	end_index := response.index_after(end_marker, start_index + start_marker.len) or { return '' }

	// Extract the content between the markers
	content_start := start_index + start_marker.len
	content := response[content_start..end_index].trim_space()

	return content
}
