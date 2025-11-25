module filemap

// parse_header robustly extracts block type and filename from header line
// Handles variable `=` count, spaces, and case-insensitivity
// Example: `  ===FILE: myfile.txt ===` → $(BlockKind.file, "myfile.txt")
fn parse_header(line string) !(BlockKind, string) {
	cleaned := line.trim_space()

	// Must have = and content
	if !cleaned.contains('=') {
		return BlockKind.end, ''
	}

	// Strip leading and trailing = (any count), preserving spaces between
	mut content := cleaned.trim_left('=').trim_space()
	content = content.trim_right('=').trim_space()

	if content.len == 0 {
		return BlockKind.end, ''
	}

	// Check for END marker
	if content.to_lower() == 'end' {
		return BlockKind.end, ''
	}

	// Parse FILE or FILECHANGE
	if content.contains(':') {
		kind_str := content.all_before(':').to_lower().trim_space()
		filename := content.all_after(':').trim_space()

		if filename.len < 1 {
			return error('Invalid filename: empty after colon')
		}

		match kind_str {
			'file' { return BlockKind.file, filename }
			'filechange' { return BlockKind.filechange, filename }
			else { return BlockKind.end, '' }
		}
	}

	return BlockKind.end, ''
}
