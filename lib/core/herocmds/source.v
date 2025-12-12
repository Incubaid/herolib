module herocmds

import os
import incubaid.herolib.osal.sshkeys
import incubaid.herolib.develop.gittools
import incubaid.herolib.ui.console
import cli { Command, Flag }

pub fn cmd_source(mut cmdroot Command) {
	mut cmd_run := Command{
		name:        'source'
		description: 'Fetch a secrets file from a git repository.'
		usage:       '
Hero Source - Fetch secrets file from git

Fetches a file from a git repository. SSH keys are read from
environment variables (SECRETS_SSH_KEY, SSH_KEY, {ORG}_SSH_KEY).

USAGE:
  hero source <url_to_file>

EXAMPLES:
  hero source https://forge.ourworld.tf/ourworld_it/secrets/src/branch/main/secrets.sh

The command will:
  1. Find SSH keys from environment variables
  2. Use gittools to clone/fetch the file (with temp SSH key if needed)
  3. Output the local path (can be sourced: source $(hero source <url>))

Note: Keys are NOT added to the system ssh-agent.
'
		execute:       cmd_source_execute
		sort_commands: true
	}

	cmd_run.add_flag(Flag{
		flag:        .string
		name:        'output'
		abbrev:      'o'
		description: 'Output file path (default: print local path)'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		name:        'ssh'
		abbrev:      's'
		description: 'Use SSH for git operations'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		name:        'verbose'
		abbrev:      'v'
		description: 'Enable verbose debug output'
	})

	cmdroot.add_command(cmd_run)
}

fn cmd_source_execute(cmd Command) ! {
	if cmd.args.len == 0 {
		return error('URL to file is required.\n\nUsage: hero source <url_to_file>\n\nExample: hero source https://forge.ourworld.tf/ourworld_it/secrets/src/branch/main/secrets.sh')
	}

	file_url := cmd.args[0]
	output_path := cmd.flags.get_string('output') or { '' }
	use_ssh := cmd.flags.get_bool('ssh') or { false }
	verbose := cmd.flags.get_bool('verbose') or { false }

	if verbose {
		console.print_debug('source: file_url=${file_url}, use_ssh=${use_ssh}, output_path=${output_path}')
	}

	// Load SSH keys from environment (does NOT touch system ssh-agent)
	mut keys := sshkeys.new()
	loaded_count := keys.load_from_env()

	if verbose {
		console.print_debug('source: found ${loaded_count} SSH keys in environment')
		for name in keys.list() {
			console.print_debug('  - key: ${name}')
		}
	}

	// Find appropriate SSH key if --ssh flag is set
	mut sshkey := ''
	if use_ssh {
		sshkey = find_ssh_key_for_url(file_url, keys)
		if verbose {
			if sshkey.len > 0 {
				console.print_debug('source: found SSH key (${sshkey.len} bytes)')
			} else {
				console.print_debug('source: no SSH key found for URL')
			}
		}
	}

	// Use gittools to get the file path
	if verbose {
		console.print_debug('source: calling gittools.path()')
	}
	file_path := gittools.path(git_url: file_url, sshkey: sshkey)!
	if verbose {
		console.print_debug('source: resolved path=${file_path.path}')
	}

	if output_path.len > 0 {
		// Copy to specified output location
		os.cp(file_path.path, output_path)!
		println(output_path)
	} else {
		// Just print the local path
		println(file_path.path)
	}
}

// Find the best SSH key for a URL based on org/provider from loaded keys
fn find_ssh_key_for_url(url string, keys sshkeys.SSHKeys) string {
	// Parse URL to get org/provider
	mut gs := gittools.new() or { return '' }
	git_loc := gs.gitlocation_from_url(url) or { return '' }

	// Use sshkeys to find the best key for this repo
	if key := keys.find_for_repo(git_loc.account, git_loc.provider) {
		return key.content
	}

	return ''
}

