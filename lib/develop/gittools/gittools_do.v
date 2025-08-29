module gittools

import freeflowuniverse.herolib.ui as gui
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console
import os

pub const gitcmds = 'clone,commit,pull,push,delete,reload,list,edit,sourcetree,path,exists'

@[params]
pub struct ReposActionsArgs {
pub mut:
	cmd       string // clone,commit,pull,push,delete,reload,list,edit,sourcetree
	filter    string // if used will only show the repo's which have the filter string inside
	repo      string
	account   string
	provider  string
	msg       string
	url       string
	branch    string
	path      string // path to start from
	recursive bool
	pull      bool
	reload    bool // means reload the info into the cache
	script    bool = true // run non interactive
	reset     bool = true // means we will lose changes (only relevant for clone, pull)
}

// do group actions on repo
// args
//```
// cmd      string // clone,commit,pull,push,delete,reload,list,edit,sourcetree,cd
// filter   string // if used will only show the repo's which have the filter string inside
// repo     string
// account  string
// provider string
// msg      string
// url      string
// pull     bool
// reload bool //means reload the info into the cache
// script   bool = true // run non interactive
// reset    bool = true // means we will lose changes (only relevant for clone, pull)
//```
pub fn (mut gs GitStructure) do(args_ ReposActionsArgs) !string {
	mut args := args_
	console.print_debug('git do ${args.cmd}')
	// println(args)
	// $dbg;

	if args.path.len > 0 && args.url.len > 0 {
		panic('bug')
	}
	if args.path.len > 0 && args.filter.len > 0 {
		panic('bug')
	}
	if args.url.len > 0 && args.filter.len > 0 {
		panic('bug')
	}

	if args.path != '' {
		if args.path.contains('*') {
			panic('bug')
		}
		if args.path == '.' {
			// means current dir
			args.path = os.getwd()
			mut curdiro := pathlib.get_dir(path: args.path, create: false)!
			mut parentpath := curdiro.parent_find('.git') or { pathlib.Path{} }
			args.path = curdiro.path
		}
		if !os.exists(args.path) {
			return error('Path does not exist: ${args.path}')
		}

		r0 := gs.repo_init_from_path_(args.path)!
		args.repo = r0.name
		args.account = r0.account
		args.provider = r0.provider
	} else {
		if args.url.len > 0 {
			if !(args.repo == '' && args.account == '' && args.provider == '' && args.filter == '') {
				return error('when specify url cannot specify repo, account, profider or filter')
			}
			mut r0 := gs.get_repo(url: args.url)!
			args.repo = r0.name
			args.account = r0.account
			args.provider = r0.provider
		}
	}

	args.cmd = args.cmd.trim_space().to_lower()

	mut ui := gui.new()!

	mut repos := gs.get_repos(
		filter:   args.filter
		name:     args.repo
		account:  args.account
		provider: args.provider
	)!

	if repos.len<4 || args.cmd in 'pull,push,commit,delete'.split(',') {
		args.reload = true
	}

	for mut repo in repos {
		repo.status_update(reset: args.reload || args.cmd == 'reload')!
	}

	if args.cmd == 'list' {
		gs.repos_print(
			filter:   args.filter
			name:     args.repo
			account:  args.account
			provider: args.provider
		)!
		return ''
	}

	if args.cmd == 'exists' {
		return gs.check_repos_exist(args)
	}

	if args.cmd == 'path' {
		if repos.len == 0 {
			return error('No repository found for path command')
		}
		if repos.len > 1 {
			return error('Multiple repositories found for path command, please be more specific')
		}
		return repos[0].path()
	}

	// means we are on 1 repo
	if args.cmd in 'sourcetree,edit'.split(',') {
		if repos.len == 0 {
			return error('please specify at least 1 repo for cmd:${args.cmd}')
		}
		if repos.len > 4 {
			return error('more than 4 repo found for cmd:${args.cmd}')
		}
		for mut r in repos {
			if args.cmd == 'edit' {
				r.open_vscode()!
			}
			if args.cmd == 'sourcetree' {
				r.sourcetree()!
			}
		}
		return ''
	}

	if args.cmd == 'clone' {
		if args.url.len == 0 {
			return error('URL needs to be specified for clone operation.')
		}
		gs.clone(url: args.url, recursive: args.recursive)!
		return ''
	}

	if args.cmd in 'pull,push,commit,delete'.split(',') {
		gs.repos_print(
			filter:   args.filter
			name:     args.repo
			account:  args.account
			provider: args.provider
		)!

		mut need_commit0 := false
		mut need_pull0 := false
		mut need_push0 := false

		if repos.len == 0 {
			console.print_header(' - nothing to do.')
			return ''
		}

		// check on repos who needs what
		for mut g in repos {
			if args.cmd == 'push' && g.need_push_or_pull()! {
				need_push0 = true
			}

			if args.cmd in ['push', 'pull'] && (need_push0 || g.need_push_or_pull()!) {
				need_pull0 = true
			}

			if args.cmd in ['push', 'pull', 'commit'] && (g.need_commit()!) {
				need_commit0 = true
			}

			// console.print_debug(" --- status repo ${g.name}'s\n    need_commit0:${need_commit0} \n    need_pull0:${need_pull0}  \n    need_push0:${need_push0}")
		}

		// console.print_debug(" --- status all repo's\n    need_commit0:${need_commit0} \n    need_pull0:${need_pull0}  \n    need_push0:${need_push0}")

		// $dbg;

		mut ok := false
		if need_commit0 || need_pull0 || need_push0 {
			mut out := '\n\n** NEED TO '
			if need_commit0 {
				out += 'COMMIT '
			}
			if need_pull0 {
				out += 'PULL '
			}
			if need_push0 {
				out += 'PUSH '
			}
			if args.reset {
				out += ' (changes will be lost!)'
			}
			console.print_debug(out + ' ** \n')
			if args.script {
				ok = true
			} else {
				if need_commit0 || need_pull0 || need_push0 {
					ok = ui.ask_yesno(question: 'Is above ok?')!
				} else {
					console.print_green('nothing to do')
				}
			}

			if ok == false {
				return error('cannot continue with action, you asked me to stop.\n${args}')
			}

			if need_commit0 {
				if args.msg.len == 0 && args.script {
					return error('message needs to be specified for commit.')
				}
				if args.msg.len == 0 {
					args.msg = ui.ask_question(
						question: 'commit message for the actions: '
					)!
				}
			}
		}

		if args.cmd == 'delete' {
			if args.script {
				ok = true
			} else {
				ok = ui.ask_yesno(question: 'Is it ok to delete above repos? (DANGEROUS)')!
			}

			if ok == false {
				return error('cannot continue with action, you asked me to stop.\n${args}')
			}
		}

		mut has_changed := false
		for mut g in repos {
			need_push_repo := need_push0 && g.need_push_or_pull()!
			need_pull_repo := need_push_repo || (need_pull0 && g.need_push_or_pull()!)
			need_commit_repo := need_push_repo || need_pull_repo
				|| (need_commit0 && g.need_commit()!)

			// console.print_debug(" --- git_do ${g.cache_key()} \n    need_commit_repo:${need_commit_repo} \n    need_pull_repo:${need_pull_repo}  \n    need_push_repo:${need_push_repo}")

			if need_commit_repo {
				mut msg := args.msg
				console.print_header(' - commit ${g.account}/${g.name}')
				g.commit(msg)!
				has_changed = true
			}
			if has_changed || need_pull_repo {
				if args.reset {
					console.print_header(' - remove changes ${g.account}/${g.name}')
					g.remove_changes()!
				}
				console.print_header(' - pull ${g.account}/${g.name}')
				g.pull()!
				has_changed = true
			}
			if has_changed || need_push_repo {
				console.print_header(' - push ${g.account}/${g.name}')
				g.push()!
				has_changed = true
			}
			if args.cmd == 'delete' {
				g.delete()!
				has_changed = true
			}
		}

		if has_changed {
			// console.clear()
			console.print_header('Completed required actions.\n')

			gs.repos_print(
				filter:   args.filter
				name:     args.repo
				account:  args.account
				provider: args.provider
			)!
		}

		return ''
	}
	// end for the commit, pull, push, delete

	$if debug {
		print_backtrace()
	}
	return error('did not find cmd: ${args.cmd}')
}
