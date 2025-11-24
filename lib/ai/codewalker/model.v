module codewalker

// BlockKind defines the type of block in parsed content
pub enum BlockKind {
	file
	filechange
	end
}

pub struct FMError {
pub:
	message  string
	linenr   int
	category string
	filename string
}

// ScopedIgnore handles directory-scoped .gitignore/.heroignore patterns
pub struct ScopedIgnore {
pub mut:
	// Map of directory -> list of patterns
	// Empty string key for root level patterns
	patterns map[string][]string
}

// Add patterns for a specific directory scope
pub fn (mut si ScopedIgnore) add_for_scope(scope string, patterns_text string) {
	mut scope_key := scope
	if scope == '' {
		scope_key = '/'
	}

	if scope_key !in si.patterns {
		si.patterns[scope_key] = []string{}
	}

	for line in patterns_text.split_into_lines() {
		line_trimmed := line.trim_space()
		if line_trimmed != '' && !line_trimmed.starts_with('#') {
			si.patterns[scope_key] << gitignore_pattern_to_regex(line_trimmed)
		}
	}
}

// Check if a relative path should be ignored
pub fn (si ScopedIgnore) is_ignored(relpath string) bool {
	// Check all scopes that could apply to this path
	path_parts := relpath.split('/')

	// Check root level patterns
	if '/' in si.patterns {
		for pattern in si.patterns['/'] {
			if relpath.match_regex(pattern) { // Use match_regex here
				return true
			}
		}
	}

	// Check directory-scoped patterns
	for i := 0; i < path_parts.len; i++ {
		scope := path_parts[..i].join('/')
		if scope != '' && scope in si.patterns {
			// Check if remaining path matches patterns in this scope
			remaining := path_parts[i..].join('/')
			for pattern in si.patterns[scope] {
				if remaining.match_regex(pattern) {
					return true
				}
			}
		}
	}

	return false
}
