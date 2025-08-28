module sshagent

import os
import freeflowuniverse.herolib.core.texttools

// Security validation functions for SSH agent operations

// validate_key_name ensures SSH key names are safe and follow conventions
pub fn validate_key_name(name string) !string {
	if name.len == 0 {
		return error('SSH key name cannot be empty')
	}

	if name.len > 255 {
		return error('SSH key name too long (max 255 characters)')
	}

	// Check for dangerous characters
	dangerous_chars := ['/', '\\', '..', '~', '$', '`', ';', '|', '&', '>', '<', '*', '?', '[',
		']', '{', '}', '(', ')', '"', "'", ' ']
	for dangerous_char in dangerous_chars {
		if name.contains(dangerous_char) {
			return error('SSH key name contains invalid character: ${dangerous_char}')
		}
	}

	// Ensure it starts with alphanumeric
	if !name[0].is_alnum() {
		return error('SSH key name must start with alphanumeric character')
	}

	return texttools.name_fix(name)
}

// validate_private_key checks if the provided string is a valid SSH private key
pub fn validate_private_key(privkey string) !string {
	if privkey.len == 0 {
		return error('Private key cannot be empty')
	}

	// Check for valid private key headers
	valid_headers := [
		'-----BEGIN OPENSSH PRIVATE KEY-----',
		'-----BEGIN RSA PRIVATE KEY-----',
		'-----BEGIN DSA PRIVATE KEY-----',
		'-----BEGIN EC PRIVATE KEY-----',
		'-----BEGIN PRIVATE KEY-----',
	]

	mut has_valid_header := false
	for header in valid_headers {
		if privkey.contains(header) {
			has_valid_header = true
			break
		}
	}

	if !has_valid_header {
		return error('Invalid private key format - missing valid header')
	}

	// Check for corresponding footer
	valid_footers := [
		'-----END OPENSSH PRIVATE KEY-----',
		'-----END RSA PRIVATE KEY-----',
		'-----END DSA PRIVATE KEY-----',
		'-----END EC PRIVATE KEY-----',
		'-----END PRIVATE KEY-----',
	]

	mut has_valid_footer := false
	for footer in valid_footers {
		if privkey.contains(footer) {
			has_valid_footer = true
			break
		}
	}

	if !has_valid_footer {
		return error('Invalid private key format - missing valid footer')
	}

	// Basic length check (private keys should be substantial)
	if privkey.len < 200 {
		return error('Private key appears to be too short')
	}

	return privkey
}

// validate_file_path ensures file paths are safe and within expected directories
pub fn validate_file_path(path string, base_dir string) !string {
	if path.len == 0 {
		return error('File path cannot be empty')
	}

	// Resolve absolute path
	abs_path := os.abs_path(path)
	abs_base := os.abs_path(base_dir)

	// Ensure path is within base directory (prevent directory traversal)
	if !abs_path.starts_with(abs_base) {
		return error('File path outside of allowed directory: ${path}')
	}

	// Check for dangerous path components
	dangerous_components := ['..', './', '~/', '$']
	for component in dangerous_components {
		if path.contains(component) {
			return error('File path contains dangerous component: ${component}')
		}
	}

	return abs_path
}

// secure_file_permissions sets appropriate permissions for SSH key files
pub fn secure_file_permissions(file_path string, is_private bool) ! {
	if !os.exists(file_path) {
		return error('File does not exist: ${file_path}')
	}

	if is_private {
		// Private keys should be readable/writable only by owner
		os.chmod(file_path, 0o600)!
	} else {
		// Public keys can be readable by others
		os.chmod(file_path, 0o644)!
	}
}

// get_secure_socket_path returns a secure socket path for the given user
pub fn get_secure_socket_path(user string) !string {
	if user.len == 0 {
		return error('User cannot be empty')
	}

	// Validate user name
	validated_user := validate_key_name(user)!

	// Use more secure temporary directory if available
	mut temp_dir := '/tmp'

	// Check for user-specific temp directory
	user_temp := os.getenv('XDG_RUNTIME_DIR')
	if user_temp.len > 0 && os.exists(user_temp) {
		temp_dir = user_temp
	}

	socket_path := '${temp_dir}/ssh-agent-${validated_user}.sock'

	// Ensure parent directory exists and has correct permissions
	parent_dir := os.dir(socket_path)
	if !os.exists(parent_dir) {
		os.mkdir_all(parent_dir)!
		os.chmod(parent_dir, 0o700)! // Only owner can access
	}

	return socket_path
}

// sanitize_environment_variables cleans SSH-related environment variables
pub fn sanitize_environment_variables() {
	// List of SSH-related environment variables that might need cleaning
	ssh_env_vars := ['SSH_AUTH_SOCK', 'SSH_AGENT_PID', 'SSH_CLIENT', 'SSH_CONNECTION']

	for var in ssh_env_vars {
		env_val := os.getenv(var)
		if env_val.len > 0 {
			// Basic validation of environment variable values
			if env_val.contains('..') || env_val.contains(';') || env_val.contains('|') {
				// Unset potentially dangerous environment variables
				os.unsetenv(var)
			}
		}
	}
}

// validate_passphrase checks passphrase strength (basic validation)
pub fn validate_passphrase(passphrase string) !string {
	// Allow empty passphrase (user choice)
	if passphrase.len == 0 {
		return passphrase
	}

	// Basic length check
	if passphrase.len < 8 {
		return error('Passphrase should be at least 8 characters long')
	}

	// Check for common weak passphrases
	weak_passphrases := ['password', '12345678', 'qwerty', 'admin', 'root', 'test']
	for weak in weak_passphrases {
		if passphrase.to_lower() == weak {
			return error('Passphrase is too weak - avoid common passwords')
		}
	}

	return passphrase
}

// check_system_security performs basic system security checks
pub fn check_system_security() !map[string]string {
	mut security_status := map[string]string{}

	// Check if running as root (generally not recommended)
	if os.getuid() == 0 {
		security_status['root_user'] = 'WARNING: Running as root user'
	} else {
		security_status['root_user'] = 'OK: Not running as root'
	}

	// Check SSH directory permissions
	ssh_dir := '${os.home_dir()}/.ssh'
	if os.exists(ssh_dir) {
		// Get directory permissions (simplified check)
		if os.is_readable(ssh_dir) && os.is_writable(ssh_dir) {
			security_status['ssh_dir_permissions'] = 'OK: SSH directory accessible'
		} else {
			security_status['ssh_dir_permissions'] = 'WARNING: SSH directory permission issues'
		}
	} else {
		security_status['ssh_dir_permissions'] = 'INFO: SSH directory does not exist'
	}

	// Check for SSH agent processes
	user := os.getenv('USER')
	res := os.execute('pgrep -u ${user} ssh-agent | wc -l')
	if res.exit_code == 0 {
		agent_count := res.output.trim_space().int()
		if agent_count == 0 {
			security_status['ssh_agents'] = 'INFO: No SSH agents running'
		} else if agent_count == 1 {
			security_status['ssh_agents'] = 'OK: One SSH agent running'
		} else {
			security_status['ssh_agents'] = 'WARNING: Multiple SSH agents running (${agent_count})'
		}
	}

	return security_status
}
