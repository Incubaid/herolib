module doctree

import incubaid.herolib.core.texttools

// returns collection and file name from "collection:file" format
// works for file, image, page keys
pub fn key_parse(key string) !(string, string) {
	parts := key.split(':')
	if parts.len != 2 {
		return error('Invalid key format. Use "collection:file"')
	}
	col := texttools.name_fix(parts[0])
	file := texttools.name_fix(parts[1])
	return col, file
}

// ============================================================
// Helper function: normalize name while preserving .md extension handling
// ============================================================
pub fn name_fix(name string) string {
	mut result := name
	// Remove .md extension if present for processing
	if result.ends_with('.md') {
		result = result[0..result.len - 3]
	}
	// Apply name fixing
	result = strip_numeric_prefix(result)
	return texttools.name_fix(result)
}

// Strip numeric prefix from filename (e.g., "03_linux_installation" -> "linux_installation")
// Docusaurus automatically strips these prefixes from URLs
fn strip_numeric_prefix(name string) string {
	// Match pattern: digits followed by underscore at the start
	if name.len > 2 && name[0].is_digit() {
		for i := 1; i < name.len; i++ {
			if name[i] == `_` {
				// Found the underscore, return everything after it
				return name[i + 1..]
			}
			if !name[i].is_digit() {
				// Not a numeric prefix pattern, return as-is
				return name
			}
		}
	}
	return name
}
