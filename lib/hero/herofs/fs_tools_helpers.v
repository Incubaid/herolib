module herofs

import os

// join_path joins path components
pub fn join_path(base string, component string) string {
	if base == '/' {
		return '/${component}'
	}
	return '${base}/${component}'
}

// normalize_path normalizes a path
pub fn normalize_path(p string) string {
	return p.replace("'", '')
}

// should_include checks if a name should be included based on patterns
pub fn should_include(name string, include_patterns []string, exclude_patterns []string) bool {
	// Exclude based on exclude_patterns
	for pattern in exclude_patterns {
		if name.contains(pattern.replace('*', '')) {
			return false
		}
	}

	// If include_patterns is empty, include everything not excluded
	if include_patterns.len == 0 {
		return true
	}

	// Include based on include_patterns
	for pattern in include_patterns {
		if name.contains(pattern.replace('*', '')) {
			return true
		}
	}

	// If include_patterns is not empty and no pattern matched, exclude
	return false
}