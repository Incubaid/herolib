module herocmds

import os
import incubaid.herolib.ui.console
import incubaid.herolib.develop.gittools
import cli { Command, Flag }

pub fn cmd_source(mut cmdroot Command) {
	mut cmd_run := Command{
		name:        'source'
		description: 'Clone a secrets repository and source environment variables from it.'
		usage:       '
Hero Source - Secrets Repository Management

Clones a git repository (typically containing secrets) and sources a shell script
from it to load environment variables. Handles SSH key setup automatically.

USAGE:
  hero source <repo_url> [options]

EXAMPLES:
  hero source https://forge.ourworld.tf/ourworld_it/secrets
  hero source https://forge.ourworld.tf/ourworld_it/secrets --key /path/to/key
  hero source https://forge.ourworld.tf/ourworld_it/secrets --file secrets.sh

ENVIRONMENT VARIABLES:
  SECRETS_SSH_KEY    SSH private key content (used if --key not specified)
  SSH_KEY            Alternative env var for SSH private key

The command will:
  1. Setup SSH with the provided key (from --key flag or env var)
  2. Clone/pull the repository
  3. Source the specified shell file (default: secrets.sh)
  4. Export all variables to the current environment
'
		execute:       cmd_source_execute
		sort_commands: true
	}

	cmd_run.add_flag(Flag{
		flag:        .string
		name:        'key'
		abbrev:      'k'
		description: 'Path to SSH private key file, or the key content directly. If not provided, uses SECRETS_SSH_KEY or SSH_KEY env var.'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		name:        'file'
		abbrev:      'f'
		description: 'Name of the shell file to source (default: secrets.sh)'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		name:        'host'
		abbrev:      'h'
		description: 'Git host for SSH known_hosts setup (auto-detected from URL if not specified)'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		name:        'print'
		abbrev:      'p'
		description: 'Print the exported variables (masked values)'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		name:        'script'
		abbrev:      's'
		description: 'Run in script/non-interactive mode'
	})

	cmdroot.add_command(cmd_run)
}

fn cmd_source_execute(cmd Command) ! {
	// Get repository URL from args
	if cmd.args.len == 0 {
		return error('Repository URL is required.\n\nUsage: hero source <repo_url>\n\nExample: hero source https://forge.ourworld.tf/ourworld_it/secrets')
	}

	repo_url := cmd.args[0]
	key_arg := cmd.flags.get_string('key') or { '' }
	secrets_file := cmd.flags.get_string('file') or { 'secrets.sh' }
	host_arg := cmd.flags.get_string('host') or { '' }
	print_vars := cmd.flags.get_bool('print') or { false }
	is_script := cmd.flags.get_bool('script') or { false }

	if !is_script {
		console.print_header('🔐 Hero Source - Loading Secrets')
	}

	// Step 1: Setup SSH key
	setup_ssh_key(key_arg, repo_url, host_arg)!

	// Step 2: Clone/pull the repository
	repo_path := clone_secrets_repo(repo_url)!

	// Step 3: Source the secrets file
	source_secrets_file(repo_path, secrets_file, print_vars, is_script)!

	if !is_script {
		console.print_green('✅ Secrets loaded successfully')
	}
}

// Setup SSH key for repository access
fn setup_ssh_key(key_arg string, repo_url string, host_arg string) ! {
	// Determine SSH key content
	mut key_content := ''

	if key_arg != '' {
		// Check if it's a file path or key content
		if os.exists(key_arg) {
			key_content = os.read_file(key_arg)!
		} else if key_arg.contains('PRIVATE KEY') {
			key_content = key_arg
		} else {
			return error('SSH key argument is neither a valid file path nor key content: ${key_arg}')
		}
	} else {
		// Try environment variables
		key_content = os.getenv('SECRETS_SSH_KEY')
		if key_content == '' {
			key_content = os.getenv('SSH_KEY')
		}
	}

	if key_content == '' {
		console.print_debug('No SSH key provided, assuming repository is accessible without authentication')
		return
	}

	// Setup SSH directory and key file
	home := os.home_dir()
	ssh_dir := '${home}/.ssh'
	key_path := '${ssh_dir}/id_secrets'

	// Create .ssh directory if needed
	if !os.exists(ssh_dir) {
		os.mkdir_all(ssh_dir)!
		os.chmod(ssh_dir, 0o700)!
	}

	// Write the key file
	os.write_file(key_path, key_content)!
	os.chmod(key_path, 0o600)!

	console.print_debug('SSH key written to ${key_path}')

	// Determine host for known_hosts
	host := if host_arg != '' {
		host_arg
	} else {
		extract_host_from_url(repo_url)
	}

	if host != '' {
		// Add to known_hosts
		known_hosts_path := '${ssh_dir}/known_hosts'
		result := os.execute('ssh-keyscan -t rsa ${host} 2>/dev/null')
		if result.exit_code == 0 && result.output.len > 0 {
			// Append to known_hosts if not already present
			existing := if os.exists(known_hosts_path) {
				os.read_file(known_hosts_path) or { '' }
			} else {
				''
			}
			if !existing.contains(host) {
				mut f := os.open_append(known_hosts_path)!
				f.write_string(result.output)!
				f.close()
				console.print_debug('Added ${host} to known_hosts')
			}
		}

		// Setup SSH config for this host
		config_path := '${ssh_dir}/config'
		config_entry := 'Host ${host}\n  IdentityFile ${key_path}\n'

		existing_config := if os.exists(config_path) {
			os.read_file(config_path) or { '' }
		} else {
			''
		}

		if !existing_config.contains('Host ${host}') {
			mut f := os.open_append(config_path)!
			f.write_string('\n${config_entry}')!
			f.close()
			console.print_debug('Added SSH config for ${host}')
		}
	}

	console.print_green('✓ SSH key configured')
}

// Extract hostname from git URL
fn extract_host_from_url(url string) string {
	// Handle various URL formats:
	// https://forge.ourworld.tf/org/repo
	// git@forge.ourworld.tf:org/repo
	// ssh://git@forge.ourworld.tf/org/repo

	if url.starts_with('https://') || url.starts_with('http://') {
		// https://forge.ourworld.tf/org/repo
		without_scheme := url.replace('https://', '').replace('http://', '')
		return without_scheme.split('/')[0]
	} else if url.starts_with('git@') {
		// git@forge.ourworld.tf:org/repo
		without_prefix := url.replace('git@', '')
		if without_prefix.contains(':') {
			return without_prefix.split(':')[0]
		}
		return without_prefix.split('/')[0]
	} else if url.starts_with('ssh://') {
		// ssh://git@forge.ourworld.tf/org/repo
		without_scheme := url.replace('ssh://', '')
		if without_scheme.contains('@') {
			after_at := without_scheme.split('@')[1]
			return after_at.split('/')[0]
		}
		return without_scheme.split('/')[0]
	}

	return ''
}

// Clone or pull the secrets repository
fn clone_secrets_repo(repo_url string) !string {
	console.print_debug('Cloning/pulling repository: ${repo_url}')

	mut gs := gittools.new()!
	repo := gs.get_repo(url: repo_url, pull: true)!

	repo_path := repo.path()
	console.print_green('✓ Repository ready at ${repo_path}')

	return repo_path
}

// Source the secrets file and export variables
fn source_secrets_file(repo_path string, filename string, print_vars bool, is_script bool) ! {
	secrets_path := '${repo_path}/${filename}'

	if !os.exists(secrets_path) {
		return error('Secrets file not found: ${secrets_path}')
	}

	console.print_debug('Sourcing secrets from ${secrets_path}')

	// Read and parse the shell file
	content := os.read_file(secrets_path)!
	lines := content.split('\n')

	mut exported_count := 0

	for line in lines {
		trimmed := line.trim_space()

		// Skip empty lines and comments
		if trimmed == '' || trimmed.starts_with('#') {
			continue
		}

		// Handle export statements: export VAR=value or export VAR="value"
		mut var_line := trimmed
		if var_line.starts_with('export ') {
			var_line = var_line.replace('export ', '')
		}

		// Parse VAR=value
		if var_line.contains('=') {
			parts := var_line.split_nth('=', 2)
			if parts.len == 2 {
				key := parts[0].trim_space()
				mut value := parts[1].trim_space()

				// Remove surrounding quotes
				if (value.starts_with('"') && value.ends_with('"'))
					|| (value.starts_with("'") && value.ends_with("'")) {
					value = value[1..value.len - 1]
				}

				// Set environment variable
				os.setenv(key, value, true)
				exported_count++

				if print_vars {
					// Mask the value for security
					masked := if value.len > 4 {
						'${value[0..2]}***${value[value.len - 2..]}'
					} else {
						'****'
					}
					console.print_item('${key}=${masked}')
				}
			}
		}
	}

	if !is_script {
		console.print_green('✓ Exported ${exported_count} environment variables')
	}
}
