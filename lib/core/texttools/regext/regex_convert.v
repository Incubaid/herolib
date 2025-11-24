module regext

// escape_regex_chars escapes special regex metacharacters in a string
// This makes a literal string safe to use in regex patterns.
// Examples:
//   "file.txt" -> "file\.txt"
//   "a[123]" -> "a\[123\]"
pub fn escape_regex_chars(s string) string {
	mut result := ''
	for ch in s {
		match ch {
			`.`, `^`, `$`, `*`, `+`, `?`, `{`, `}`, `[`, `]`, `\\`, `|`, `(`, `)` {
				result += '\\'
			}
			else {}
		}
		result += ch.ascii_str()
	}
	return result
}

// wildcard_to_regex converts a wildcard pattern to a regex pattern
// Conversion rules:
// - `*` becomes `.*` (matches any sequence)
// - literal text is escaped (special regex chars are backslash-escaped)
// - patterns without `*` return a substring matcher
//
// Examples:
//   "*.txt" -> ".*\.txt" (matches any filename ending with .txt)
//   "test*" -> "test.*" (matches anything starting with test)
//   "config" -> ".*config.*" (matches anything containing config)
//   "file.log" -> ".*file\.log.*" (matches anything containing file.log)
pub fn wildcard_to_regex(pattern string) string {
	if !pattern.contains('*') {
		// No wildcards: match substring anywhere
		return '.*' + escape_regex_chars(pattern) + '.*'
	}

	mut result := ''
	mut i := 0
	for i < pattern.len {
		if pattern[i] == `*` {
			result += '.*'
			i++
		} else {
			// Find next * or end of string
			mut j := i
			for j < pattern.len && pattern[j] != `*` {
				j++
			}
			// Escape special regex chars in literal part
			literal := pattern[i..j]
			result += escape_regex_chars(literal)
			i = j
		}
	}
	return result
}
