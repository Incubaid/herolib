module sshkeys

// Lightweight SSH key management - tracks keys without modifying system ssh-agent.
// Keys are loaded from environment variables and can be written to temp files
// for use with GIT_SSH_COMMAND.

import os
import incubaid.herolib.ui.console

// SSHKey represents an SSH key loaded from environment
pub struct SSHKey {
pub mut:
	name    string // Key name (derived from env var, e.g., "ourworld-it" from OURWORLD_IT_SSH_KEY)
	content string // Private key content
}

// SSHKeys manages a collection of SSH keys loaded from environment
@[heap]
pub struct SSHKeys {
pub mut:
	keys []SSHKey
}

// new creates a new SSHKeys instance
pub fn new() SSHKeys {
	return SSHKeys{}
}

// load_from_env loads SSH keys from environment variables.
// Looks for: SECRETS_SSH_KEY, SSH_KEY, and *_SSH_KEY patterns.
// Returns number of keys loaded.
pub fn (mut sk SSHKeys) load_from_env() int {
	mut loaded := 0
	mut env_vars := ['SECRETS_SSH_KEY', 'SSH_KEY']

	// Find all *_SSH_KEY env vars
	for env_name, _ in os.environ() {
		if env_name.ends_with('_SSH_KEY') && env_name !in env_vars {
			env_vars << env_name
		}
	}

	for env_name in env_vars {
		key_content := os.getenv(env_name)
		if key_content.len == 0 {
			continue
		}

		// Normalize key: handle escaped newlines
		mut final_key := key_content
		if final_key.contains('\\n') {
			final_key = final_key.replace('\\n', '\n')
		}
		final_key = final_key.trim_space()
		if !final_key.ends_with('\n') {
			final_key = final_key + '\n'
		}

		// Validate key format
		if !final_key.contains('-----BEGIN') || !final_key.contains('-----END') {
			console.print_debug('sshkeys: skipping invalid key from ${env_name}')
			continue
		}

		// Generate key name from env var name (e.g., OURWORLD_IT_SSH_KEY -> ourworld-it)
		key_name := env_name.to_lower().replace('_ssh_key', '').replace('_', '-')
		if key_name.len == 0 {
			continue
		}

		sk.keys << SSHKey{
			name:    key_name
			content: final_key
		}
		console.print_debug('sshkeys: loaded key "${key_name}" from ${env_name}')
		loaded += 1
	}

	return loaded
}

// get returns a key by name, or none if not found
pub fn (sk &SSHKeys) get(name string) ?SSHKey {
	normalized := name.to_lower().replace('_', '-')
	for key in sk.keys {
		if key.name == normalized {
			return key
		}
	}
	return none
}

// find_for_repo finds the best SSH key for a repo based on account/provider.
// Priority: account-specific > provider-specific > secrets > first available
pub fn (sk &SSHKeys) find_for_repo(account string, provider string) ?SSHKey {
	candidates := [
		account.to_lower().replace('_', '-'),
		provider.to_lower().replace('_', '-'),
		'secrets',
	]

	for candidate in candidates {
		if key := sk.get(candidate) {
			console.print_debug('sshkeys: found key "${key.name}" for ${account}/${provider}')
			return key
		}
	}

	// Fallback: return first available key
	if sk.keys.len > 0 {
		console.print_debug('sshkeys: using fallback key "${sk.keys[0].name}" for ${account}/${provider}')
		return sk.keys[0]
	}

	return none
}

// list returns all loaded key names
pub fn (sk &SSHKeys) list() []string {
	return sk.keys.map(it.name)
}

// len returns number of loaded keys
pub fn (sk &SSHKeys) len() int {
	return sk.keys.len
}
