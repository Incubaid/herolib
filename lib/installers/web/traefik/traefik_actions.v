module traefik

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.osal.startupmanager
import freeflowuniverse.herolib.installers.ulist
import os

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut installer := get()!
	mut res := []startupmanager.ZProcessNewArgs{}
	res << startupmanager.ZProcessNewArgs{
		name: 'traefik'
		cmd:  'traefik'
	}

	return res
}

fn running() !bool {
	cmd := 'traefik healthcheck'
	res := os.execute(cmd)
	if res.exit_code != 0 {
		return false
	}
	return true
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
	res := os.execute('${osal.profile_path_source_and()!} traefik version')
	if res.exit_code != 0 {
		return false
	}
	r := res.output.split_into_lines().filter(it.contains('Version'))
	if r.len != 1 {
		return error("couldn't parse traefik version.\n${res.output}")
	}
	if texttools.version(version) == texttools.version(r[0].all_after('Version:')) {
		return true
	}
	return false
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	return ulist.UList{}
}

fn upload() ! {
	// installers.upload(
	//     cmdname: 'traefik'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/traefik'
	// )!
}

fn install() ! {
	console.print_header('install traefik')
	mut url := ''
	if core.is_linux_arm()! {
		url = 'https://github.com/traefik/traefik/releases/download/v${version}/traefik_v${version}_linux_arm64.tar.gz'
	} else if core.is_linux_intel()! {
		url = 'https://github.com/traefik/traefik/releases/download/v${version}/traefik_v${version}_linux_amd64.tar.gz'
	} else if core.is_osx_arm()! {
		url = 'https://github.com/traefik/traefik/releases/download/v${version}/traefik_v${version}_darwin_arm64.tar.gz'
	} else if core.is_osx_intel()! {
		url = 'https://github.com/traefik/traefik/releases/download/v${version}/traefik_v${version}_darwin_arm64.tar.gz'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 20000
		expand_dir: '/tmp/traefik'
	)!

	mut binpath := dest.file_get('traefik')!
	osal.cmd_add(
		cmdname: 'traefik'
		source:  binpath.path
	)!
}

fn destroy() ! {
	osal.process_kill_recursive(name: 'traefik')!
	osal.cmd_delete('traefik')!

	osal.package_remove('
       traefik
    ')!

	osal.rm('
       traefik
    ')!
}
