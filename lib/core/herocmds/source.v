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

Fetches a file from a git repository. SSH keys are automatically loaded from
environment variables and used if a matching key is found for the repository.

USAGE:
  hero source <url_to_file>
  hero source --key <ENV_VAR_NAME> <url_to_file>

EXAMPLES:
  hero source https://forge.ourworld.tf/ourworld_it/secrets/src/branch/main/secrets.sh
  hero source --key MY_DEPLOY_KEY https://github.com/myorg/private-repo

SSH KEY DETECTION:
  Keys are automatically loaded from environment variables matching:
  - SECRETS_SSH_KEY
  - SSH_KEY  
  - {ORG}_SSH_KEY (e.g., OURWORLD_IT_SSH_KEY, GITHUB_SSH_KEY)
  - {ORG}_{REPO}_SSH_KEY (e.g., OURWORLD_IT_SECRETS_SSH_KEY)

  The best matching key is selected based on org/repo name in the URL.
  Use --key to explicitly specify which env var to use.

The command will:
  1. Load SSH keys from environment variables (does NOT modify ssh-agent)
  2. Auto-select best matching key for the repo, or use --key if specified
  3. Clone/fetch using temp SSH key file with GIT_SSH_COMMAND
  4. Output the local path (can be sourced: source $(hero source <url>))
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
		flag:        .string
		name:        'key'
		abbrev:      'k'
		description: 'Environment variable name containing SSH key (e.g., MY_DEPLOY_KEY)'
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
	key_env_var := cmd.flags.get_string('key') or { '' }
	verbose := cmd.flags.get_bool('verbose') or { false }

	// Suppress all console output so only the path goes to stdout
	// This allows: source $(hero source <url>)
	if !verbose {
		console.silent_set()
	}
	defer {
		console.silent_unset()
	}

	if verbose {
		eprintln('source: file_url=${file_url}, key_env_var=${key_env_var}, output_path=${output_path}')
	}

	// Load SSH keys from environment (does NOT touch system ssh-agent)
	mut keys := sshkeys.new()
	loaded_count := keys.load_from_env()

	if verbose {
		eprintln('source: found ${loaded_count} SSH keys in environment')
		for name in keys.list() {
			eprintln('  - key: ${name}')
		}
	}

	// Find appropriate SSH key
	mut sshkey := ''
	mut key_source := ''

	if key_env_var.len > 0 {
		// Explicit key specified via --key flag
		sshkey = os.getenv(key_env_var)
		if sshkey.len == 0 {
			return error('SSH key environment variable "${key_env_var}" is not set or empty')
		}
		key_source = key_env_var
		if verbose {
			eprintln('source: using explicit key from ${key_env_var}')
		}
	} else {
		// Auto-detect best matching key for the URL
		sshkey, key_source = find_ssh_key_for_url(file_url, keys)
		if verbose {
			if sshkey.len > 0 {
				eprintln('source: auto-selected SSH key "${key_source}" (${sshkey.len} bytes)')
			} else {
				eprintln('source: no matching SSH key found, using default git auth')
			}
		}
	}

	// Use gittools to get the file path
	if verbose {
		eprintln('source: calling gittools.path()')
	}
	file_path := gittools.path(git_url: file_url, sshkey: sshkey)!
	if verbose {
		eprintln('source: resolved path=${file_path.path}')
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
// Returns (key_content, key_name)
fn find_ssh_key_for_url(url string, keys sshkeys.SSHKeys) (string, string) {
	// Parse URL to get org/provider
	mut gs := gittools.new() or { return '', '' }
	git_loc := gs.gitlocation_from_url(url) or { return '', '' }

	// Use sshkeys to find the best key for this repo
	if key := keys.find_for_repo(git_loc.account, git_loc.provider) {
		return key.content, key.name
	}

	return '', ''
}

