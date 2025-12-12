module gittools

import incubaid.herolib.ui.console
import os

@[params]
pub struct GitCloneArgs {
pub mut:
	url       string // Git URL to clone
	sshkey    string // SSH key content (optional)
	recursive bool   // If true, also clone submodules
	light     bool   // If true, clones only the last history for all branches (clone with only 1 level deep)
}

// Clones a new repository into the git structure based on the provided arguments.
pub fn (mut gitstructure GitStructure) clone(args GitCloneArgs) !&GitRepo {
	if args.url.len == 0 {
		return error('url needs to be specified when doing a clone.')
	}

	console.print_debug('clone: url=${args.url}, sshkey_len=${args.sshkey.len}')
	console.print_header('Git clone from the URL: ${args.url}.')
	git_location := gitstructure.gitlocation_from_url(args.url)!
	console.print_debug('clone: provider=${git_location.provider}, account=${git_location.account}, name=${git_location.name}')

	// Initialize a new GitRepo instance
	mut repo := GitRepo{
		gs:           &gitstructure
		provider:     git_location.provider
		account:      git_location.account
		name:         git_location.name
		deploysshkey: args.sshkey
		config:       GitRepoConfig{}
		status:       GitStatus{}
	}

	// Add the new repo to the gitstructure's repos map
	key_ := repo.cache_key()
	gitstructure.repos[key_] = &repo

	if repo.exists() {
		console.print_green('Repository already exists at ${repo.path()}')
		repo.load_internal() or {
			console.print_debug('Could not load existing repository status: ${err}')
		}
		return &repo
	}

	// Check if path exists but is not a git repository
	if os.exists(repo.path()) {
		return error('Path exists but is not a git repository: ${repo.path()}')
	}

	parent_dir := repo.get_parent_dir(create: true)!
	console.print_debug('clone: parent_dir=${parent_dir}')

	mut extra := ''
	if args.light {
		extra = '--depth 1 --no-single-branch '
	}

	cfg := gitstructure.config()!
	mut cmd := ''
	mut temp_key_path := ''

	// Determine SSH key to use: args.sshkey (content) > cfg.ssh_key_path (file path)
	if args.sshkey.len > 0 {
		// Write SSH key content to temp file
		temp_key_path = '/tmp/hero_git_key_${git_location.account}'
		console.print_debug('clone: writing SSH key to ${temp_key_path}')
		
		mut final_key := args.sshkey
		if !final_key.ends_with('\n') {
			final_key = final_key + '\n'
		}
		os.write_file(temp_key_path, final_key) or {
			return error('Failed to write SSH key to temp file: ${err}')
		}
		os.chmod(temp_key_path, 0o600) or {
			return error('Failed to set permissions on SSH key file: ${err}')
		}
		
		clone_url := repo.get_ssh_url()!
		console.print_debug('clone: using SSH URL=${clone_url}')
		cmd = 'cd ${parent_dir} && GIT_SSH_COMMAND="ssh -i ${temp_key_path} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" git clone ${extra} ${clone_url} ${repo.name}'
	} else if cfg.ssh_key_path.len > 0 {
		console.print_debug('clone: using config ssh_key_path=${cfg.ssh_key_path}')
		clone_url := repo.get_ssh_url()!
		cmd = 'cd ${parent_dir} && GIT_SSH_COMMAND="ssh -i ${cfg.ssh_key_path}" git clone ${extra} ${clone_url} ${repo.name}'
	} else {
		console.print_debug('clone: no SSH key, using default URL')
		clone_url := repo.get_repo_url_for_clone()!
		cmd = 'cd ${parent_dir} && git clone ${extra} ${clone_url} ${repo.name}'
	}

	console.print_debug('clone: executing: ${cmd}')
	result := os.execute(cmd)

	// Clean up temp key file
	if temp_key_path.len > 0 && os.exists(temp_key_path) {
		os.rm(temp_key_path) or {}
	}

	if result.exit_code != 0 {
		return error('Cannot clone the repository due to: \n${result.output}')
	}

	// The repo is now cloned. Load its initial status.
	repo.load_internal()!

	console.print_green("The repository '${repo.name}' cloned into ${parent_dir}.")

	return &repo
}
