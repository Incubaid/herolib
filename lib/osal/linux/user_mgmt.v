module linux

import os
import json
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console

@[params]
pub struct UserCreateArgs {
pub mut:
	name        string @[required]
	giteakey    string
	giteaurl    string
	passwd      string
	description string
	email       string
	tel         string
	sshkey      string // SSH public key
}

@[params]
pub struct UserDeleteArgs {
pub mut:
	name string @[required]
}

@[params]
pub struct SSHKeyCreateArgs {
pub mut:
	username    string @[required]
	sshkey_name string @[required]
	sshkey_pub  string
	sshkey_priv string
}

@[params]
pub struct SSHKeyDeleteArgs {
pub mut:
	username    string @[required]
	sshkey_name string @[required]
}

struct UserConfig {
pub mut:
	name        string
	giteakey    string
	giteaurl    string
	email       string
	description string
	tel         string
}

// Check if running as root
pub fn (mut lf LinuxFactory) check_root() ! {
	if os.getuid() != 0 {
		return error('❌ Must be run as root')
	}
}

// Create a new user with all the configuration
pub fn (mut lf LinuxFactory) user_create(args UserCreateArgs) ! {
	lf.check_root()!

	console.print_header('Creating user: ${args.name}')

	// Save config to ~/hero/cfg/myconfig.json
	lf.save_user_config(args)!

	// Create user using system commands
	lf.create_user_system(args)!
}

// Delete a user
pub fn (mut lf LinuxFactory) user_delete(args UserDeleteArgs) ! {
	lf.check_root()!

	console.print_header('Deleting user: ${args.name}')

	// Check if user exists
	if !osal.user_exists(args.name) {
		return error('User ${args.name} does not exist')
	}

	// Delete user and home directory
	osal.exec(cmd: 'userdel -r ${args.name}')!
	console.print_green('✅ User ${args.name} deleted')

	// Remove from config
	lf.remove_user_config(args.name)!
}

// Create SSH key for user
pub fn (mut lf LinuxFactory) sshkey_create(args SSHKeyCreateArgs) ! {
	lf.check_root()!

	console.print_header('Creating SSH key for user: ${args.username}')

	user_home := '/home/${args.username}'
	ssh_dir := '${user_home}/.ssh'

	// Ensure SSH directory exists
	osal.dir_ensure(ssh_dir)!
	osal.exec(cmd: 'chmod 700 ${ssh_dir}')!

	if args.sshkey_priv != '' && args.sshkey_pub != '' {
		// Both private and public keys provided
		priv_path := '${ssh_dir}/${args.sshkey_name}'
		pub_path := '${ssh_dir}/${args.sshkey_name}.pub'

		osal.file_write(priv_path, args.sshkey_priv)!
		osal.file_write(pub_path, args.sshkey_pub)!

		// Set permissions
		osal.exec(cmd: 'chmod 600 ${priv_path}')!
		osal.exec(cmd: 'chmod 644 ${pub_path}')!

		console.print_green('✅ SSH keys installed for ${args.username}')
	} else {
		// Generate new SSH key (modern ed25519)
		key_path := '${ssh_dir}/${args.sshkey_name}'
		osal.exec(
			cmd: 'ssh-keygen -t ed25519 -f ${key_path} -N "" -C "${args.username}@$(hostname)"'
		)!
		console.print_green('✅ New SSH key generated for ${args.username}')
	}

	// Set ownership
	osal.exec(cmd: 'chown -R ${args.username}:${args.username} ${ssh_dir}')!
}

// Delete SSH key for user
pub fn (mut lf LinuxFactory) sshkey_delete(args SSHKeyDeleteArgs) ! {
	lf.check_root()!

	console.print_header('Deleting SSH key for user: ${args.username}')

	user_home := '/home/${args.username}'
	ssh_dir := '${user_home}/.ssh'

	priv_path := '${ssh_dir}/${args.sshkey_name}'
	pub_path := '${ssh_dir}/${args.sshkey_name}.pub'

	// Remove keys if they exist
	if os.exists(priv_path) {
		os.rm(priv_path)!
		console.print_green('✅ Removed private key: ${priv_path}')
	}
	if os.exists(pub_path) {
		os.rm(pub_path)!
		console.print_green('✅ Removed public key: ${pub_path}')
	}
}

// Save user configuration to JSON file
fn (mut lf LinuxFactory) save_user_config(args UserCreateArgs) ! {
	config_dir := '${os.home_dir()}/hero/cfg'
	osal.dir_ensure(config_dir)!

	config_path := '${config_dir}/myconfig.json'

	mut configs := []UserConfig{}

	// Load existing configs if file exists
	if os.exists(config_path) {
		content := osal.file_read(config_path)!
		configs = json.decode([]UserConfig, content) or { []UserConfig{} }
	}

	// Check if user already exists in config
	mut found_idx := -1
	for i, config in configs {
		if config.name == args.name {
			found_idx = i
			break
		}
	}

	new_config := UserConfig{
		name:        args.name
		giteakey:    args.giteakey
		giteaurl:    args.giteaurl
		email:       args.email
		description: args.description
		tel:         args.tel
	}

	if found_idx >= 0 {
		configs[found_idx] = new_config
	} else {
		configs << new_config
	}

	// Save updated configs
	content := json.encode_pretty(configs)
	osal.file_write(config_path, content)!
	console.print_green('✅ User config saved to ${config_path}')
}

// Remove user from configuration
fn (mut lf LinuxFactory) remove_user_config(username string) ! {
	config_dir := '${os.home_dir()}/hero/cfg'
	config_path := '${config_dir}/myconfig.json'

	if !os.exists(config_path) {
		return
	}

	content := osal.file_read(config_path)!
	mut configs := json.decode([]UserConfig, content) or { return }

	// Filter out the user
	configs = configs.filter(it.name != username)

	// Save updated configs
	updated_content := json.encode_pretty(configs)
	osal.file_write(config_path, updated_content)!
	console.print_green('✅ User config removed for ${username}')
}

// Create user in the system
fn (mut lf LinuxFactory) create_user_system(args UserCreateArgs) ! {
	// Check if user exists
	if osal.user_exists(args.name) {
		console.print_green('✅ User ${args.name} already exists')
	} else {
		console.print_item('➕ Creating user ${args.name}')
		osal.exec(cmd: 'useradd -m -s /bin/bash ${args.name}')!
	}

	user_home := '/home/${args.name}'

	// Setup SSH if key provided
	if args.sshkey != '' {
		ssh_dir := '${user_home}/.ssh'
		osal.dir_ensure(ssh_dir)!
		osal.exec(cmd: 'chmod 700 ${ssh_dir}')!

		authorized_keys := '${ssh_dir}/authorized_keys'
		osal.file_write(authorized_keys, args.sshkey)!
		osal.exec(cmd: 'chmod 600 ${authorized_keys}')!
		osal.exec(cmd: 'chown -R ${args.name}:${args.name} ${ssh_dir}')!
		console.print_green('✅ SSH key installed for ${args.name}')
	}

	// Ensure ourworld group exists
	group_check := osal.exec(cmd: 'getent group ourworld', raise_error: false) or {
		osal.Job{
			exit_code: 1
		}
	}
	if group_check.exit_code != 0 {
		console.print_item('➕ Creating group ourworld')
		osal.exec(cmd: 'groupadd ourworld')!
	} else {
		console.print_green('✅ Group ourworld exists')
	}

	// Add user to group
	user_groups := osal.exec(cmd: 'id -nG ${args.name}', stdout: false)!
	if !user_groups.output.contains('ourworld') {
		osal.exec(cmd: 'usermod -aG ourworld ${args.name}')!
		console.print_green('✅ Added ${args.name} to ourworld group')
	} else {
		console.print_green('✅ ${args.name} already in ourworld')
	}

	// Setup /code directory
	osal.dir_ensure('/code')!
	osal.exec(cmd: 'chown root:ourworld /code')!
	osal.exec(cmd: 'chmod 2775 /code')! // rwx for user+group, SGID bit
	console.print_green('✅ /code prepared (group=ourworld, rwx for group, SGID bit set)')

	// Create SSH agent profile script
	lf.create_ssh_agent_profile(args.name)!

	// Set password if provided
	if args.passwd != '' {
		osal.exec(cmd: 'echo "${args.name}:${args.passwd}" | chpasswd')!
		console.print_green('✅ Password set for ${args.name}')
	}

	console.print_header('🎉 Setup complete for user ${args.name}')
}

// Create SSH agent profile script
fn (mut lf LinuxFactory) create_ssh_agent_profile(username string) ! {
	user_home := '/home/${username}'
	profile_script := '${user_home}/.profile_sshagent'

	// Create SSH agent auto-start script content
	script_content := '#!/bin/bash
# Auto-start ssh-agent if not running
SSH_AGENT_SOCKET="/tmp/ssh-agent-${username}.sock"

# Check if agent is already running and responsive
if [ -n "\$SSH_AUTH_SOCK" ] && ssh-add -l >/dev/null 2>&1; then
    # Agent is running and responsive
    exit 0
fi

# Check if our socket exists and is responsive
if [ -S "\$SSH_AGENT_SOCKET" ]; then
    export SSH_AUTH_SOCK="\$SSH_AGENT_SOCKET"
    if ssh-add -l >/dev/null 2>&1; then
        # Socket is responsive
        exit 0
    fi
fi

# Clean up any orphaned agents
pkill -u ${username} ssh-agent >/dev/null 2>&1 || true

# Remove stale socket
rm -f "\$SSH_AGENT_SOCKET"

# Start new ssh-agent with consistent socket
ssh-agent -a "\$SSH_AGENT_SOCKET" >/dev/null 2>&1

# Export the socket path
export SSH_AUTH_SOCK="\$SSH_AGENT_SOCKET"

# Verify agent is responsive
if ! ssh-add -l >/dev/null 2>&1; then
    echo "Warning: SSH agent started but is not responsive" >&2
fi
'

	osal.file_write(profile_script, script_content)!
	osal.exec(cmd: 'chown ${username}:${username} ${profile_script}')!
	osal.exec(cmd: 'chmod 644 ${profile_script}')!

	// Source it on login
	bashrc := '${user_home}/.bashrc'
	bashrc_content := if os.exists(bashrc) { osal.file_read(bashrc)! } else { '' }

	if !bashrc_content.contains('.profile_sshagent') {
		source_line := '[ -f ~/.profile_sshagent ] && source ~/.profile_sshagent\n'
		osal.file_write(bashrc, bashrc_content + source_line)!
	}

	console.print_green('✅ SSH agent profile created for ${username}')
}
