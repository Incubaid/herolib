module crun_installer

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core
import incubaid.herolib.installers.ulist
import os

//////////////////// following actions are not specific to instance of the object

// checks if crun is installed
pub fn (self &CrunInstaller) installed() !bool {
	res := os.execute('${osal.profile_path_source_and()!} crun --version')
	if res.exit_code != 0 {
		return false
	}
	return true
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
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

pub fn (mut self CrunInstaller) install(args InstallArgs) ! {
	console.print_header('install crun')

	// Check platform support
	pl := core.platform()!

	if pl == .ubuntu || pl == .arch {
		console.print_debug('installing crun via package manager')
		osal.package_install('crun')!
		console.print_header('crun is installed')
		return
	}

	if pl == .osx {
		return error('crun is not available on macOS - it is a Linux-only container runtime. On macOS, use Docker Desktop or Podman Desktop instead.')
	}

	return error('unsupported platform for crun installation')
}

pub fn (mut self CrunInstaller) destroy() ! {
	console.print_header('destroy crun')

	if !self.installed()! {
		console.print_debug('crun is not installed')
		return
	}

	pl := core.platform()!

	if pl == .ubuntu || pl == .arch {
		console.print_debug('removing crun via package manager')
		osal.package_remove('crun')!
		console.print_header('crun has been removed')
		return
	}

	if pl == .osx {
		return error('crun is not available on macOS')
	}

	return error('unsupported platform for crun removal')
}
