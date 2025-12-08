module coordinator

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.pathlib
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.installers.ulist
import incubaid.herolib.installers.lang.rust
import incubaid.herolib.develop.gittools
import os

@[params]
pub struct StartArgs {
pub mut:
	reset bool
}

fn (self &Coordinator) startupcmd(args StartArgs) ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}

	reset := args.reset

	res << startupmanager.ZProcessNewArgs{
		name:  'coordinator'
		cmd:   '${self.binary_path} --redis-addr ${self.redis_addr} --api-http-port ${self.http_port} --api-ws-port ${self.ws_port}'
		reset: reset
		env:   {
			'HOME':           os.home_dir()
			'RUST_LOG':       self.log_level
			'RUST_LOG_STYLE': 'never'
		}
	}

	return res
}

fn (self &Coordinator) running_check() !bool {
	// Check if the process is running by checking the HTTP port
	// The coordinator returns 405 for GET requests (requires POST), so we check if we get any response
	res := osal.exec(
		cmd:         'curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:${self.http_port}'
		stdout:      false
		raise_error: false
	)!
	// Any HTTP response code (including 405) means the server is running
	return res.output.len > 0 && res.output.int() > 0
}

fn (self &Coordinator) start_pre() ! {
}

fn (self &Coordinator) start_post() ! {
}

fn (self &Coordinator) stop_pre() ! {
}

fn (self &Coordinator) stop_post() ! {
}

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn (self &Coordinator) installed() !bool {
	// Check if the binary exists
	mut binary := pathlib.get(self.binary_path)
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

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

fn (mut self Coordinator) install(args InstallArgs) ! {
	console.print_header('install coordinator')
	// For coordinator, we build from source instead of downloading
	self.build()!
}

// Public function to build coordinator without requiring factory/redis
pub fn build_coordinator() ! {
	console.print_header('build coordinator')
	println('📦 Starting coordinator build process...\n')

	// Use default config instead of getting from factory
	println('⚙️  Initializing configuration...')
	mut cfg := Coordinator{}
	println('✅ Configuration initialized')
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
	println('✅ Repository ready at: ${cfg.repo_path}\n')

	// Build the coordinator binary from the horus workspace
	println('Step 3/3: Building coordinator binary...')
	println('WARNING: This may take several minutes (compiling Rust code)...')
	println('Running: cargo build -p hero-coordinator --release\n')

	cmd := 'cd ${cfg.repo_path} && . ~/.cargo/env && RUSTFLAGS="-A warnings" cargo build -p hero-coordinator --release'
	osal.execute_stdout(cmd)!

	println('\n✅ Build completed successfully')

	// Ensure binary directory exists and copy the binary
	println('📁 Preparing binary directory: ${cfg.binary_path}')
	mut binary_path_obj := pathlib.get(cfg.binary_path)
	osal.dir_ensure(binary_path_obj.path_dir())!

	// Copy the built binary to the configured location
	source_binary := '${cfg.repo_path}/target/release/coordinator'
	println('📋 Copying binary from: ${source_binary}')
	println('📋 Copying binary to: ${cfg.binary_path}')
	mut source_file := pathlib.get_file(path: source_binary)!
	source_file.copy(dest: cfg.binary_path, rsync: false)!

	println('\n🎉 Coordinator built successfully!')
	println('📍 Binary location: ${cfg.binary_path}')
}

fn (mut self Coordinator) build() ! {
	console.print_header('build coordinator')

	println('Building coordinator binary from ${self}')

	// Ensure Redis is installed and running (required for coordinator)
	console.print_debug('Checking if Redis is installed and running...')
	redis_check := osal.exec(cmd: 'redis-cli -c -p 6379 ping', stdout: false, raise_error: false)!
	if redis_check.exit_code != 0 {
		console.print_header('Redis is not running, checking if installed...')
		if !osal.cmd_exists_profile('redis-server') {
			console.print_header('Installing Redis...')
			osal.package_install('redis-server')!
		}
		console.print_header('Starting Redis...')
		osal.exec(cmd: 'systemctl start redis-server')!
		console.print_debug('Redis started successfully')
	} else {
		console.print_debug('Redis is already running')
	}

	// Ensure rust is installed
	console.print_debug('Checking if Rust is installed...')
	mut rust_installer := rust.get()!
	res := osal.exec(cmd: 'rustc -V', stdout: false, raise_error: false)!
	if res.exit_code != 0 {
		console.print_header('Installing Rust first...')
		rust_installer.install()!
	} else {
		console.print_debug('Rust is already installed: ${res.output.trim_space()}')
	}

	// Clone or get the repository
	console.print_debug('Cloning/updating horus repository...')
	mut gs := gittools.new()!
	mut repo := gs.get_repo(
		url:   'https://git.ourworld.tf/herocode/horus.git'
		pull:  true
		reset: false
	)!

	// Update the path to the actual cloned repo
	self.repo_path = repo.path()
	set(self)!
	console.print_debug('Repository path: ${self.repo_path}')

	// Build the coordinator binary from the horus workspace
	console.print_header('Building coordinator binary (this may take several minutes ${self.repo_path})...')
	console.print_debug('Running: cargo build -p hero-coordinator --release')
	console.print_debug('Build output:')

	cmd := 'cd ${self.repo_path} && . ~/.cargo/env && RUSTFLAGS="-A warnings" cargo build -p hero-coordinator --release'
	osal.execute_stdout(cmd)!

	console.print_debug('Build completed successfully')

	// Ensure binary directory exists and copy the binary
	console.print_header('Preparing binary directory: ${self.binary_path}')
	mut binary_path_obj := pathlib.get(self.binary_path)
	osal.dir_ensure(binary_path_obj.path_dir())!

	// Copy the built binary to the configured location
	source_binary := '${self.repo_path}/target/release/coordinator'
	console.print_debug('Copying binary from: ${source_binary}')
	console.print_debug('Copying binary to: ${self.binary_path}')
	mut source_file := pathlib.get_file(path: source_binary)!
	source_file.copy(dest: self.binary_path, rsync: false)!

	console.print_header('coordinator built successfully at ${self.binary_path}')
}

fn (mut self Coordinator) destroy() ! {
	self.stop()!


	osal.process_kill_recursive(name: 'coordinator')!

	// Remove the built binary
	osal.rm(self.binary_path)!
}
