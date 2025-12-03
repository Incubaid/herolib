module actrunner

import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.installers.ulist
import incubaid.herolib.osal.core as osal
import incubaid.herolib.core
import incubaid.herolib.clients.zinit
import os

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}
	res << startupmanager.ZProcessNewArgs{
		name:        'actrunner'
		cmd:         'actrunner daemon'
		startuptype: .zinit
		env:         {
			'HOME': '/root'
		}
	}

	return res
}

fn running() !bool {
	mut zinit_factory := zinit.new()!
	if zinit_factory.service_exists('actrunner')! {
		status := zinit_factory.service_status('actrunner')!
		return status.state == 'Running'
	}
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
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	res := os.execute('actrunner --version')
	if res.exit_code != 0 {
		return false
	}
	r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	if r.len != 1 {
		return error("couldn't parse actrunner version.\n${res.output}")
	}
	if texttools.version(version) == texttools.version(r[0]) {
		return true
	}
	return false
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {}

fn install() ! {
	console.print_header('install actrunner')
	mut url := ''
	if core.is_linux_arm()! {
		url = 'https://gitea.com/gitea/act_runner/releases/download/v${version}/act_runner-${version}-linux-arm64'
	} else if core.is_linux_intel()! {
		url = 'https://gitea.com/gitea/act_runner/releases/download/v${version}/act_runner-${version}-linux-amd64'
	} else if core.is_osx_arm()! {
		url = 'https://gitea.com/gitea/act_runner/releases/download/v${version}/act_runner-${version}-darwin-arm64'
	} else if core.is_osx_intel()! {
		url = 'https://gitea.com/gitea/act_runner/releases/download/v${version}/act_runner-${version}-darwin-amd64'
	} else {
		return error('unsupported platform')
	}

	// Download to temp location using osal.download (uses curl, commonly pre-installed)
	mut dest := osal.download(
		url:        url
		minsize_kb: 1000
	) or { return error('failed to download actrunner: ${err}') }

	// Install to ~/hero/bin (user-writable, no sudo required)
	osal.cmd_add(
		cmdname: 'actrunner'
		source:  dest.path
	)!
}

fn build() ! {}

fn destroy() ! {
	console.print_header('uninstall actrunner')
	mut zinit_factory := zinit.new()!

	if zinit_factory.service_exists('actrunner') or { false } {
		zinit_factory.service_stop('actrunner') or {
			return error('Could not stop actrunner service due to: ${err}')
		}
		zinit_factory.service_delete('actrunner') or {
			return error('Could not delete actrunner service due to: ${err}')
		}
	}

	// Remove the binary using osal.cmd_delete (handles ~/hero/bin and other locations)
	osal.cmd_delete('actrunner')!
	console.print_header('actrunner is uninstalled')
}
