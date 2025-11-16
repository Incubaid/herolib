module coordinator

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.installers.ulist
import incubaid.herolib.installers.lang.rust
import incubaid.herolib.installers.base.redis
import incubaid.herolib.develop.gittools
import os

// Helper function to ensure Redis is installed and running
fn ensure_redis_running() ! {
	redis_config := redis.RedisInstall{
		port: 6379
		datadir: '/var/lib/redis'
		ipaddr: 'localhost'
	}
	
	if !redis.check(redis_config) {
		println('Installing and starting Redis...')
		redis.redis_install(redis_config)!
	} else {
		println('Redis is already running')
	}
}

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut cfg := get()!
	mut res := []startupmanager.ZProcessNewArgs{}
	
	res << startupmanager.ZProcessNewArgs{
		name: 'coordinator'
		cmd:  '${cfg.binary_path} --redis-addr ${cfg.redis_addr} --api-http-port ${cfg.http_port} --api-ws-port ${cfg.ws_port}'
		env:  {
			'HOME':           os.home_dir()
			'RUST_LOG':       cfg.log_level
			'RUST_LOG_STYLE': 'never'
		}
	}

	return res
}

fn running() !bool {
	mut cfg := get()!
	// Check if the process is running by checking the HTTP port
	res := osal.exec(cmd: 'curl -fsSL http://127.0.0.1:${cfg.http_port} || exit 1', stdout: false, raise_error: false)!
	return res.exit_code == 0
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
	mut cfg := get()!
	
	// Check if the binary exists
	mut binary := pathlib.get(cfg.binary_path)
	if !binary.exists() {
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
fn upload() ! {
	// installers.upload(
	//     cmdname: 'coordinator'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/coordinator'
	// )!
}

fn install() ! {
	console.print_header('install coordinator')
	// For coordinator, we build from source instead of downloading
	build()!
}

// Public build function that works with or without Redis/factory available
pub fn build() ! {
	console.print_header('build coordinator')
	println('Starting coordinator build process...\n')
	
	// Try to get config from factory, fallback to default if Redis not available
	println('Initializing configuration...')
	mut cfg_ref := get() or {
		console.print_debug('Factory not available, using default config')
		mut default_cfg := CoordinatorServer{}
		_ := set_in_mem(default_cfg)!
		coordinator_global[default_cfg.name]
	}
	mut cfg := *cfg_ref
	println('Configuration initialized')
	println('   - Binary path: ${cfg.binary_path}')
	println('   - Redis address: ${cfg.redis_addr}')
	println('   - HTTP port: ${cfg.http_port}')
	println('   - WS port: ${cfg.ws_port}\n')
	
	// Ensure Redis is installed and running (required for coordinator)
	println('Step 1/4: Checking Redis dependency...')
	ensure_redis_running()!
	println('Redis is ready\n')
	
	// Ensure rust is installed
	println('Step 2/4: Checking Rust dependency...')
	mut rust_installer := rust.get()!
	res := osal.exec(cmd: 'rustc -V', stdout: false, raise_error: false)!
	if res.exit_code != 0 {
		println('Installing Rust...')
		rust_installer.install()!
		println('Rust installed\n')
	} else {
		println('Rust is already installed: ${res.output.trim_space()}\n')
	}
	
	// Clone or get the repository
	println('Step 3/4: Cloning/updating horus repository...')
	mut gs := gittools.new(coderoot: '/root/code')!
	mut repo := gs.get_repo(
		url:   'https://git.ourworld.tf/herocode/horus.git'
		pull:  true
		reset: false
	)!
	
	// Update the path to the actual cloned repo
	cfg.repo_path = repo.path()
	println('Repository ready at: ${cfg.repo_path}\n')
	
	// Build the coordinator binary from the horus workspace
	println('Step 4/4: Building coordinator binary...')
	println('WARNING: This may take several minutes (compiling Rust code)...')
	println('Running: cargo build -p hero-coordinator --release\n')
	
	cmd := 'cd ${cfg.repo_path} && . ~/.cargo/env && RUSTFLAGS="-A warnings" cargo build -p hero-coordinator --release'
	osal.execute_stdout(cmd)!
	
	println('\nBuild completed successfully')
	
	// Ensure binary directory exists and copy the binary
	println('Preparing binary directory: ${cfg.binary_path}')
	mut binary_path_obj := pathlib.get(cfg.binary_path)
	osal.dir_ensure(binary_path_obj.path_dir())!
	
	// Copy the built binary to the configured location
	source_binary := '${cfg.repo_path}/target/release/coordinator'
	println('Copying binary from: ${source_binary}')
	println('Copying binary to: ${cfg.binary_path}')
	mut source_file := pathlib.get_file(path: source_binary)!
	source_file.copy(dest: cfg.binary_path, rsync: false)!
	
	println('\nCoordinator built successfully!')
	println('Binary location: ${cfg.binary_path}')
}

fn destroy() ! {
	mut server := get()!
	server.stop()!
	
	osal.process_kill_recursive(name: 'coordinator')!
	
	// Remove the built binary
	osal.rm(server.binary_path)!
}
