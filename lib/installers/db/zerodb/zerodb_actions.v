module zerodb

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.osal.startupmanager
import freeflowuniverse.herolib.installers.ulist
import freeflowuniverse.herolib.develop.gittools
import freeflowuniverse.herolib.installers.base
import freeflowuniverse.herolib.crypt.secrets
import freeflowuniverse.herolib.clients.zerodb_client
import crypto.md5
import rand
import os
import time

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut cfg := get()!
	mut cmd := 'zdb --socket ${os.home_dir()}/var/zdb.sock --port ${cfg.port} --admin ${cfg.secret} --data ${cfg.datadir} --index ${cfg.indexdir} --dualnet --protect --rotate ${cfg.rotateperiod}'
	if cfg.sequential {
		cmd += ' --mode seq'
	}

	mut res := []startupmanager.ZProcessNewArgs{}
	res << startupmanager.ZProcessNewArgs{
		name:        'zdb'
		cmd:         cmd
		startuptype: .zinit
	}

	return res
}

fn running() !bool {
	time.sleep(time.second * 2)
	cfg := get()!
	cmd := 'redis-cli -s ${os.home_dir()}/var/zdb.sock PING'

	result := os.execute(cmd)
	if result.exit_code > 0 {
		return error('${cmd} failed with exit code: ${result.exit_code} and error: ${result.output}')
	}

	if result.output.trim_space() == 'PONG' {
		console.print_debug('zdb is answering.')
		return true
	}

	mut db := zerodb_client.get('localhost:${cfg.port}', cfg.secret, 'test')!

	// check info returns info about zdb
	info := db.info()!

	assert info.contains('server_name: 0-db')

	console.print_debug('zdb is answering.')
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
	res := os.execute('zdb --version')
	return res.exit_code == 0
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {
	// installers.upload(
	//     cmdname: 'zerodb'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/zerodb'
	// )!
}

fn install() ! {
	console.print_header('install zdb')

	mut url := ''
	if core.is_linux_intel()! {
		url = 'https://github.com/threefoldtech/0-db/releases/download/v${version}/zdb-${version}-linux-amd64-static'
	} else {
		return error('unsported platform, only linux 64 for zdb for now')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 1000
	)!

	osal.cmd_add(
		cmdname: 'zdb'
		source:  dest.path
	)!
}

fn build() ! {
	base.install()!
	console.print_header('package_install install zdb')
	if !osal.done_exists('install_zdb') && !osal.cmd_exists('zdb') {
		mut gs := gittools.new()!
		mut repo := gs.get_repo(
			url:   'git@github.com:threefoldtech/0-db.git'
			reset: false
			pull:  true
		)!
		path := repo.path()
		cmd := '
		set -ex
		cd ${path}
		make
		sudo rsync -rav ${path}/bin/zdb* /usr/local/bin/
		'
		osal.execute_silent(cmd) or { return error('Cannot install zdb.\n${err}') }
		osal.done_set('install_zdb', 'OK')!
	}
}

fn destroy() ! {
	res := os.execute('sudo rm -rf /usr/local/bin/zdb')
	if res.exit_code != 0 {
		return error('Could not remove zdb binary due to: ${res.output}')
	}

	mut zinit_factory := zinit.new()!
	if zinit_factory.exists('zdb') {
		zinit_factory.stop('zdb') or { return error('Could not stop zdb service due to: ${err}') }
		zinit_factory.delete('zdb') or {
			return error('Could not delete zdb service due to: ${err}')
		}
	}
	console.print_header('zdb removed')
}
