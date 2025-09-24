module daguserver

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.core.httpconnection
import freeflowuniverse.herolib.installers.ulist
// import freeflowuniverse.herolib.develop.gittools
import freeflowuniverse.herolib.osal.startupmanager
import freeflowuniverse.herolib.libarchive.zinit as zinit_lib
import os

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}
	mut cfg := get()!

	res << startupmanager.ZProcessNewArgs{
		name: 'dagu'
		cmd:  'dagu server'
		env:  {
			'HOME ':      os.home_dir()
			'DAGU_HOME ': cfg.configpath // config for dagu is called admin.yml and is in this dir
		}
	}

	res << startupmanager.ZProcessNewArgs{
		name: 'dagu_scheduler'
		cmd:  'dagu scheduler'
		env:  {
			'HOME ':      os.home_dir()
			'DAGU_HOME ': cfg.configpath
		}
	}

	return res
}

fn running() !bool {
	mut cfg := get()!
	url := 'http://${cfg.host}:${cfg.port}/api/v1'
	mut conn := httpconnection.new(name: 'dagu', url: url)!

	if cfg.secret.len > 0 {
		conn.default_header.add(.authorization, 'Bearer ${cfg.secret}')
	}

	console.print_debug("curl -X 'GET' '${url}'/tags --oauth2-bearer ${cfg.secret}")
	r := conn.get_json_dict(prefix: 'tags', debug: false) or { return false }
	tags := r['Tags'] or { return false }
	console.print_debug(tags)
	console.print_debug('Dagu is answering.')
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
	res := os.execute('dagu version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().len > 0)
		if r.len != 1 {
			return error("couldn't parse dagu version.\n${res.output}")
		}
		if texttools.version(version) > texttools.version(r[0]) {
			return false
		}
	} else {
		return false
	}
	return true
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {}

fn install() ! {
	console.print_header('install daguserver')
	mut url := ''
	if core.is_linux_arm()! {
		url = 'https://github.com/dagu-dev/dagu/releases/download/v${version}/dagu_${version}_linux_arm64.tar.gz'
	} else if core.is_linux_intel()! {
		url = 'https://github.com/dagu-dev/dagu/releases/download/v${version}/dagu_${version}_linux_amd64.tar.gz'
	} else if core.is_osx_arm()! {
		url = 'https://github.com/dagu-dev/dagu/releases/download/v${version}/dagu_${version}_darwin_arm64.tar.gz'
	} else if core.is_osx_intel()! {
		url = 'https://github.com/dagu-dev/dagu/releases/download/v${version}/dagu_${version}_darwin_amd64.tar.gz'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 9000
		expand_dir: '/tmp/dagu'
	)!

	mut binpath := dest.file_get('dagu')!
	osal.cmd_add(
		cmdname: 'dagu'
		source:  binpath.path
	)!
}

fn destroy() ! {
	cmd := '
        systemctl disable daguserver_scheduler.service
        systemctl disable daguserver.service
        systemctl stop daguserver_scheduler.service
        systemctl stop daguserver.service

        systemctl list-unit-files | grep daguserver

        pkill -9 -f daguserver

        ps aux | grep daguserver

        '

	osal.execute_silent(cmd) or {}
	// mut zinit_factory := zinit_lib.Zinit{}

	// if zinit_factory.exists('dagu') {
	// 	zinit_factory.stop('dagu')! or { return error('Could not stop dagu service due to: ${err}') }
	// 	zinit_factory.delete('dagu')! or {
	// 		return error('Could not delete dagu service due to: ${err}')
	// 	}
	// }

	// if zinit_factory.exists('dagu_scheduler') {
	// 	zinit_factory.stop('dagu_scheduler')! or {
	// 		return error('Could not stop dagu_scheduler service due to: ${err}')
	// 	}
	// 	zinit_factory.delete('dagu_scheduler')! or {
	// 		return error('Could not delete dagu_scheduler service due to: ${err}')
	// 	}
	// }
}
