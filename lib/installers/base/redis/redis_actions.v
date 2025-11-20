module redis

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
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

	// Ensure data directory exists with proper permissions before configuring
	osal.execute_silent('mkdir -p ${cfg.datadir}')!
	if core.is_linux()! {
		// On Linux, ensure redis user can access the directory
		osal.execute_silent('chown -R redis:redis ${cfg.datadir}')!
		osal.execute_silent('chmod 755 ${cfg.datadir}')!
	}

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

// Install and start Redis with the given configuration
// This is the main entry point for installing Redis without using the factory
pub fn redis_install(args RedisInstall) ! {
	// Check if already running
	if check(args) {
		console.print_debug('Redis already running on port ${args.port}')
		return
	}

	console.print_header('install redis')

	// Install Redis package if not already installed
	if !installed()! {
		if core.is_linux()! {
			osal.package_install('redis-server')! // Ubuntu/Debian
		} else {
			osal.package_install('redis')! // macOS, Alpine, Arch, etc.
		}
	}

	// Create data directory with correct permissions
	osal.execute_silent('mkdir -p ${args.datadir}')!
	osal.execute_silent('chown -R redis:redis ${args.datadir}') or {}
	osal.execute_silent('chmod 755 ${args.datadir}') or {}

	// Configure and start Redis
	start(args)!
}

// Check if Redis is running
pub fn check(args RedisInstall) bool {
	res := os.execute('redis-cli -c -p ${args.port} ping > /dev/null 2>&1')
	if res.exit_code == 0 {
		return true
	}
	return false
}

// Start Redis with the given configuration
// Writes config file, kills any existing processes, and starts Redis
pub fn start(args RedisInstall) ! {
	if check(args) {
		console.print_debug('Redis already running on port ${args.port}')
		return
	}

	// Write Redis configuration file
	configure_with_args(args)!

	// Kill any existing Redis processes (including package auto-started ones)
	osal.process_kill_recursive(name: 'redis-server')!

	if core.platform()! == .osx {
		// macOS: start directly with daemonize
		osal.exec(cmd: 'redis-server ${configfilepath(args)} --daemonize yes')!
	} else {
		// Linux: prefer systemctl if available, otherwise start directly
		if osal.cmd_exists('systemctl') {
			// Ensure permissions are correct for systemd-managed Redis
			osal.execute_silent('chown -R redis:redis ${args.datadir}') or {}
			osal.execute_silent('chmod 755 ${args.datadir}') or {}
			// Reset any failed state from previous kills
			osal.execute_silent('systemctl reset-failed redis-server') or {}
			osal.exec(cmd: 'systemctl start redis-server')!
		} else {
			// No systemctl (Alpine, containers, etc.)
			// Set permissions for redis user before starting
			osal.execute_silent('chown -R redis:redis ${args.datadir}') or {}
			osal.execute_silent('chmod 755 ${args.datadir}') or {}
			osal.exec(cmd: 'redis-server ${configfilepath(args)} --daemonize yes')!
		}
	}

	// Wait for Redis to be ready
	for _ in 0 .. 100 {
		if check(args) {
			console.print_debug('Redis started successfully')
			return
		}
		time.sleep(100)
	}

	return error('Redis did not start properly after 10 seconds - could not ping on port ${args.port}')
}

// Stop Redis
pub fn stop() ! {
	osal.execute_silent('redis-cli shutdown')!
}

// Restart Redis
pub fn restart(args RedisInstall) ! {
	stop()!
	time.sleep(500) // Give Redis time to shut down
	start(args)!
}

// Private install function for factory-based usage
fn install() ! {
	mut cfg := get()!
	redis_install(cfg)!
}

fn destroy() ! {
	stop()!
	osal.process_kill_recursive(name: 'redis-server')!
}
