module osirisrunner

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.pathlib
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.installers.ulist
import incubaid.herolib.installers.lang.rust
import incubaid.herolib.develop.gittools
import os

fn (self &Osirisrunner) startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}

	// Ensure redis_addr has the redis:// prefix
	redis_url := if self.redis_addr.starts_with('redis://') {
		self.redis_addr
	} else {
		'redis://${self.redis_addr}'
	}

	res << startupmanager.ZProcessNewArgs{
		name: 'runner_osiris'
		cmd:  '${self.binary_path} --redis-url ${redis_url} 12002'
		env:  {
			'HOME':           os.home_dir()
			'RUST_LOG':       self.log_level
			'RUST_LOG_STYLE': 'never'
		}
	}

	return res
}

fn (self &Osirisrunner) running_check() !bool {
	// Check if the process is running
	res := osal.exec(cmd: 'pgrep -f runner_osiris', stdout: false, raise_error: false)!
	return res.exit_code == 0
}

fn (self &Osirisrunner) start_pre() ! {
}

fn (self &Osirisrunner) start_post() ! {
}

fn (self &Osirisrunner) stop_pre() ! {
}

fn (self &Osirisrunner) stop_post() ! {
}

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn (self &Osirisrunner) installed() !bool {
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
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

fn (mut self Osirisrunner) install(args InstallArgs) ! {
	console.print_header('install osirisrunner')
	// For osirisrunner, we build from source instead of downloading
	self.build()!
}

fn (mut self Osirisrunner) build() ! {
	console.print_header('build osirisrunner')

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

	// Build the osirisrunner binary from the horus workspace
	console.print_header('Building osirisrunner binary (this may take several minutes)...')
	console.print_debug('Running: cargo build -p runner-osiris --release')
	console.print_debug('Build output:')

	cmd := 'cd ${self.repo_path} && . ~/.cargo/env && RUSTFLAGS="-A warnings" cargo build -p runner-osiris --release'
	osal.execute_stdout(cmd)!

	console.print_debug('Build completed successfully')

	// Ensure binary directory exists and copy the binary
	console.print_debug('Preparing binary directory: ${self.binary_path}')
	mut binary_path_obj := pathlib.get(self.binary_path)
	osal.dir_ensure(binary_path_obj.path_dir())!

	// Copy the built binary to the configured location
	source_binary := '${self.repo_path}/target/release/runner_osiris'
	console.print_debug('Copying binary from: ${source_binary}')
	console.print_debug('Copying binary to: ${self.binary_path}')
	mut source_file := pathlib.get_file(path: source_binary)!
	source_file.copy(dest: self.binary_path, rsync: false)!

	console.print_header('osirisrunner built successfully at ${self.binary_path}')
}

fn (mut self Osirisrunner) destroy() ! {
	self.stop()!

	osal.process_kill_recursive(name: 'runner_osiris')!

	// Remove the built binary
	osal.rm(self.binary_path)!
}
