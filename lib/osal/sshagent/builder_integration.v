module sshagent

import freeflowuniverse.herolib.builder
import freeflowuniverse.herolib.ui.console

// push SSH public key to a remote node's authorized_keys
pub fn (mut agent SSHAgent) push_key_to_node(mut node builder.Node, key_name string) ! {
	// Verify this is an SSH node
	node_info := node.info()
	if node_info['category'] != 'ssh' {
		return error('Can only push keys to SSH nodes, got: ${node_info['category']}')
	}

	// Find the key
	mut key := agent.get(name: key_name) or {
		return error('SSH key "${key_name}" not found in agent')
	}

	// Get public key content
	pubkey_content := key.keypub()!

	// Check if authorized_keys file exists on remote
	home_dir := node.environ_get()!['HOME'] or {
		return error('Could not determine HOME directory on remote node')
	}

	ssh_dir := '${home_dir}/.ssh'
	authorized_keys_path := '${ssh_dir}/authorized_keys'

	// Ensure .ssh directory exists with correct permissions
	node.exec_silent('mkdir -p ${ssh_dir}')!
	node.exec_silent('chmod 700 ${ssh_dir}')!

	// Check if key already exists
	if node.file_exists(authorized_keys_path) {
		existing_keys := node.file_read(authorized_keys_path)!
		if existing_keys.contains(pubkey_content.trim_space()) {
			console.print_debug('SSH key already exists on remote node')
			return
		}
	}

	// Add key to authorized_keys
	node.exec_silent('echo "${pubkey_content}" >> ${authorized_keys_path}')!
	node.exec_silent('chmod 600 ${authorized_keys_path}')!

	console.print_debug('SSH key "${key_name}" successfully pushed to node')
}

// remove SSH public key from a remote node's authorized_keys
pub fn (mut agent SSHAgent) remove_key_from_node(mut node builder.Node, key_name string) ! {
	// Verify this is an SSH node
	node_info := node.info()
	if node_info['category'] != 'ssh' {
		return error('Can only remove keys from SSH nodes, got: ${node_info['category']}')
	}

	// Find the key
	mut key := agent.get(name: key_name) or {
		return error('SSH key "${key_name}" not found in agent')
	}

	// Get public key content
	pubkey_content := key.keypub()!

	// Get authorized_keys path
	home_dir := node.environ_get()!['HOME'] or {
		return error('Could not determine HOME directory on remote node')
	}

	authorized_keys_path := '${home_dir}/.ssh/authorized_keys'

	if !node.file_exists(authorized_keys_path) {
		console.print_debug('authorized_keys file does not exist on remote node')
		return
	}

	// Remove the key line from authorized_keys
	escaped_key := pubkey_content.replace('/', '\\/')
	node.exec_silent('sed -i "\\|${escaped_key}|d" ${authorized_keys_path}')!

	console.print_debug('SSH key "${key_name}" removed from remote node')
}

// verify SSH key access to remote node
pub fn (mut agent SSHAgent) verify_key_access(mut node builder.Node, key_name string) !bool {
	// This would attempt to connect with the specific key
	// For now, we'll do a simple connectivity test
	node_info := node.info()
	if node_info['category'] != 'ssh' {
		return error('Can only verify access to SSH nodes')
	}

	// Test basic connectivity
	result := node.exec_silent('echo "SSH key verification successful"') or { return false }

	return result.contains('SSH key verification successful')
}

// Copy private key to remote node
pub fn remote_copy(mut agent SSHAgent, node_addr string, key_name string) ! {
	console.print_header('Copying SSH key "${key_name}" to ${node_addr}')

	// Get the key
	mut key := agent.get(name: key_name) or { return error('SSH key "${key_name}" not found') }

	// Create builder node
	mut b := builder.new()!
	mut node := b.node_new(ipaddr: node_addr)!

	// Get private key content
	mut key_path := key.keypath()!
	if !key_path.exists() {
		return error('Private key file not found: ${key_path.path}')
	}

	private_key_content := key_path.read()!

	// Get home directory on remote
	home_dir := node.environ_get()!['HOME'] or {
		return error('Could not determine HOME directory on remote node')
	}

	remote_ssh_dir := '${home_dir}/.ssh'
	remote_key_path := '${remote_ssh_dir}/${key_name}'

	// Ensure .ssh directory exists with correct permissions
	node.exec_silent('mkdir -p ${remote_ssh_dir}')!
	node.exec_silent('chmod 700 ${remote_ssh_dir}')!

	// Copy private key to remote
	node.file_write(remote_key_path, private_key_content)!
	node.exec_silent('chmod 600 ${remote_key_path}')!

	// Generate public key on remote
	node.exec_silent('ssh-keygen -y -f ${remote_key_path} > ${remote_key_path}.pub')!
	node.exec_silent('chmod 644 ${remote_key_path}.pub')!

	console.print_green('✓ SSH key "${key_name}" copied to ${node_addr}')
}

// Add public key to authorized_keys on remote node
pub fn remote_auth(mut agent SSHAgent, node_addr string, key_name string) ! {
	console.print_header('Adding SSH key "${key_name}" to authorized_keys on ${node_addr}')

	// Create builder node
	mut b := builder.new()!
	mut node := b.node_new(ipaddr: node_addr)!

	// Use existing builder integration
	agent.push_key_to_node(mut node, key_name)!

	console.print_green('✓ SSH key "${key_name}" added to authorized_keys on ${node_addr}')
}
