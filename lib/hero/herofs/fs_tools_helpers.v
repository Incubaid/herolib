module herofs

// Helper function to check if name matches include/exclude patterns
fn matches_pattern(name string, patterns []string) bool {
	if patterns.len == 0 {
		return true // No patterns means include everything
	}

	for pattern in patterns {
		if pattern.contains('*') {
			prefix := pattern.all_before('*')
			suffix := pattern.all_after('*')

			if prefix == '' && suffix == '' {
				return true // Pattern is just "*"
			} else if prefix == '' {
				if name.ends_with(suffix) {
					return true
				}
			} else if suffix == '' {
				if name.starts_with(prefix) {
					return true
				}
			} else {
				if name.starts_with(prefix) && name.ends_with(suffix) {
					return true
				}
			}
		} else if name == pattern {
			return true // Exact match
		}
	}

	return false
}

// Check if item should be included based on patterns
fn should_include(name string, include_patterns []string, exclude_patterns []string) bool {
	// First apply include patterns (if empty, include everything)
	if !matches_pattern(name, include_patterns) && include_patterns.len > 0 {
		return false
	}

	// Then apply exclude patterns
	if matches_pattern(name, exclude_patterns) && exclude_patterns.len > 0 {
		return false
	}

	return true
}

// Normalize path by removing trailing slashes and handling edge cases
fn normalize_path(path string) string {
	if path == '' || path == '/' {
		return '/'
	}
	return path.trim_right('/')
}

// Split path into directory and filename parts
fn split_path(path string) (string, string) {
	normalized := normalize_path(path)
	if normalized == '/' {
		return '/', ''
	}

	mut dir_path := normalized.all_before_last('/')
	filename := normalized.all_after_last('/')

	if dir_path == '' {
		dir_path = '/'
	}

	return dir_path, filename
}

// Get the parent path of a given path
fn parent_path(path string) string {
	normalized := normalize_path(path)
	if normalized == '/' {
		return '/'
	}

	parent := normalized.all_before_last('/')
	if parent == '' {
		return '/'
	}
	return parent
}

// Join path components
fn join_path(base string, component string) string {
	normalized_base := normalize_path(base)
	if normalized_base == '/' {
		return '/' + component
	}
	return normalized_base + '/' + component
}
