module gittools

import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.develop.vscode
import freeflowuniverse.herolib.develop.sourcetree
import os

@[params]
struct GetParentDir {
pub mut:
	create bool
}

// get the key in redis where json cached info is
pub fn (mut repo GitRepo) cache_key() string {
	return '${repo.gs.cache_key()}:${repo.provider}:${repo.account}:${repo.name}'
}

pub fn (mut repo GitRepo) print_key() string {
	return '${repo.provider}:${repo.account}:${repo.name}'
}

// get path where the repo is on the fs
pub fn (repo GitRepo) path() string {
	mut repo_ := repo
	mypath := repo_.gs.coderoot.path
	return '${mypath}/${repo.provider}/${repo.account}/${repo.name}'
}

// get herolib path object
pub fn (repo GitRepo) patho() !pathlib.Path {
	return pathlib.get_dir(path: repo.path(), create: false)!
}

// gets the path of a given url within a repo
// ex: 'https://git.threefold.info/ourworld_holding/info_ourworld/src/branch/main/books/cocreation/SUMMARY.md'
// returns <repo_path>/books/cocreation/SUMMARY.md
pub fn (mut repo GitRepo) get_path_of_url(url string) !string {
	// Split the URL into components
	url_parts := url.split('/')

	// Find the index of "src" (Gitea) or "blob/tree" (GitHub)
	mut repo_root_idx := url_parts.index('src')
	if repo_root_idx == -1 {
		repo_root_idx = url_parts.index('blob')
	}

	if repo_root_idx == -1 {
		// maybe default repo url (without src and blob)
		return repo.path()
	}

	// Ensure that the repository path starts after the branch
	if url_parts.len < repo_root_idx + 2 {
		return error('Invalid URL format: Missing branch or file path')
	}

	// Extract the path inside the repository
	path_in_repo := url_parts[repo_root_idx + 3..].join('/')

	// Construct the full path
	return '${repo.path()}/${path_in_repo}'
}

// Relative path inside the gitstructure, pointing to the repo
pub fn (repo GitRepo) get_relative_path() !string {
	mut mypath := repo.patho()!
	mut repo_ := repo
	return mypath.path_relative(repo_.gs.coderoot.path) or { panic("couldn't get relative path") }
}

// path where we use ~ and its the full path
pub fn (repo GitRepo) get_human_path() !string {
	mut mypath := repo.patho()!.path.replace(os.home_dir(), '~')
	return mypath
}

pub fn (mut repo GitRepo) get_parent_dir(args GetParentDir) !string {
	repo_path := repo.path()
	parent_dir := os.dir(repo_path)
	if !os.exists(parent_dir) && !args.create {
		return error('Parent directory does not exist: ${parent_dir}')
	}
	os.mkdir_all(parent_dir)!
	return parent_dir
}

// DONT THINK ITS GOOD TO GIVE THE BRANCH
// @[params]
// pub struct GetRepoUrlArgs {
// pub mut:
// 	with_branch bool // // If true, return the repo URL for an exact branch.
// }

// url_get returns the URL of a git address
fn (self GitRepo) get_repo_url_for_clone() !string {
	// WHY do we do following, now uncommented, the following code dispisses the ssh url part
	// url := self.status_wanted.url
	// if true{panic(url)}
	// if url.len != 0 {
	// 	if args.with_branch {
	// 		return '${url}/tree/${self.status_local.branch}'
	// 	}
	// 	return url
	// }

	// Check if SSH agent is loaded (avoid importing sshagent to prevent circular dependency)
	ssh_check := os.execute('ssh-add -l')
	if ssh_check.exit_code == 0 {
		return self.get_ssh_url()!
	} else {
		return self.get_http_url()!
	}
}

fn (self GitRepo) get_ssh_url() !string {
	mut provider := self.provider
	if provider == 'github' {
		provider = 'github.com'
	}
	return 'git@${provider}:${self.account}/${self.name}.git'
}

fn (self GitRepo) get_http_url() !string {
	mut provider := self.provider
	if provider == 'github' {
		provider = 'github.com'
	}
	return 'https://${provider}/${self.account}/${self.name}'
}

// Return rich path object from our library hero lib

pub fn (mut repo GitRepo) display_current_status() ! {
	staged_changes := repo.get_changes_staged()!
	unstaged_changes := repo.get_changes_unstaged()!

	console.print_header('Staged changes:')
	for f in staged_changes {
		console.print_green('\t- ${f}')
	}

	console.print_header('Unstaged changes:')
	if unstaged_changes.len == 0 {
		console.print_stderr('No unstaged changes; the changes need to be committed.')
		return
	}

	for f in unstaged_changes {
		console.print_stderr('\t- ${f}')
	}
}

// Opens SourceTree for the Git repo
pub fn (mut repo GitRepo) sourcetree() ! {
	sourcetree.open(path: repo.path())!
}

// Opens Visual Studio Code for the repo
pub fn (mut repo GitRepo) open_vscode() ! {
	path := repo.path()
	mut vs_code := vscode.new(path)
	vs_code.open()!
}
