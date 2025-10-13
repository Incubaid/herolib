module qdrant_installer

import incubaid.herolib.ui.console
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.core
import incubaid.herolib.installers.ulist
import incubaid.herolib.core.texttools
import incubaid.herolib.clients.zinit
import os

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}
	res << startupmanager.ZProcessNewArgs{
		name:        'qdrant'
		cmd:         'sleep 5 && qdrant --config-path ${os.home_dir()}/hero/var/qdrant/config.yaml'
		startuptype: .zinit
	}

	return res
}

fn running() !bool {
	console.print_header('checking qdrant is running')
	res := os.execute('curl -s http://localhost:6336/healthz')
	if res.exit_code == 0 && res.output.contains('healthz check passed') {
		console.print_debug('qdrant is running')
		return true
	}
	console.print_debug('qdrant is not running')
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
	console.print_header('checking qdrant installation')
	// Check the version directly without sourcing profile
	res := os.execute('qdrant -V')
	if res.exit_code != 0 {
		return false
	}

	r := res.output.split_into_lines().filter(it.contains('qdrant'))
	if r.len != 1 {
		return error("couldn't parse qdrant version.\n${res.output}")
	}

	if texttools.version(version) == texttools.version(r[0].all_after('qdrant')) {
		console.print_debug('qdrant version is ${r[0].all_after('qdrant')}')
		return true
	}
	return false
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {
	// installers.upload(
	//     cmdname: 'qdrant'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/qdrant'
	// )!
}

fn install() ! {
	console.print_header('install qdrant')
	mut url := ''

	if (core.platform() == core.PlatformType.ubuntu || core.platform() == core.PlatformType.arch)
		&& core.cputype() == core.CPUType.arm {
		url = 'https://github.com/qdrant/qdrant/releases/download/v${version}/qdrant-aarch64-unknown-linux-musl.tar.gz'
	} else if
		(core.platform() == core.PlatformType.ubuntu || core.platform() == core.PlatformType.arch)
		&& core.cputype() == core.CPUType.intel {
		url = 'https://github.com/qdrant/qdrant/releases/download/v${version}/qdrant-x86_64-unknown-linux-musl.tar.gz'
	} else if core.platform() == core.PlatformType.osx && core.cputype() == core.CPUType.arm {
		url = 'https://github.com/qdrant/qdrant/releases/download/v${version}/qdrant-aarch64-apple-darwin.tar.gz'
	} else if core.platform() == core.PlatformType.osx && core.cputype() == core.CPUType.intel {
		url = 'https://github.com/qdrant/qdrant/releases/download/v${version}/qdrant-x86_64-apple-darwin.tar.gz'
	} else {
		return error('unsported platform')
	}
	mut dest := osal.download(
		url:        url
		minsize_kb: 18000
		expand_dir: '/tmp/qdrant'
	)

	mut binpath := dest.file_get('qdrant')!
	osal.cmd_add(
		cmdname: 'qdrant'
		source:  binpath.path
	)!
}

fn build() ! {}

fn destroy() ! {
	console.print_header('removing qdrant')
	osal.rm('${os.home_dir()}/hero/var/qdrant')!
	osal.rm('${os.home_dir()}/hero/bin/qdrant')!
	osal.rm('/usr/local/bin/qdrant')!

	mut zinit_factory := zinit.ZinitRPC{}
	if zinit_factory.service_list()!.keys().contains('qdrant') {
		zinit_factory.service_stop('qdrant')!
		zinit_factory.service_delete('qdrant')!
	}
	console.print_header('qdrant removed')
}
