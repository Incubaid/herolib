module coordinator

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.pathlib
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.installers.ulist
import incubaid.herolib.installers.lang.rust
import incubaid.herolib.develop.gittools
import os

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

// Lifecycle hooks - can be implemented for custom pre/post actions
fn start_pre() ! {
	// Add any pre-start actions here if needed
}

fn start_post() ! {
	// Add any post-start actions here if needed
}

fn stop_pre() ! {
	// Add any pre-stop actions here if needed
}

fn stop_post() ! {
	// Add any post-stop actions here if needed
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
	
	// Ensure rust is installed
	println('Step 1/3: Checking Rust dependency...')
	if !osal.cmd_exists('rustc') {
		println('Rust not found, installing...')
		mut rust_installer := rust.get()!
		rust_installer.install()!
		println('Rust installed successfully\n')
	} else {
		res := osal.exec(cmd: 'rustc --version', stdout: false, raise_error: false)!
		println('Rust is already installed: ${res.output.trim_space()}\n')
	}
	
	// Clone or get the repository
	println('Step 2/3: Cloning/updating horus repository...')
	// Use the configured repo_path or default coderoot
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
	println('Step 3/3: Building coordinator binary...')
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
	
	// Verify source binary exists before copying
	mut source_file := pathlib.get_file(path: source_binary) or {
		return error('Built binary not found at ${source_binary}. Build may have failed.')
	}
	if !source_file.exists() {
		return error('Built binary not found at ${source_binary}. Build may have failed.')
	}
	
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
