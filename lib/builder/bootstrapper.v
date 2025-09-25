module builder

import os
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console

const heropath_ = os.dir(@FILE) + '/../'

pub struct BootStrapper {
}

@[params]
pub struct BootstrapperArgs {
pub mut:
	name  string = 'bootstrap'
	addr  string // format:  root@something:33, 192.168.7.7:222, 192.168.7.7, despiegk@something
	reset bool
	debug bool
}

// to use do something like: export NODES="195.192.213.3" .
pub fn bootstrapper() BootStrapper {
	mut bs := BootStrapper{}
	return bs
}

pub fn (mut bs BootStrapper) run(args_ BootstrapperArgs) ! {
	mut args := args_
	addr := texttools.to_array(args.addr)
	mut b := new()!
	mut counter := 0
	for a in addr {
		counter += 1
		name := '${args.name}_${counter}'
		mut n := b.node_new(ipaddr: a, name: name)!
		n.hero_install()!
		// n.hero_install()!
	}
}

@[params]
pub struct HeroInstallArgs {
pub mut:
	reset      bool
	compile    bool
	v_analyzer bool
	debug      bool // will go in shell
}

pub fn (mut node Node) hero_install(args HeroInstallArgs) ! {
	console.print_debug('install hero')
	bootstrapper()

	myenv := node.environ_get()!
	_ := myenv['HOME'] or { return error("can't find HOME in env") }

	mut todo := []string{}
	if !args.compile {
		todo << 'curl https://raw.githubusercontent.com/incubaid/herolib/refs/heads/development/install_hero.sh > /tmp/install.sh'
		todo << 'bash /tmp/install.sh'
	} else {
		todo << "curl 'https://raw.githubusercontent.com/incubaid/herolib/refs/heads/development/install_v.sh' > /tmp/install_v.sh"
		if args.v_analyzer {
			todo << 'bash /tmp/install_v.sh --analyzer --herolib '
		} else {
			todo << 'bash /tmp/install_v.sh --herolib '
		}
	}
	node.exec_interactive(todo.join('\n'))!
}

@[params]
pub struct HeroUpdateArgs {
pub mut:
	sync_from_local bool // will sync local hero lib to the remote, then cannot use git
	sync_full       bool // sync the full herolib repo
	sync_fast       bool = true // don't hash the files, there is small chance on error
	git_reset       bool // will get the code from github at remote and reset changes
	git_pull        bool // will pull the code but not reset, will give error if it can't reset	
	branch          string
}

// execute vscript on remote node

pub fn (mut node Node) hero_update(args_ HeroUpdateArgs) ! {
	mut args := args_

	if args.sync_from_local && (args.git_reset || args.git_pull) {
		return error('if sync is asked for hero update, then cannot use git to get hero')
	}

	if args.sync_from_local {
		if args.sync_full {
			node.sync_code('hero', heropath_ + '/..', '~/code/github/incubaid/herolib',
				args.sync_fast)!
		} else {
			node.sync_code('hero_lib', heropath_, '~/code/github/incubaid/herolib/herolib',
				args.sync_fast)!
		}
		return
	}
	mut branchstr := ''
	if args.branch.len > 0 {
		branchstr = 'git checkout ${args.branch} -f && git pull' // not sure latest git pull needed
	}
	if args.git_reset {
		args.git_pull = false
		node.exec_cmd(
			cmd: '
			cd ~/code/github/incubaid/herolib
			rm -f .git/index
			git fetch --all
			git reset HEAD --hard
			git clean -xfd		
			git checkout . -f				
			${branchstr}
			'
		)!
	}
	if args.git_pull {
		node.exec_cmd(
			cmd: '
			cd ~/code/github/incubaid/herolib
			git pull
			${branchstr}		
			'
		)!
	}
}

pub fn (mut node Node) sync_code(name string, src_ string, dest string, fast_rsync bool) ! {
	mut src := pathlib.get_dir(path: os.abs_path(src_), create: false)!
	node.upload(
		source:     src.path
		dest:       dest
		ignore:     [
			'.git/*',
			'_archive',
			'.vscode',
			'examples',
		]
		delete:     true
		fast_rsync: fast_rsync
	)!
}

// sync local hero code to rmote and then compile hero
pub fn (mut node Node) hero_compile_sync() ! {
	if !node.file_exists('~/code/github/incubaid/herolib/cli/readme.md') {
		node.hero_install()!
	}
	node.hero_update()!
	node.exec_cmd(
		cmd: '
		~/code/github/incubaid/herolib/install.sh
		~/code/github/incubaid/herolib/cli/hero/compile_debug.sh		
		'
	)!
}

pub fn (mut node Node) hero_compile() ! {
	if !node.file_exists('~/code/github/incubaid/herolib/cli/readme.md') {
		node.hero_install()!
	}
	node.exec_cmd(
		cmd: '
		~/code/github/incubaid/herolib/cli/hero/compile_debug.sh		
		'
	)!
}

@[params]
pub struct VScriptArgs {
pub mut:
	path            string
	sync_from_local bool   // will sync local hero lib to the remote
	git_reset       bool   // will get the code from github at remote and reset changes
	git_pull        bool   // will pull the code but not reset, will give error if it can't reset
	branch          string // can only be used when git used
}

pub fn (mut node Node) vscript(args_ VScriptArgs) ! {
	mut args := args_
	node.hero_update(
		sync_from_local: args.sync_from_local
		git_reset:       args.git_reset
		git_pull:        args.git_pull
		branch:          args.branch
	)!
	mut p := pathlib.get_file(path: args.path, create: false)!

	node.upload(source: p.path, dest: '/tmp/remote_${p.name()}')!
	node.exec_cmd(
		cmd: '
		cd /tmp/remote
		v -w -enable-globals /tmp/remote_${p.name()}
		'
	)!
}
