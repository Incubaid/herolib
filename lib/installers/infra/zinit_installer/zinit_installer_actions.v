module zinit_installer

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.develop.gittools
import incubaid.herolib.core
import incubaid.herolib.osal.systemd
import incubaid.herolib.installers.ulist
import incubaid.herolib.installers.lang.rust
import incubaid.herolib.osal.startupmanager
import os

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}
	if core.is_linux()! {
		res << startupmanager.ZProcessNewArgs{
			name:        'zinit'
			cmd:         '/usr/local/bin/zinit init -c ${os.home_dir()}/hero/cfg/zinit'
			startuptype: .systemd
			start:       true
			restart:     true
		}
	} else {
		res << startupmanager.ZProcessNewArgs{
			name:        'zinit'
			cmd:         '${os.home_dir()}/hero/bin/zinit init -c  ${os.home_dir()}/hero/cfg/zinit'
			startuptype: .screen
			start:       true
		}
	}
	osal.dir_ensure(os.join_path(os.home_dir(), 'hero/cfg/zinit'))!
	return res
}

fn running() !bool {
	cmd := 'zinit list'
	return osal.execute_ok(cmd)
}

fn start_pre() ! {
}

fn start_post() ! {
}

fn stop_pre() ! {
}

fn stop_post() ! {
}

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	cmd := 'zinit --version'
	// console.print_debug(cmd)
	res := os.execute(cmd)
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().starts_with('zinit v'))
		if r.len != 1 {
			return error("couldn't parse zinit version.\n${res.output}")
		}
		if texttools.version(version) == texttools.version(r[0].all_after_first('zinit v')) {
			return true
		}
	}
	console.print_debug(res.str())
	return false
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {}

fn install() ! {
	console.print_header('install zinit')
	baseurl := 'https://github.com/threefoldtech/zinit/releases/download/v${version}/zinit-'

	mut url := ''

	if core.is_linux_intel()! {
		url = '${baseurl}linux-x86_64'
	} else if core.is_osx_arm()! {
		url = '${baseurl}macos-aarch64'
	} else if core.is_osx_intel()! {
		url = '${baseurl}macos-x86_64'
	} else {
		return error('unsupported platform to install zinit')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 4000
	)!

	osal.cmd_add(
		cmdname: 'zinit'
		source:  dest.path
	)!
}

fn build() ! {
	if !core.is_linux()! {
		return error('only support linux for now')
	}

	mut i := rust.new()!
	i.install()!

	// install zinit if it was already done will return true
	console.print_header('build zinit')

	mut gs := gittools.new(coderoot: '/tmp/builder')!
	mut repo := gs.get_repo(
		url:   'https://github.com/threefoldtech/zinit'
		reset: true
		pull:  true
	)!
	gitpath := repo.path()

	// source ${osal.profile_path()}

	cmd := '
	source ~/.cargo/env
	cd ${gitpath}
	make release
	'
	osal.execute_stdout(cmd)!

	osal.cmd_add(
		cmdname: 'zinit'
		source:  '/tmp/builder/github/threefoldtech/zinit/target/x86_64-unknown-linux-musl/release/zinit'
	)!
}

fn destroy() ! {
	if core.is_linux()! {
		mut systemdfactory := systemd.new()!
		systemdfactory.destroy('zinit') or {
			return error('Could not destroy zinit due to: ${err}')
		}
	}

	osal.process_kill_recursive(name: 'zinit') or {
		return error('Could not kill zinit due to: ${err}')
	}
	osal.cmd_delete('zinit')!
}
