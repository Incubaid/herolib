// lib/develop/gittools/repository.v
module gittools

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.core as osal
import os

// commit stages all changes and commits them with the provided message.
pub fn (mut repo GitRepo) commit(msg string) ! {
	repo.status_update()!
	if !repo.need_commit()! {
		console.print_debug('No changes to commit for ${repo.path()}.')
		return
	}

	if msg == '' {
		return error('Commit message cannot be empty.')
	}
	repo.exec('add . -A')!
	repo.exec('commit -m "${msg}"') or {
		// A common case for failure is when changes are only whitespace changes and git is configured to ignore them.
		console.print_debug('Could not commit in ${repo.path()}. Maybe nothing to commit? Error: ${err}')
		return
	}
	console.print_green("Committed changes in '${repo.path()}' with message: '${msg}'.")
	repo.cache_last_load_clear()!
}

// push local changes to the remote repository.
pub fn (mut repo GitRepo) push() ! {
	repo.status_update()!
	if !repo.need_push()! {
		console.print_header('Nothing to push for ${repo.path()}. Already up-to-date.')
		return
	}

	url := repo.get_repo_url_for_clone()!
	console.print_header('Pushing changes to ${url}')
	// This will push the current branch to its upstream counterpart.
	// --set-upstream is useful for new branches.
	repo.exec('push --set-upstream origin ${repo.status.branch}')!
	console.print_green('Changes pushed successfully.')
	repo.cache_last_load_clear()!
}

@[params]
pub struct PullArgs {
pub mut:
	submodules bool // if we want to pull for submodules
	reset      bool // if true, will reset local changes before pulling
}

// pull remote content into the repository.
pub fn (mut repo GitRepo) pull(args PullArgs) ! {
	repo.status_update()!

	if args.reset {
		repo.reset()!
	}

	if repo.need_commit()! {
		return error('Cannot pull in ${repo.path()} due to uncommitted changes. Either commit them or use the reset:true option.')
	}

	repo.exec('pull')!

	if args.submodules {
		repo.update_submodules()!
	}

	repo.cache_last_load_clear()!
	console.print_green('Changes pulled successfully from ${repo.path()}.')
}

// branch_create creates a new branch.
pub fn (mut repo GitRepo) branch_create(branchname string) ! {
	repo.exec('branch ${branchname}')!
	repo.cache_last_load_clear()!
	console.print_green('Branch ${branchname} created successfully in ${repo.path()}.')
}

// branch_switch switches to a different branch.
pub fn (mut repo GitRepo) branch_switch(branchname string) ! {
	if repo.need_commit()! {
		return error('Cannot switch branch in ${repo.path()} due to uncommitted changes.')
	}
	repo.exec('switch ${branchname}')!
	console.print_green('Switched to branch ${branchname} in ${repo.path()}.')
	repo.status.branch = branchname
	repo.status.tag = ''
	repo.cache_last_load_clear()!
}

// tag_create creates a new tag.
pub fn (mut repo GitRepo) tag_create(tagname string) ! {
	repo.exec('tag ${tagname}')!
	console.print_green('Tag ${tagname} created successfully in ${repo.path()}.')
	repo.cache_last_load_clear()!
}

// tag_switch checks out a specific tag.
pub fn (mut repo GitRepo) tag_switch(tagname string) ! {
	if repo.need_commit()! {
		return error('Cannot switch to tag in ${repo.path()} due to uncommitted changes.')
	}
	repo.exec('checkout tags/${tagname}')!
	console.print_green('Switched to tag ${tagname} in ${repo.path()}.')
	repo.status.branch = ''
	repo.status.tag = tagname
	repo.cache_last_load_clear()!
}

// tag_exists checks if a tag exists in the repository.
pub fn (mut repo GitRepo) tag_exists(tag string) !bool {
	repo.status_update()!
	return tag in repo.status.tags
}

// delete removes the repository from the filesystem and cache.
pub fn (mut repo GitRepo) delete() ! {
	repo_path := repo.path()
	key := repo.cache_key()
	repo.cache_delete()!
	osal.rm(repo_path)!
	repo.gs.repos.delete(key)
}

// gitlocation_from_path creates a GitLocation from a path inside this repository.
pub fn (mut repo GitRepo) gitlocation_from_path(path string) !GitLocation {
	if path.starts_with('/') || path.starts_with('~') {
		return error('Path must be relative, cannot start with / or ~')
	}
	repo.status_update()!

	mut git_path := repo.patho()!
	repo_path := git_path.path
	abs_path := os.abs_path(path)

	if !abs_path.starts_with(repo_path) {
		return error('Path ${path} is not inside the git repository at ${repo_path}')
	}

	rel_path := abs_path[repo_path.len + 1..]
	if !os.exists(abs_path) {
		return error('Path does not exist inside the repository: ${abs_path}')
	}

	mut branch_or_tag := repo.status.branch
	if repo.status.tag != '' {
		branch_or_tag = repo.status.tag
	}

	return GitLocation{
		provider:      repo.provider
		account:       repo.account
		name:          repo.name
		branch_or_tag: branch_or_tag
		path:          rel_path
	}
}

// init validates the repository's configuration and path.
pub fn (mut repo GitRepo) init() ! {
	if repo.provider == '' || repo.account == '' || repo.name == '' {
		return error('Repo identifier (provider, account, name) cannot be empty for ${repo.path()}')
	}

	if !os.exists(repo.path()) {
		return error('Path does not exist: ${repo.path()}')
	}
}

// set_sshkey configures the repository to use a specific SSH key for git operations.
fn (mut repo GitRepo) set_sshkey(key_name string) ! {
	ssh_dir := os.join_path(os.home_dir(), '.ssh')
	key := osal.get_ssh_key(key_name, directory: ssh_dir) or {
		return error('SSH Key with name ${key_name} not found.')
	}
	private_key_path := key.private_key_path()!
	repo.exec('config core.sshCommand "ssh -i ${private_key_path}"')!
	repo.deploysshkey = key_name
}

// remove_changes hard resets the repository to HEAD and cleans untracked files.
pub fn (mut repo GitRepo) remove_changes() ! {
	repo.status_update()!
	if repo.status.has_changes {
		console.print_header('Removing all local changes in ${repo.path()}')
		repo.exec('reset --hard HEAD && git clean -fdx')!
		repo.cache_last_load_clear()!
	}
}

// reset is an alias for remove_changes.
pub fn (mut repo GitRepo) reset() ! {
	repo.remove_changes()!
}

// update_submodules initializes and updates all submodules.
fn (mut repo GitRepo) update_submodules() ! {
	repo.exec('submodule update --init --recursive')!
}

// exec executes a command within the repository's directory.
// This is the designated wrapper for all git commands for this repo.
fn (repo GitRepo) exec(cmd_ string) !string {
	repo_path := repo.path()

	// if cmd_.starts_with("pull ") || cmd_.starts_with("push ") || cmd_.starts_with("fetch "){
	// 	//means we need to be able to fetch from remote repo, check we have a key registered e.g. for gitea
	// 	$dbg;

	// }
	cmd := 'cd ${repo_path} && git ${cmd_}'
	// console.print_debug(cmd)
	r := os.execute(cmd)
	if r.exit_code != 0 {
		return error('Repo command failed:\nCMD: ${cmd}\nOUT: ${r.output})')
	}
	return r.output.trim_space()
}
