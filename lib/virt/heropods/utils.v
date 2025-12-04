module heropods

// Validate container name to prevent shell injection and path traversal
//
// Security validation that ensures container names:
// - Are not empty and not too long (max 64 chars)
// - Contain only alphanumeric characters, dashes, and underscores
// - Don't start with dash or underscore
// - Don't contain path traversal sequences
//
// This is critical for preventing command injection attacks since container
// names are used in shell commands throughout the module.
fn validate_container_name(name string) ! {
	if name == '' {
		return error('Container name cannot be empty')
	}
	if name.len > 64 {
		return error('Container name too long (max 64 characters)')
	}

	// Check if name contains only allowed characters: alphanumeric, dash, underscore
	allowed_chars := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_'
	if !name.contains_only(allowed_chars) {
		return error('Container name "${name}" contains invalid characters. Only alphanumeric characters, dashes, and underscores are allowed.')
	}

	if name.starts_with('-') || name.starts_with('_') {
		return error('Container name cannot start with dash or underscore')
	}

	// Prevent path traversal (redundant check but explicit for security)
	if name.contains('..') || name.contains('/') || name.contains('\\') {
		return error('Container name cannot contain path separators or ".."')
	}
}
