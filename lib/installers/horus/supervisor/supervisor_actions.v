module supervisor

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.installers.ulist
import incubaid.herolib.installers.lang.rust
import incubaid.herolib.develop.gittools
import os

fn (self &Supervisor) startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}

	// Ensure redis_addr has the redis:// prefix
	redis_url := if self.redis_addr.starts_with('redis://') {
		self.redis_addr
	} else {
		'redis://${self.redis_addr}'
	}

	res << startupmanager.ZProcessNewArgs{
		name: 'supervisor'
		cmd:  '${self.binary_path} --redis-url ${redis_url} --port ${self.http_port} --admin-secret mysecret'
		env:  {
			'HOME':           os.home_dir()
			'RUST_LOG':       self.log_level
			'RUST_LOG_STYLE': 'never'
		}
	}

	return res
}

fn (self &Supervisor) running_check() !bool {
	// Check if the process is running by checking the HTTP port
	// The supervisor returns 405 for GET requests (requires POST), so we check if we get any response
	res := osal.exec(
		cmd:         'curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:${self.http_port}'
		stdout:      false
		raise_error: false
	)!
	// Any HTTP response code (including 405) means the server is running
	return res.output.len > 0 && res.output.int() > 0
}

fn (self &Supervisor) start_pre() ! {
}

fn (self &Supervisor) start_post() ! {
}

fn (self &Supervisor) stop_pre() ! {
}

fn (self &Supervisor) stop_post() ! {
}

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn (self &Supervisor) installed() !bool {
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
	//     cmdname: 'supervisor'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/supervisor'
	// )!
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

fn (mut self Supervisor) install(args InstallArgs) ! {
	console.print_header('install supervisor')
	// For supervisor, we build from source instead of downloading
	self.build()!
}

// Public function to build supervisor without requiring factory/redis
pub fn build_supervisor() ! {
	console.print_header('build supervisor')
	println('📦 Starting supervisor build process...\n')

	// Use default config instead of getting from factory
	println('⚙️  Initializing configuration...')
	mut cfg := Supervisor{}
	println('✅ Configuration initialized')
	println('   - Binary path: ${cfg.binary_path}')
	println('   - Redis address: ${cfg.redis_addr}')
	println('   - HTTP port: ${cfg.http_port}')
	println('   - WS port: ${cfg.ws_port}\n')

	// Ensure Redis is installed and running (required for supervisor)
	println('🔍 Step 1/4: Checking Redis dependency...')

	// First check if redis-server is installed
	if !osal.cmd_exists_profile('redis-server') {
		println('⚠️  Redis is not installed')
		println('📥 Installing Redis...')
		osal.package_install('redis-server')!
		println('✅ Redis installed')
	} else {
		println('✅ Redis is already installed')
	}

	// Now check if it's running
	println('🔍 Checking if Redis is running...')
	redis_check := osal.exec(cmd: 'redis-cli -c -p 6379 ping', stdout: false, raise_error: false)!
	if redis_check.exit_code != 0 {
		println('⚠️  Redis is not running')
		println('🚀 Starting Redis...')
		osal.exec(cmd: 'systemctl start redis-server')!
		println('✅ Redis started successfully\n')
	} else {
		println('✅ Redis is already running\n')
	}

	// Ensure rust is installed
	println('🔍 Step 2/4: Checking Rust dependency...')
	mut rust_installer := rust.get()!
	res := osal.exec(cmd: 'rustc -V', stdout: false, raise_error: false)!
	if res.exit_code != 0 {
		println('📥 Installing Rust...')
		rust_installer.install()!
		println('✅ Rust installed\n')
	} else {
		println('✅ Rust is already installed: ${res.output.trim_space()}\n')
	}

	// Clone or get the repository
	println('🔍 Step 3/4: Cloning/updating horus repository...')
	mut gs := gittools.new()!
	mut repo := gs.get_repo(
		url:   'https://git.ourworld.tf/herocode/horus.git'
		pull:  true
		reset: false
	)!

	// Update the path to the actual cloned repo
	cfg.repo_path = repo.path()
	println('✅ Repository ready at: ${cfg.repo_path}\n')

	// Build the supervisor binary from the horus workspace
	println('🔍 Step 4/4: Building supervisor binary...')
	println('⚠️  This may take several minutes (compiling Rust code)...')
	println('📝 Running: cargo build -p hero-supervisor --release\n')

	cmd := 'cd ${cfg.repo_path} && . ~/.cargo/env && RUSTFLAGS="-A warnings" cargo build -p hero-supervisor --release'
	osal.execute_stdout(cmd)!

	println('\n✅ Build completed successfully')

	// Ensure binary directory exists and copy the binary
	println('📁 Preparing binary directory: ${cfg.binary_path}')
	mut binary_path_obj := pathlib.get(cfg.binary_path)
	osal.dir_ensure(binary_path_obj.path_dir())!

	// Copy the built binary to the configured location
	source_binary := '${cfg.repo_path}/target/release/supervisor'
	println('📋 Copying binary from: ${source_binary}')
	println('📋 Copying binary to: ${cfg.binary_path}')
	mut source_file := pathlib.get_file(path: source_binary)!
	source_file.copy(dest: cfg.binary_path, rsync: false)!

	println('\n🎉 Supervisor built successfully!')
	println('📍 Binary location: ${cfg.binary_path}')
}

fn (mut self Supervisor) build() ! {
	console.print_header('build supervisor')

	// Ensure Redis is installed and running (required for supervisor)
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

	// Build the supervisor binary from the horus workspace
	console.print_header('Building supervisor binary (this may take several minutes)...')
	console.print_debug('Running: cargo build -p hero-supervisor --release')
	console.print_debug('Build output:')

	cmd := 'cd ${self.repo_path} && . ~/.cargo/env && RUSTFLAGS="-A warnings" cargo build -p hero-supervisor --release'
	osal.execute_stdout(cmd)!

	console.print_debug('Build completed successfully')

	// Ensure binary directory exists and copy the binary
	console.print_debug('Preparing binary directory: ${self.binary_path}')
	mut binary_path_obj := pathlib.get(self.binary_path)
	osal.dir_ensure(binary_path_obj.path_dir())!

	// Copy the built binary to the configured location
	source_binary := '${self.repo_path}/target/release/supervisor'
	console.print_debug('Copying binary from: ${source_binary}')
	console.print_debug('Copying binary to: ${self.binary_path}')
	mut source_file := pathlib.get_file(path: source_binary)!
	source_file.copy(dest: self.binary_path, rsync: false)!

	console.print_header('supervisor built successfully at ${self.binary_path}')
}

fn (mut self Supervisor) destroy() ! {
	self.stop()!

	osal.process_kill_recursive(name: 'supervisor')!

	// Remove the built binary
	osal.rm(self.binary_path)!
}
