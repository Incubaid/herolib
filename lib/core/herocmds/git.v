module herocmds

import freeflowuniverse.herolib.develop.gittools
import freeflowuniverse.herolib.ui.console
import cli { Command, Flag }
import os

pub fn cmd_git(mut cmdroot Command) {
	mut cmd_run := Command{
		name:        'git'
		description: 'Work with your repos, list, commit, pull, reload, ...\narg is url or path, or nothing if for all repos. \nCheck -f for filter. '
		// required_args: 1
		usage:         'sub commands of git are '
		execute:       cmd_git_execute
		sort_commands: true
	}

	mut clone_command := Command{
		sort_flags:  true
		name:        'clone'
		execute:     cmd_git_execute
		description: 'will clone the repo based on a given url, e.g. https://github.com/freeflowuniverse/webcomponents/tree/main'
	}

	mut pull_command := Command{
		sort_flags:  true
		name:        'pull'
		execute:     cmd_git_execute
		description: 'will pull the content, if it exists for each found repo.'
	}

	mut push_command := Command{
		sort_flags:  true
		name:        'push'
		execute:     cmd_git_execute
		description: 'will push the content, if it exists for each found repo.'
	}

	mut commit_command := Command{
		sort_flags:  true
		name:        'commit'
		execute:     cmd_git_execute
		description: 'will commit newly found content, specify the message.'
	}

	mut reload_command := Command{
		sort_flags:  true
		name:        'reload'
		execute:     cmd_git_execute
		description: 'reset the cache of the repos, they are kept for 24h in local redis, this will reload all info.'
	}

	mut delete_command := Command{
		sort_flags:  true
		name:        'delete'
		execute:     cmd_git_execute
		description: 'delete the repo.'
	}

	mut list_command := Command{
		sort_flags:  true
		name:        'list'
		execute:     cmd_git_execute
		description: 'list all repos.\nThe Argument is url or path, otherwise use -f filter.'
	}

	mut sourcetree_command := Command{
		sort_flags:  true
		name:        'sourcetree'
		execute:     cmd_git_execute
		description: 'Open sourcetree on found repos, will do for max 5.'
	}

	mut editor_command := Command{
		sort_flags:  true
		name:        'edit'
		execute:     cmd_git_execute
		description: 'Open visual studio code on found repos, will do for max 5.'
	}

	mut exists_command := Command{
		sort_flags:  true
		name:        'exists'
		execute:     cmd_git_execute
		description: 'Check if git repository exists. Returns exit code 0 if exists, 1 if not.'
	}

	mut cmd_path := Command{
		sort_flags:  true
		name:        'path'
		execute:     cmd_git_execute
		description: 'Get the path to a git repository. Use with cd $(hero git path <url>)'
	}

	cmd_path.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'url'
		abbrev:      'u'
		description: 'url for git path operation, so we know which repo path to get'
	})

	mut allcmdsref := [&list_command, &clone_command, &push_command, &pull_command, &commit_command,
		&reload_command, &delete_command, &sourcetree_command, &editor_command, &exists_command]

	for mut c in allcmdsref {
		c.add_flag(Flag{
			flag:        .bool
			required:    false
			name:        'silent'
			abbrev:      's'
			description: 'be silent.'
		})

		c.add_flag(Flag{
			flag:        .bool
			required:    false
			name:        'load'
			abbrev:      'l'
			description: 'reload the data in cache for selected repos.'
		})

		c.add_flag(Flag{
			flag:        .string
			required:    false
			name:        'filter'
			abbrev:      'f'
			description: 'filter the repos by name or path.'
		})
	}

	mut allcmdscommit := [&push_command, &pull_command, &commit_command]

	for mut c in allcmdscommit {
		c.add_flag(Flag{
			flag:        .string
			required:    false
			name:        'message'
			abbrev:      'm'
			description: 'which message to use for commit.'
		})
	}

	mut urlcmds := [&clone_command, &pull_command, &push_command, &editor_command, &sourcetree_command]
	for mut c in urlcmds {
		c.add_flag(Flag{
			flag:        .bool
			required:    false
			name:        'reset'
			description: 'force a pull and reset changes.'
		})
		c.add_flag(Flag{
			flag:        .bool
			required:    false
			name:        'pull'
			description: 'force a pull.'
		})
		c.add_flag(Flag{
			flag:        .bool
			required:    false
			name:        'pullreset'
			abbrev:      'pr'
			description: 'force a pull and do a reset.'
		})
		c.add_flag(Flag{
			flag:        .bool
			required:    false
			name:        'recursive'
			description: 'if we do a clone or a pull we also get the git submodules.'
		})
	}

	for mut c_ in allcmdsref {
		mut c := *c_
		c.add_flag(Flag{
			flag:        .string
			required:    false
			name:        'coderoot'
			abbrev:      'cr'
			description: 'If you want to use another directory for your code root.'
		})
		c.add_flag(Flag{
			flag:        .bool
			required:    false
			name:        'script'
			abbrev:      'z'
			description: 'to use in scripts, will not run interative and ask questions.'
		})
		cmd_run.add_command(c)
	}
	cmd_run.add_command(cmd_path)
	cmdroot.add_command(cmd_run)
}

fn cmd_git_execute(cmd Command) ! {
	mut is_silent := cmd.flags.get_bool('silent') or { false }
	mut reload := cmd.flags.get_bool('load') or { false }

	// path command is silent so it just outputs repo path
	if is_silent || cmd.name == 'path' {
		console.silent_set()
	}
	mut coderoot := cmd.flags.get_string('coderoot') or { '' }

	if 'CODEROOT' in os.environ() && coderoot == '' {
		coderoot = os.environ()['CODEROOT']
	}

	mut gs := gittools.new(coderoot: coderoot)!

	// create the filter for doing group actions, or action on 1 repo
	mut filter := ''
	mut url := ''
	mut path := ''

	if cmd.args.len > 0 {
		arg1 := cmd.args[0]
		if arg1.starts_with('git') || arg1.starts_with('http') {
			url = arg1
		} else {
			path = arg1
		}
	}

	if cmd.name in gittools.gitcmds.split(',') {
		mut pull := cmd.flags.get_bool('pull') or { false }
		mut reset := cmd.flags.get_bool('reset') or { false }
		mut recursive := cmd.flags.get_bool('recursive') or { false }
		if cmd.flags.get_bool('pullreset') or { false } {
			pull = true
			reset = true
		}

		mypath := gs.do(
			filter:    cmd.flags.get_string('filter') or { '' }
			reload:    reload
			recursive: recursive
			cmd:       cmd.name
			script:    cmd.flags.get_bool('script') or { false }
			pull:      pull
			reset:     reset
			msg:       cmd.flags.get_string('message') or { '' }
			url:       url
			path:      path
		)!
		if cmd.name == 'path' {
			print('${mypath}\n')
		}
		return
	} else {
		// console.print_debug(" Supported commands are: ${gittools.gitcmds}")
		return error(cmd.help_message())
	}
}
