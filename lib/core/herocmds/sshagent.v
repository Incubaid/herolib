module herocmds

import os
import freeflowuniverse.herolib.osal.sshagent
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.ui
import cli { Command, Flag }

pub fn cmd_sshagent(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'sshagent'
		description:   'Comprehensive SSH Agent Management'
		usage:         '
Hero SSH Agent Management Tool

COMMANDS:
  profile                     Initialize SSH agent with smart key loading
  list                        List available SSH keys
  generate <name>             Generate new SSH key
  load <name>                 Load SSH key into agent
  forget <name>               Remove SSH key from agent
  reset                       Remove all loaded SSH keys
  push <target> [key]         Deploy SSH key to remote machine
  auth <target> [key]         Verify SSH key authorization
  status                      Show SSH agent status

EXAMPLES:
  hero sshagent profile
  hero sshagent push user@server.com
  hero sshagent push user@server.com:2222 my_key
  hero sshagent auth user@server.com
  hero sshagent load my_key
  hero sshagent status

TARGET FORMAT:
  user@hostname[:port]        # Port defaults to 22
		'
		execute:       cmd_sshagent_execute
		sort_commands: true
	}

	// Profile command - primary initialization
	mut sshagent_command_profile := Command{
		sort_flags:  true
		name:        'profile'
		execute:     cmd_sshagent_execute
		description: 'Initialize SSH agent with smart key loading and shell integration'
	}

	mut sshagent_command_list := Command{
		sort_flags:  true
		name:        'list'
		execute:     cmd_sshagent_execute
		description: 'List available SSH keys and their status'
	}

	mut sshagent_command_generate := Command{
		sort_flags:  true
		name:        'generate'
		execute:     cmd_sshagent_execute
		description: 'Generate new SSH key pair'
	}

	mut sshagent_command_add := Command{
		sort_flags:  true
		name:        'add'
		execute:     cmd_sshagent_execute
		description: 'Add existing private key to SSH agent'
	}

	// Status command
	mut sshagent_command_status := Command{
		sort_flags:  true
		name:        'status'
		execute:     cmd_sshagent_execute
		description: 'Show SSH agent status and diagnostics'
	}

	// Push command for remote deployment
	mut sshagent_command_push := Command{
		sort_flags:  true
		name:        'push'
		execute:     cmd_sshagent_execute
		description: 'Deploy SSH key to remote machine'
	}

	// Auth command for verification
	mut sshagent_command_auth := Command{
		sort_flags:  true
		name:        'auth'
		execute:     cmd_sshagent_execute
		description: 'Verify SSH key authorization on remote machine'
	}

	sshagent_command_generate.add_flag(Flag{
		flag:        .bool
		name:        'load'
		abbrev:      'l'
		description: 'should key be loaded'
	})

	// Add target flag for push and auth commands
	sshagent_command_push.add_flag(Flag{
		flag:        .string
		name:        'target'
		abbrev:      't'
		required:    true
		description: 'target in format user@hostname[:port]'
	})

	sshagent_command_push.add_flag(Flag{
		flag:        .string
		name:        'key'
		abbrev:      'k'
		description: 'specific key name to deploy (optional)'
	})

	sshagent_command_auth.add_flag(Flag{
		flag:        .string
		name:        'target'
		abbrev:      't'
		required:    true
		description: 'target in format user@hostname[:port]'
	})

	sshagent_command_auth.add_flag(Flag{
		flag:        .string
		name:        'key'
		abbrev:      'k'
		description: 'specific key name to verify (optional)'
	})

	mut sshagent_command_load := Command{
		sort_flags:  true
		name:        'load'
		execute:     cmd_sshagent_execute
		description: 'load ssh-key in agent.'
	}

	mut sshagent_command_unload := Command{
		sort_flags:  true
		name:        'forget'
		execute:     cmd_sshagent_execute
		description: 'Unload ssh-key from agent.'
	}

	mut sshagent_command_reset := Command{
		sort_flags:  true
		name:        'reset'
		execute:     cmd_sshagent_execute
		description: 'Reset all keys, means unload them all.'
	}

	// Commands that require a name parameter
	mut allcmdsref_gen0 := [&sshagent_command_generate, &sshagent_command_load, &sshagent_command_unload,
		&sshagent_command_reset, &sshagent_command_add]
	for mut d in allcmdsref_gen0 {
		d.add_flag(Flag{
			flag:        .string
			name:        'name'
			abbrev:      'n'
			required:    true
			description: 'name of the key'
		})
	}

	// Commands that support script mode
	mut allcmdsref_gen := [&sshagent_command_list, &sshagent_command_generate, &sshagent_command_load,
		&sshagent_command_unload, &sshagent_command_reset, &sshagent_command_status]

	for mut c in allcmdsref_gen {
		c.add_flag(Flag{
			flag:        .bool
			name:        'script'
			abbrev:      's'
			description: 'runs non interactive!'
		})
	}

	// Add all commands to the main sshagent command
	cmd_run.add_command(sshagent_command_profile)
	cmd_run.add_command(sshagent_command_list)
	cmd_run.add_command(sshagent_command_generate)
	cmd_run.add_command(sshagent_command_add)
	cmd_run.add_command(sshagent_command_load)
	cmd_run.add_command(sshagent_command_unload)
	cmd_run.add_command(sshagent_command_reset)
	cmd_run.add_command(sshagent_command_status)
	cmd_run.add_command(sshagent_command_push)
	cmd_run.add_command(sshagent_command_auth)

	cmdroot.add_command(cmd_run)
}

fn cmd_sshagent_execute(cmd Command) ! {
	mut isscript := cmd.flags.get_bool('script') or { false }
	mut load := cmd.flags.get_bool('load') or { false }
	mut name := cmd.flags.get_string('name') or { '' }
	mut target := cmd.flags.get_string('target') or { '' }
	mut key := cmd.flags.get_string('key') or { '' }

	mut agent := sshagent.new()!

	match cmd.name {
		'profile' {
			cmd_profile_execute(mut agent, isscript)!
		}
		'list' {
			cmd_list_execute(mut agent, isscript)!
		}
		'generate' {
			cmd_generate_execute(mut agent, name, load)!
		}
		'load' {
			cmd_load_execute(mut agent, name)!
		}
		'forget' {
			cmd_forget_execute(mut agent, name)!
		}
		'reset' {
			cmd_reset_execute(mut agent, isscript)!
		}
		'add' {
			cmd_add_execute(mut agent, name)!
		}
		'status' {
			cmd_status_execute(mut agent)!
		}
		'push' {
			cmd_push_execute(mut agent, target, key)!
		}
		'auth' {
			cmd_auth_execute(mut agent, target, key)!
		}
		else {
			return error(cmd.help_message())
		}
	}
}

// Profile command - comprehensive SSH agent initialization
fn cmd_profile_execute(mut agent sshagent.SSHAgent, isscript bool) ! {
	console.print_header('🔑 Hero SSH Agent Profile Initialization')

	// Ensure single agent instance
	agent.ensure_single_agent()!
	console.print_green('✓ SSH agent instance verified')

	// Smart key loading
	available_keys := agent.keys
	loaded_keys := agent.keys_loaded()!

	console.print_debug('Found ${available_keys.len} available keys, ${loaded_keys.len} loaded')

	// If only one key and none loaded, auto-load it
	if available_keys.len == 1 && loaded_keys.len == 0 {
		key_name := available_keys[0].name
		console.print_debug('Auto-loading single key: ${key_name}')

		mut key := agent.get(name: key_name) or {
			console.print_stderr('Failed to get key: ${err}')
			return
		}

		key.load() or { console.print_debug('Key loading failed (may need passphrase): ${err}') }
	}

	// Update shell profile
	update_shell_profile()!

	console.print_green('✅ SSH agent profile initialized successfully')
	cmd_status_execute(mut agent)!
}

// Update shell profile with SSH agent initialization
fn update_shell_profile() ! {
	home := os.home_dir()
	ssh_dir := '${home}/.ssh'
	socket_path := '${ssh_dir}/hero-agent.sock'

	// Find appropriate profile file
	profile_candidates := [
		'${home}/.profile',
		'${home}/.bash_profile',
		'${home}/.bashrc',
		'${home}/.zshrc',
	]

	mut profile_file := '${home}/.profile'
	for candidate in profile_candidates {
		if os.exists(candidate) {
			profile_file = candidate
			break
		}
	}

	profile_content := if os.exists(profile_file) {
		os.read_file(profile_file)!
	} else {
		''
	}

	hero_init_block := '
# Hero SSH Agent initialization
if [ -f "${socket_path}" ]; then
    export SSH_AUTH_SOCK="${socket_path}"
fi'

	// Check if already present
	if profile_content.contains('Hero SSH Agent initialization') {
		console.print_debug('Hero initialization already present in profile')
		return
	}

	// Add hero initialization
	updated_content := profile_content + hero_init_block
	os.write_file(profile_file, updated_content)!

	console.print_green('✓ Updated shell profile: ${profile_file}')
}

// List command
fn cmd_list_execute(mut agent sshagent.SSHAgent, isscript bool) ! {
	if !isscript {
		console.clear()
	}

	console.print_header('SSH Keys Status')
	println(agent.str())

	loaded_keys := agent.keys_loaded()!
	if loaded_keys.len > 0 {
		console.print_header('Currently Loaded Keys:')
		for key in loaded_keys {
			console.print_item('- ${key.name} (${key.cat})')
		}
	} else {
		console.print_debug('No keys currently loaded in agent')
	}
}

// Generate command
fn cmd_generate_execute(mut agent sshagent.SSHAgent, name string, load bool) ! {
	if name == '' {
		return error('Key name is required for generate command')
	}

	console.print_debug('Generating SSH key: ${name}')
	mut key := agent.generate(name, '')!
	console.print_green('✓ Generated SSH key: ${name}')

	if load {
		console.print_debug('Loading key into agent...')
		key.load() or {
			console.print_stderr('Failed to load key: ${err}')
			return
		}
		console.print_green('✓ Key loaded into agent')
	}
}

// Load command
fn cmd_load_execute(mut agent sshagent.SSHAgent, name string) ! {
	if name == '' {
		return error('Key name is required for load command')
	}

	mut key := agent.get(name: name) or { return error('SSH key "${name}" not found') }

	console.print_debug('Loading SSH key: ${name}')
	key.load()!
	console.print_green('✓ SSH key "${name}" loaded successfully')
}

// Forget command
fn cmd_forget_execute(mut agent sshagent.SSHAgent, name string) ! {
	if name == '' {
		return error('Key name is required for forget command')
	}

	console.print_debug('Removing SSH key from agent: ${name}')
	agent.forget(name)!
	console.print_green('✓ SSH key "${name}" removed from agent')
}

// Reset command
fn cmd_reset_execute(mut agent sshagent.SSHAgent, isscript bool) ! {
	if !isscript {
		print('This will remove all loaded SSH keys. Continue? (y/N): ')
		input := os.input('')
		if input.trim_space().to_lower() != 'y' {
			console.print_debug('Reset cancelled')
			return
		}
	}

	console.print_debug('Resetting SSH agent - removing all keys')
	agent.reset()!
	console.print_green('✓ All SSH keys removed from agent')
}

// Add command
fn cmd_add_execute(mut agent sshagent.SSHAgent, name string) ! {
	if name == '' {
		return error('Key name is required for add command')
	}

	mut myui := ui.new()!
	privkey := myui.ask_question(
		question: 'Enter the private key content:'
	)!

	console.print_debug('Adding SSH key: ${name}')
	agent.add(name, privkey)!
	console.print_green('✓ SSH key "${name}" added successfully')
}

// Status command
fn cmd_status_execute(mut agent sshagent.SSHAgent) ! {
	console.print_header('SSH Agent Status')

	diag := agent.diagnostics()
	for key, value in diag {
		console.print_item('${key}: ${value}')
	}

	loaded_keys := agent.keys_loaded()!
	if loaded_keys.len > 0 {
		console.print_header('Loaded Keys:')
		for key in loaded_keys {
			console.print_item('- ${key.name} (${key.cat})')
		}
	} else {
		console.print_debug('No keys currently loaded')
	}
}

// Push command - deploy SSH key to remote machine
fn cmd_push_execute(mut agent sshagent.SSHAgent, target string, key_name string) ! {
	if target == '' {
		return error('Target is required for push command (format: user@hostname[:port])')
	}

	console.print_header('🚀 SSH Key Deployment')

	// Parse target
	parsed_target := parse_target(target)!
	console.print_debug('Target: ${parsed_target.user}@${parsed_target.hostname}:${parsed_target.port}')

	// Select key to deploy
	mut selected_key := select_key_for_deployment(mut agent, key_name)!
	console.print_debug('Selected key: ${selected_key.name}')

	// Deploy key
	deploy_key_to_target(mut selected_key, parsed_target)!

	console.print_green('✅ SSH key deployed successfully to ${target}')
}

// Auth command - verify SSH key authorization
fn cmd_auth_execute(mut agent sshagent.SSHAgent, target string, key_name string) ! {
	if target == '' {
		return error('Target is required for auth command (format: user@hostname[:port])')
	}

	console.print_header('🔐 SSH Key Authorization Verification')

	// Parse target
	parsed_target := parse_target(target)!

	// Select key to verify
	mut selected_key := select_key_for_deployment(mut agent, key_name)!

	// Verify authorization
	verify_key_authorization(mut selected_key, parsed_target)!

	console.print_green('✅ SSH key authorization verified for ${target}')
}

// Helper structures and functions for remote operations
struct RemoteTarget {
mut:
	user     string
	hostname string
	port     int = 22
}

// Parse target string in format user@hostname[:port]
fn parse_target(target_str string) !RemoteTarget {
	if !target_str.contains('@') {
		return error('Target must be in format user@hostname[:port]')
	}

	parts := target_str.split('@')
	if parts.len != 2 {
		return error('Invalid target format: ${target_str}')
	}

	user := parts[0]
	mut hostname := parts[1]
	mut port := 22

	// Check for port specification
	if hostname.contains(':') {
		host_port := hostname.split(':')
		if host_port.len != 2 {
			return error('Invalid hostname:port format: ${hostname}')
		}
		hostname = host_port[0]
		port = host_port[1].int()
	}

	return RemoteTarget{
		user:     user
		hostname: hostname
		port:     port
	}
}

// Select appropriate key for deployment
fn select_key_for_deployment(mut agent sshagent.SSHAgent, key_name string) !sshagent.SSHKey {
	available_keys := agent.keys

	if available_keys.len == 0 {
		return error('No SSH keys found. Generate a key first with: hero sshagent generate <name>')
	}

	// If specific key requested
	if key_name.len > 0 {
		for key in available_keys {
			if key.name == key_name {
				return key
			}
		}
		return error('SSH key "${key_name}" not found')
	}

	// Auto-select if only one key
	if available_keys.len == 1 {
		console.print_debug('Auto-selecting single available key: ${available_keys[0].name}')
		return available_keys[0]
	}

	// Interactive selection for multiple keys
	return interactive_key_selection(available_keys)!
}

// Interactive key selection when multiple keys are available
fn interactive_key_selection(keys []sshagent.SSHKey) !sshagent.SSHKey {
	console.print_header('Multiple SSH keys available:')

	for i, key in keys {
		console.print_item('${i + 1}. ${key.name} (${key.cat})')
	}

	print('Select key number (1-${keys.len}): ')
	input := os.input('')

	selection := input.trim_space().int() - 1
	if selection < 0 || selection >= keys.len {
		return error('Invalid selection: ${input}')
	}

	return keys[selection]
}

// Deploy key to remote target
fn deploy_key_to_target(mut key sshagent.SSHKey, target RemoteTarget) ! {
	console.print_debug('Deploying key ${key.name} to ${target.user}@${target.hostname}')

	// Get public key content
	pub_key_content := key.keypub()!

	// Use ssh-copy-id if available, otherwise manual deployment
	if has_ssh_copy_id() {
		deploy_with_ssh_copy_id(mut key, target)!
	} else {
		deploy_manually(pub_key_content, target)!
	}
}

// Check if ssh-copy-id is available
fn has_ssh_copy_id() bool {
	result := os.execute('which ssh-copy-id')
	return result.exit_code == 0
}

// Deploy using ssh-copy-id
fn deploy_with_ssh_copy_id(mut key sshagent.SSHKey, target RemoteTarget) ! {
	mut key_path := key.keypath()!

	mut cmd := 'ssh-copy-id -i ${key_path.path}'
	if target.port != 22 {
		cmd += ' -p ${target.port}'
	}
	cmd += ' ${target.user}@${target.hostname}'

	console.print_debug('Executing: ${cmd}')
	result := os.execute(cmd)

	if result.exit_code != 0 {
		return error('ssh-copy-id failed: ${result.output}')
	}
}

// Manual deployment by appending to authorized_keys
fn deploy_manually(pub_key_content string, target RemoteTarget) ! {
	mut ssh_cmd := 'ssh'
	if target.port != 22 {
		ssh_cmd += ' -p ${target.port}'
	}

	// Command to append key to authorized_keys
	remote_cmd := 'mkdir -p ~/.ssh && echo "${pub_key_content}" >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys'

	full_cmd := '${ssh_cmd} ${target.user}@${target.hostname} "${remote_cmd}"'

	console.print_debug('Executing manual deployment')
	result := os.execute(full_cmd)

	if result.exit_code != 0 {
		return error('Manual key deployment failed: ${result.output}')
	}
}

// Verify that key is properly authorized on remote target
fn verify_key_authorization(mut key sshagent.SSHKey, target RemoteTarget) ! {
	console.print_debug('Verifying key authorization for ${key.name}')

	// Test SSH connection
	mut ssh_cmd := 'ssh -o BatchMode=yes -o ConnectTimeout=10'
	if target.port != 22 {
		ssh_cmd += ' -p ${target.port}'
	}
	ssh_cmd += ' ${target.user}@${target.hostname} "echo SSH_CONNECTION_SUCCESS"'

	console.print_debug('Testing SSH connection...')
	result := os.execute(ssh_cmd)

	if result.exit_code != 0 {
		return error('SSH connection failed: ${result.output}')
	}

	if !result.output.contains('SSH_CONNECTION_SUCCESS') {
		return error('SSH connection test failed - unexpected output')
	}

	console.print_green('✓ SSH key is properly authorized and working')
}
