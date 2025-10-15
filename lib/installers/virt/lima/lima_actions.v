module lima

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.core
import incubaid.herolib.core.pathlib
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.installers.ulist
import incubaid.herolib.installers.virt.qemu
import os

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut installer := get()!
	mut res := []startupmanager.ZProcessNewArgs{}
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// res << startupmanager.ZProcessNewArgs{
	//     name: 'lima'
	//     cmd: 'lima server'
	//     env: {
	//         'HOME': '/root'
	//     }
	// }

	return res
}

fn running() !bool {
	mut installer := get()!
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// this checks health of lima
	// curl http://localhost:3333/api/v1/s --oauth2-bearer 1234 works
	// url:='http://127.0.0.1:${cfg.port}/api/v1'
	// mut conn := httpconnection.new(name: 'lima', url: url)!

	// if cfg.secret.len > 0 {
	//     conn.default_header.add(.authorization, 'Bearer ${cfg.secret}')
	// }
	// conn.default_header.add(.content_type, 'application/json')
	// console.print_debug("curl -X 'GET' '${url}'/tags --oauth2-bearer ${cfg.secret}")
	// r := conn.get_json_dict(prefix: 'tags', debug: false) or {return false}
	// println(r)
	// if true{panic("ssss")}
	// tags := r['Tags'] or { return false }
	// console.print_debug(tags)
	// console.print_debug('lima is answering.')
	return false
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
	if !osal.cmd_exists('limactl') {
		return false
	}
	mut res := os.execute('lima -v')
	r := res.output.split_into_lines().filter(it.contains('limactl version'))
	if r.len != 1 {
		return error("couldn't parse lima version, expected 'lima version' on 1 row.\n${res.output}")
	}

	v := texttools.version(r[0].all_after('version'))
	if v < texttools.version(version) {
		return false
	}
	return true
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	return ulist.UList{}
}

fn upload() ! {
}

fn install() ! {
	console.print_header('install lima')
	qemu.install()!
	mut url := ''
	mut url2 := ''
	mut dest_on_os := '${os.home_dir()}/hero'
	if core.is_linux_arm()! {
		dest_on_os = '/usr/local'
		url = 'https://github.com/lima-vm/lima/releases/download/v${version}/lima-${version}-Linux-aarch64.tar.gz'
		url2 = 'https://github.com/lima-vm/lima/releases/download/v${version}/lima-additional-guestagents-${version}-Linux-aarch64.tar.gz'
	} else if core.is_linux_intel()! {
		dest_on_os = '/usr/local'
		url = 'https://github.com/lima-vm/lima/releases/download/v${version}/lima-${version}-Linux-x86_64.tar.gz'
		url2 = 'https://github.com/lima-vm/lima/releases/download/v${version}/lima-additional-guestagents-${version}-Linux-x86_64.tar.gz'
	} else if core.is_osx()! {
		url = 'https://github.com/lima-vm/lima/releases/download/v${version}/lima-${version}-Darwin-arm64.tar.gz'
		url2 = 'https://github.com/lima-vm/lima/releases/download/v${version}/lima-additional-guestagents-${version}-Darwin-arm64.tar.gz'
	} else if core.is_osx_intel()! {
		url = 'https://github.com/lima-vm/lima/releases/download/v${version}/lima-${version}-Darwin-x86_64.tar.gz'
		url2 = 'https://github.com/lima-vm/lima/releases/download/v${version}/lima-additional-guestagents-${version}-Darwin-x86_64.tar.gz'
	} else {
		return error('unsported platform')
	}

	console.print_header('download ${url}')
	mut e := osal.download(
		url:         url
		minsize_kb:  20000
		dest:        '/tmp/lima.tar.gz'
		expand_file: '/tmp/download/lima'
	)!

	e.copy(dest: dest_on_os)!

	mut installer := get()!

	if installer.extra {
		mut e2 := osal.download(
			url:         url2
			minsize_kb:  20000
			dest:        '/tmp/lima-additional-guestagents.tar.gz'
			expand_file: '/tmp/download/lima-additional-guestagents'
		)!

		e2.copy(dest: dest_on_os)!
	}
}

fn destroy() ! {
	osal.process_kill_recursive(name: 'lima')!

	osal.package_remove('
	   lima
	   limactl
	')!

	osal.rm('
	   lima
	   limactl
	   ${os.home_dir()}/bin/*.lima
	   ${os.home_dir()}/bin/*.lima	   
	   ${os.home_dir()}/share/doc/lima
	   ${os.home_dir()}/share/lima
	   ${os.home_dir()}/share/man/lima*

	')!
}
