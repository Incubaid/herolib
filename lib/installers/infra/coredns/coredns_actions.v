module coredns

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import incubaid.herolib.core
import incubaid.herolib.develop.gittools
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.installers.ulist
import incubaid.herolib.core.httpconnection
import incubaid.herolib.installers.lang.golang
import os

fn (self &CoreDNS) startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}
	cmd := "coredns -conf '${self.config_path}'"
	res << startupmanager.ZProcessNewArgs{
		name: 'coredns'
		cmd:  cmd
	}

	return res
}

fn (self &CoreDNS) running_check() !bool {
	mut conn := httpconnection.new(name: 'coredns', url: 'http://localhost:3334')!
	r := conn.get(prefix: 'health')!
	if r.trim_space() == 'OK' {
		return true
	}
	return false
}

fn (self &CoreDNS) start_pre() ! {
	fix()!
}

fn (self &CoreDNS) start_post() ! {
	set_local_dns()
}

fn (self &CoreDNS) stop_pre() ! {
}

fn (self &CoreDNS) stop_post() ! {
}

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn (self &CoreDNS) installed() !bool {
	res := os.execute('/bin/bash -c "coredns --version"')
	if res.exit_code != 0 {
		return false
	}
	r := res.output.split_into_lines().filter(it.trim_space().starts_with('CoreDNS-'))
	if r.len != 1 {
		return error("couldn't parse coredns version.\n${res.output}")
	}
	if texttools.version(version) == texttools.version(r[0].all_after_first('CoreDNS-')) {
		return true
	}
	return false
}

// get the Upload List of the files
fn (self &CoreDNS) ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn (self &CoreDNS) upload() ! {
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

fn (mut self CoreDNS) install(args InstallArgs) ! {
	console.print_header('install coredns')
	self.build()! // because we need the plugins
}

fn (mut self CoreDNS) build() ! {
	url := 'https://github.com/coredns/coredns'

	if core.platform()! != .ubuntu {
		return error('only support ubuntu for now')
	}
	mut g := golang.get()!
	g.install()!

	console.print_header('build coredns')

	mut gs := gittools.new()!

	gitpath := gs.get_path(
		pull:  true
		reset: true
		url:   url
	)!

	// set the plugins file on right location
	pluginsfile := $tmpl('templates/plugin.cfg')
	mut path := pathlib.get_file(path: '${gitpath}/plugin.cfg', create: true)!
	path.write(pluginsfile)!

	cmd := 'bash -c "cd ${gitpath} && make"'
	osal.execute_stdout(cmd)!

	// now copy to the default bin path
	mut codedir := pathlib.get_dir(path: '${gitpath}', create: false)!
	mut binpath := codedir.file_get('coredns')!
	osal.cmd_add(
		cmdname: 'coredns'
		source:  binpath.path
	)!
}

fn (mut self CoreDNS) destroy() ! {
	for zprocess in self.startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.delete(zprocess.name) or { return error('failed to delete coredns process: ${err}') }
	}

	osal.execute_silent('sudo rm /usr/local/bin/coredns') or {
		return error('failed to delete coredns bin: ${err}')
	}
}
