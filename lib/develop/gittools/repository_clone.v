module gittools

import incubaid.herolib.ui.console
import os
// import incubaid.herolib.core.pathlib

@[params]
pub struct GitCloneArgs {
pub mut:
	// only url needed because is a clone
	url       string
	sshkey    string
	recursive bool // If true, also clone submodules
	light     bool // If true, clones only the last history for all branches (clone with only 1 level deep)
}

// Get SSH key from environment variable based on org/account name
// Convention: {ORG}_SSH_KEY (uppercase), e.g., MYCELIUM_SSH_KEY
// Falls back to SECRETS_SSH_KEY if org-specific key not found
fn get_org_ssh_key(account string) ?string {
	// Try org-specific key first (e.g., MYCELIUM_SSH_KEY)
	org_key_name := '${account.to_upper()}_SSH_KEY'
	org_key := os.getenv(org_key_name)
	if org_key.len > 0 {
		console.print_debug('Using org-specific SSH key: ${org_key_name}')
		return org_key
	}

	// Fall back to generic SECRETS_SSH_KEY
	secrets_key := os.getenv('SECRETS_SSH_KEY')
	if secrets_key.len > 0 {
		console.print_debug('Using fallback SECRETS_SSH_KEY')
		return secrets_key
	}

	return none
}

// Write SSH key to temp file and return the path
// Returns none if no key content provided
fn write_temp_ssh_key(key_content string, identifier string) ?string {
	if key_content.len == 0 {
		return none
	}

	// Normalize key: handle escaped newlines from env vars
	mut final_key := key_content
	if final_key.contains('\\n') {
		final_key = final_key.replace('\\n', '\n')
	}
	final_key = final_key.trim_space()
	if !final_key.ends_with('\n') {
		final_key = final_key + '\n'
	}

	// Write to temp file
	temp_path := '/tmp/hero_git_key_${identifier}'
	os.write_file(temp_path, final_key) or { return none }
	os.chmod(temp_path, 0o600) or { return none }

	return temp_path
}

// Clones a new repository into the git structure based on the provided arguments.
pub fn (mut gitstructure GitStructure) clone(args GitCloneArgs) !&GitRepo {
	if args.url.len == 0 {
		return error('url needs to be specified when doing a clone.')
	}

	console.print_header('Git clone from the URL: ${args.url}.')
	// gitlocatin comes just from the url, not from fs of whats already there
	git_location := gitstructure.gitlocation_from_url(args.url)!

	// Check for org-specific SSH key from environment if none provided
	mut effective_sshkey := args.sshkey
	if effective_sshkey.len == 0 {
		if org_key := get_org_ssh_key(git_location.account) {
			effective_sshkey = org_key
		}
	}

	// Initialize a new GitRepo instance
	mut repo := GitRepo{
		gs:           &gitstructure
		provider:     git_location.provider
		account:      git_location.account
		name:         git_location.name
		deploysshkey: effective_sshkey // Use the sshkey from args or env
		config:       GitRepoConfig{} // Initialize with default config
		status:       GitStatus{}     // Initialize with default status
	}

	// Add the new repo to the gitstructure's repos map
	key_ := repo.cache_key()
	gitstructure.repos[key_] = &repo

	if repo.exists() {
		console.print_green('Repository already exists at ${repo.path()}')
		// Load the existing repository status
		repo.load_internal() or {
			console.print_debug('Could not load existing repository status: ${err}')
		}
		return &repo
	}

	// Check if path exists but is not a git repository
	if os.exists(repo.path()) {
		return error('Path exists but is not a git repository: ${repo.path()}')
	}

	if effective_sshkey.len > 0 {
		repo.set_sshkey(effective_sshkey)!
	}

	parent_dir := repo.get_parent_dir(create: true)!

	mut extra := ''
	if args.light {
		extra = '--depth 1 --no-single-branch '
	}

	// the url needs to be http if no agent, otherwise its ssh, the following code will do this
	mut cmd := 'cd ${parent_dir} && git clone ${extra} ${repo.get_repo_url_for_clone()!} ${repo.name}'

	mut sshkey_include := ''
	mut temp_key_path := ''
	cfg := gitstructure.config()!

	// First check if we have an SSH key from env that needs to be written to temp file
	if effective_sshkey.len > 0 && cfg.ssh_key_path.len == 0 {
		// Write the key content to a temp file
		if key_path := write_temp_ssh_key(effective_sshkey, git_location.account) {
			temp_key_path = key_path
			sshkey_include = 'GIT_SSH_COMMAND="ssh -i ${temp_key_path} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" '
			cmd = 'cd ${parent_dir} && ${sshkey_include}git clone ${extra} ${repo.get_ssh_url()!} ${repo.name}'
		}
	} else if cfg.ssh_key_path.len > 0 {
		sshkey_include = "GIT_SSH_COMMAND=\"ssh -i ${cfg.ssh_key_path}\" "
		cmd = 'cd ${parent_dir} && ${sshkey_include}git clone ${extra} ${repo.get_ssh_url()!} ${repo.name}'
	}

	console.print_debug(cmd)
	result := os.execute(cmd)

	// Clean up temp key file if we created one
	if temp_key_path.len > 0 && os.exists(temp_key_path) {
		os.rm(temp_key_path) or {}
	}

	if result.exit_code != 0 {
		return error('Cannot clone the repository due to: \n${result.output}')
	}

	// The repo is now cloned. Load its initial status.
	repo.load_internal()!

	console.print_green("The repository '${repo.name}' cloned into ${parent_dir}.")

	return &repo // Return the initialized repo
}
