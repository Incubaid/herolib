module hetznermanager

import incubaid.herolib.core.texttools
import incubaid.herolib.ui.console

pub struct SSHKey {
pub mut:
	name        string
	fingerprint string
	type_       string @[json: 'type']
	size        int
	created_at  string
	data        string
}

pub fn (mut h HetznerManager) keys_get() ![]SSHKey {
	mut conn := h.connection()!
	return conn.get_json_list_generic[SSHKey](
		method:        .get
		prefix:        'key'
		list_dict_key: 'key'
		dataformat:    .urlencoded
	)!
}

// Get a specific SSH key by fingerprint
pub fn (mut h HetznerManager) key_get(name string) !SSHKey {
	name_fixed := texttools.name_fix(name)
	keys := h.keys_get()!
	for key in keys {
		if texttools.name_fix(key.name) == name_fixed {
			return key
		}
	}
	return error('SSH key with name "${name}" not found')
}

pub fn (mut h HetznerManager) key_exists(name string) bool {
	name_fixed := texttools.name_fix(name)
	keys := h.keys_get() or { return false }
	for key in keys {
		if texttools.name_fix(key.name) == name_fixed {
			return true
		}
	}
	return false
}

// Create a new SSH key
pub fn (mut h HetznerManager) key_create(name string, data string) !SSHKey {
	name_fixed := texttools.name_fix(name)
	mut conn := h.connection()!
	if h.key_exists(name_fixed) {
		return error('SSH key with name "${name_fixed}" already exists')
	}
	return conn.post_json_generic[SSHKey](
		method:     .post
		prefix:     'key'
		dataformat: .urlencoded
		params:     {
			'name': name_fixed
			'data': data
		}
	)!
}

// Delete an SSH key
pub fn (mut h HetznerManager) key_delete(name string) ! {
	if !h.key_exists(name) {
		return
	}
	key := h.key_get(name)!
	mut conn := h.connection()!
	conn.delete(
		method:     .delete
		prefix:     'key/${key.fingerprint}'
		dataformat: .urlencoded
	)!
}

// Get SSH keys based on the sshkey specification mode:
// - '*': returns all keys registered on Hetzner
// - any other value: returns the key with that name (e.g., "kristof", "mahmoud")
pub fn (mut h HetznerManager) get_keys_for_rescue() ![]SSHKey {
	if h.sshkey == '*' {
		// Return all keys registered on Hetzner
		keys := h.keys_get()!
		if keys.len == 0 {
			return error('No SSH keys registered on Hetzner account')
		}
		console.print_debug('Using all ${keys.len} SSH keys from Hetzner')
		return keys
	} else {
		// Use the specified key name
		if !h.key_exists(h.sshkey) {
			return error('SSH key "${h.sshkey}" not found on Hetzner. Available keys: ${h.keys_get()!.map(it.name).join(', ')}')
		}
		key := h.key_get(h.sshkey)!
		console.print_debug('Using SSH key "${h.sshkey}" from Hetzner')
		return [key]
	}
}

// Get all public key data for the specified keys (for copying to authorized_keys)
pub fn (mut h HetznerManager) get_pubkeys_data() ![]string {
	keys := h.get_keys_for_rescue()!
	mut pubkeys := []string{}
	for key in keys {
		if key.data.len > 0 {
			pubkeys << key.data
		}
	}
	return pubkeys
}
