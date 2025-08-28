module herolib

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.installers.base
import freeflowuniverse.herolib.installers.lang.vlang
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.develop.gittools
import os
// install herolib will return true if it was already installed

@[params]
pub struct InstallArgs {
pub mut:
	git_pull  bool
	git_reset bool
	reset     bool // means reinstall
}

pub fn install(args InstallArgs) ! {
	// install herolib if it was already done will return true
	console.print_header('install herolib (reset: ${args.reset})')
	// osal.package_refresh()!
	if args.reset {
		osal.done_reset()!
	}
	base.install(develop: true)!
	vlang.install(reset: args.reset)!
	vlang.v_analyzer_install(reset: args.reset)!

	mut gs := gittools.new()!
	gs.config()!.light = true // means we clone depth 1

	mut repo := gs.get_repo(
		pull:  args.git_pull
		reset: args.git_reset
		url:   'https://github.com/freeflowuniverse/herolib/tree/development/lib'
	)!

	// mut repo2 := gs.get_repo(
	// 	pull:  args.git_pull
	// 	reset: args.git_reset
	// 	url:   'https://github.com/freeflowuniverse/webcomponents/tree/main/webcomponents'
	// )!

	mut path1 := repo.path()
	// mut path2 := repo2.get_path()!

	mut path1p := pathlib.get_dir(path: path1, create: false)!
	// mut path2p := pathlib.get_dir(path: path2, create: false)!
	path1p.link('${os.home_dir()}/.vmodules/freeflowuniverse/herolib', true)!
	// path2p.link('${os.home_dir()}/.vmodules/freeflowuniverse/webcomponents', true)!

	// hero_compile()!

	osal.done_set('install_herolib', 'OK')!
	return
}

// check if herolib installed and hero, if not do so
pub fn check() ! {
	if osal.done_exists('install_herolib') {
		return
	}
	install()!
}

// remove hero, crystal, ...
pub fn uninstall() ! {
	console.print_debug('uninstall hero & herolib')
	cmd := '
		rm -rf ${os.home_dir()}/hero
		rm -rf ${os.home_dir()}/_code
		rm -f /usr/local/bin/hero
		rm -f /tmp/hero
		rm -f /tmp/install*
		rm -f /tmp/build_hero*
		rm -rf /tmp/execscripts
		'
	osal.execute_stdout(cmd) or { return error('Cannot uninstall herolib/hero.\n${err}') }
}

pub fn hero_install(args InstallArgs) ! {
	if args.reset == false && osal.done_exists('install_hero') {
		console.print_debug('hero already installed')
		return
	}
	console.print_header('install hero')
	base.install()!

	cmd := "
		cd /tmp
		export TERM=xterm
		curl 'https://raw.githubusercontent.com/freeflowuniverse/herolib/refs/heads/main/install_v.sh' > /tmp/install_v.sh
		bash /tmp/install_v.sh --analyzer --herolib
		"
	osal.execute_stdout(cmd) or { return error('Cannot install hero.\n${err}') }
	osal.done_set('install_hero', 'OK')!
	return
}

pub fn hero_compile(args InstallArgs) ! {
	if args.reset == false && osal.done_exists('compile_hero') {
		console.print_debug('hero already compiled')
		return
	}
	console.print_header('compile hero')

	home_dir := os.home_dir()
	cmd_hero := texttools.template_replace($tmpl('templates/hero.sh'))
	osal.exec(cmd: cmd_hero, stdout: false)!

	osal.execute_stdout(cmd_hero) or { return error('Cannot compile hero.\n${err}') }
	osal.done_set('compile_hero', 'OK')!
	return
}

// pub fn update() ! {
// 	console.print_header('package_install update herolib')
// 	if !(i.state == .reset) && osal.done_exists('install_crystaltools') {
// 		console.print_debug('    package_install was already done')
// 		return
// 	}
// 	osal.execute_silent('cd /tmp && export TERM=xterm && source /root/env.sh && ct_upgrade') or {
// 		return error('Cannot update crystal tools.\n${err}')
// 	}
// 	osal.done_set('update_crystaltools', 'OK')!
// }
