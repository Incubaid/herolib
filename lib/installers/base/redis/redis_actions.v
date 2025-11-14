module redis

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import incubaid.herolib.osal.systemd
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.installers.ulist
import incubaid.herolib.core
import time
import os

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut cfg := get()!
	mut res := []startupmanager.ZProcessNewArgs{}
	
	res << startupmanager.ZProcessNewArgs{
		name: 'redis'
		cmd:  'redis-server ${configfilepath(cfg)}'
		env:  {
			'HOME': os.home_dir()
		}
	}

	return res
}

fn running() !bool {
	mut cfg := get()!
	res := os.execute('redis-cli -c -p ${cfg.port} ping > /dev/null 2>&1')
	if res.exit_code == 0 {
		return true
	}
	return false
}

fn start_pre() ! {
	// Check if already running
	if running()! {
		return
	}
	
	mut cfg := get()!
	
	// Configure redis before starting (applies template)
	configure()!
	
	// Kill any existing redis processes
	osal.process_kill_recursive(name: 'redis-server')!
	
	// On macOS, start redis with daemonize (not via startupmanager)
	if core.platform()! == .osx {
		osal.exec(cmd: 'redis-server ${configfilepath(cfg)} --daemonize yes')!
	}
}

fn start_post() ! {
	// Wait for redis to be ready
	for _ in 0 .. 100 {
		if running()! {
			console.print_debug('redis started.')
			return
		}
		time.sleep(100)
	}
	return error("Redis did not start properly could not do:'redis-cli -c ping'")
}

fn stop_pre() ! {
	osal.execute_silent('redis-cli shutdown') or {}
}

fn stop_post() ! {
}

//////////////////// following actions are not specific to instance of the object

// checks if redis-server is installed
fn installed() !bool {
	return osal.cmd_exists_profile('redis-server')
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {
	// installers.upload(
	//     cmdname: 'redis'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/redis'
	// )!
}

fn install() ! {
	console.print_header('install redis')
	
	if installed()! {
		console.print_debug('redis-server already installed')
		return
	}
	
	// Install redis-server via package manager
	if core.is_linux()! {
		osal.package_install('redis-server')!
	} else {
		osal.package_install('redis')!
	}
	
	mut cfg := get()!
	osal.execute_silent('mkdir -p ${cfg.datadir}')!
	
	console.print_debug('redis-server installed successfully')
}

fn destroy() ! {
	mut cfg := get()!
	cfg.stop()!
	osal.process_kill_recursive(name: 'redis-server')!
}
