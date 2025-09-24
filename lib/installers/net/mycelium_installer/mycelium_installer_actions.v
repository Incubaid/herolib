module mycelium_installer

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.clients.mycelium
import freeflowuniverse.herolib.develop.gittools
import freeflowuniverse.herolib.osal.startupmanager
import freeflowuniverse.herolib.installers.ulist
import freeflowuniverse.herolib.installers.lang.rust
import os

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut installer := get()!
	mut res := []startupmanager.ZProcessNewArgs{}

	mut peers_str := installer.peers.join(' ')
	mut tun_name := 'tun${installer.tun_nr}'

	mut cmd := 'mycelium --key-file ${osal.hero_path()!}/cfg/priv_key.bin --peers ${peers_str} --tun-name ${tun_name}'
	if core.is_osx()! {
		cmd = 'sudo ${cmd}'
	}

	res << startupmanager.ZProcessNewArgs{
		name:        'mycelium'
		startuptype: .zinit
		cmd:         cmd
		env:         {
			'HOME': os.home_dir()
		}
	}
	return res
}

fn running() !bool {
	mycelium.inspect() or { return false }
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
	cmd := '${osal.profile_path_source_and()!} mycelium -V'
	// println(cmd)
	res := os.execute(cmd)
	if res.exit_code != 0 {
		println(res)
		return false
	}
	r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	if r.len != 1 {
		return error("couldn't parse mycelium version.\n${res.output}")
	}
	if texttools.version(version) == texttools.version(r[0].all_after_last('mycelium')) {
		return true
	}
	return false
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {
	// installers.upload(
	//     cmdname: 'mycelium_installer'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/mycelium_installer'
	// )!
}

fn install() ! {
	console.print_header('install mycelium')

	mut url := ''
	if core.is_linux_arm()! {
		url = 'https://github.com/threefoldtech/mycelium/releases/download/v${version}/mycelium-aarch64-unknown-linux-musl.tar.gz'
	} else if core.is_linux_intel()! {
		url = 'https://github.com/threefoldtech/mycelium/releases/download/v${version}/mycelium-x86_64-unknown-linux-musl.tar.gz'
	} else if core.is_osx_arm()! {
		url = 'https://github.com/threefoldtech/mycelium/releases/download/v${version}/mycelium-aarch64-apple-darwin.tar.gz'
	} else if core.is_osx_intel()! {
		url = 'https://github.com/threefoldtech/mycelium/releases/download/v${version}/mycelium-x86_64-apple-darwin.tar.gz'
	} else {
		return error('unsported platform')
	}

	pathlib.get_dir(
		path:   '${osal.hero_path()!}/cfg'
		create: true
	)!

	mut dest := osal.download(
		url:        url
		minsize_kb: 5000
		expand_dir: '/tmp/mycelium'
	)!
	mut binpath := dest.file_get('mycelium')!
	osal.cmd_add(
		cmdname: 'mycelium'
		source:  binpath.path
	)!
}

fn build() ! {
	url := 'https://github.com/threefoldtech/mycelium'
	myplatform := core.platform()!
	if myplatform != .ubuntu {
		return error('only support ubuntu for now')
	}

	mut rs := rust.get()!
	rs.install()!

	console.print_header('build mycelium')

	mut gs := gittools.new()!
	gitpath := gs.get_path(
		pull:  true
		reset: false
		url:   url
	)!

	panic('implement')

	cmd := '
    cd ${gitpath}
    source ~/.cargo/env
    cargo install --path . --locked
    cargo build --release --locked --no-default-features --features=native-tls
    cp target/release/mycelium ~/.cargo/bin/mycelium
    mycelium --version
    '
	osal.execute_stdout(cmd)!

	// //now copy to the default bin path
	// mut binpath := dest.file_get('...')!
	// adds it to path
	// osal.cmd_add(
	//     cmdname: 'griddriver2'
	//     source: binpath.path
	// )!
}

fn destroy() ! {
	osal.process_kill_recursive(name: 'mycelium')!
	osal.cmd_delete('mycelium')!

	osal.rm('
       mycelium
    ')!
}
