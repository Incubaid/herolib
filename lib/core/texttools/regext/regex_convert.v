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

// wildcard_to_regex converts a wildcard pattern (e.g., "*.txt") to a regex pattern.
// This function does not add implicit ^ and $ anchors, allowing for substring matches.
fn wildcard_to_regex(wildcard_pattern string) string {
	mut regex_pattern := ''
	    for _, r in wildcard_pattern.runes() {
		match r {
			`*` {
				regex_pattern += '.*'
			}
			`?` {
				regex_pattern += '.'
			}
			`.`, `+`, `(`, `)`, `[`, `]`, `{`, `}`, `^`, `$`, `\\`, `|` {
				// Escape regex special characters
				regex_pattern += '\\' + r.str()
			}
			else {
				regex_pattern += r.str()
			}
		}
	}
	return regex_pattern
}
