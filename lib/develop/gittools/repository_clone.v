module gittools

import freeflowuniverse.herolib.ui.console
import os
// import freeflowuniverse.herolib.core.pathlib

@[params]
pub struct GitCloneArgs {
pub mut:
	// only url needed because is a clone
	url       string
	sshkey    string
	recursive bool // If true, also clone submodules
	light     bool // If true, clones only the last history for all branches (clone with only 1 level deep)
}

// Clones a new repository into the git structure based on the provided arguments.
pub fn (mut gitstructure GitStructure) clone(args GitCloneArgs) !&GitRepo {
	if args.url.len == 0 {
		return error('url needs to be specified when doing a clone.')
	}

	console.print_header('Git clone from the URL: ${args.url}.')
	// gitlocatin comes just from the url, not from fs of whats already there
	git_location := gitstructure.gitlocation_from_url(args.url)!

	// Initialize a new GitRepo instance
	mut repo := GitRepo{
		gs:           &gitstructure
		provider:     git_location.provider
		account:      git_location.account
		name:         git_location.name
		deploysshkey: args.sshkey // Use the sshkey from args
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

	if args.sshkey.len > 0 {
		repo.set_sshkey(args.sshkey)!
	}

	parent_dir := repo.get_parent_dir(create: true)!

	mut extra := ''
	if args.light {
		extra = '--depth 1 --no-single-branch '
	}

	// the url needs to be http if no agent, otherwise its ssh, the following code will do this
	mut cmd := 'cd ${parent_dir} && git clone ${extra} ${repo.get_repo_url_for_clone()!} ${repo.name}'

	mut sshkey_include := ''
	cfg := gitstructure.config()!
	if cfg.ssh_key_path.len > 0 {
		sshkey_include = "GIT_SSH_COMMAND=\"ssh -i ${cfg.ssh_key_path}\" "
		cmd = 'cd ${parent_dir} && ${sshkey_include}git clone ${extra} ${repo.get_ssh_url()!} ${repo.name}'
	}

	console.print_debug(cmd)
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Cannot clone the repository due to: \n${result.output}')
	}

	// The repo is now cloned. Load its initial status.
	repo.load_internal()!

	console.print_green("The repository '${repo.name}' cloned into ${parent_dir}.")

	return &repo // Return the initialized repo
}
