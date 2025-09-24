module actrunner

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.osal.startupmanager
import freeflowuniverse.herolib.installers.ulist
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core
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
	if zinit_factory.exists('actrunner') {
		is_running := zinit_factory.get('actrunner')!
		println('is_running: ${is_running}')
		return true
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
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
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
		return error('unsported platform')
	}

	osal.package_install('wget') or { return error('Could not install wget due to: ${err}') }

	mut res := os.execute('sudo wget -O /usr/local/bin/actrunner ${url}')
	if res.exit_code != 0 {
		return error('failed to install actrunner: ${res.output}')
	}

	res = os.execute('sudo chmod +x /usr/local/bin/actrunner')
	if res.exit_code != 0 {
		return error('failed to install actrunner: ${res.output}')
	}
}

fn build() ! {}

fn destroy() ! {
	console.print_header('uninstall actrunner')
	mut zinit_factory := zinit.new()!

	if zinit_factory.exists('actrunner') {
		zinit_factory.stop('actrunner') or {
			return error('Could not stop actrunner service due to: ${err}')
		}
		zinit_factory.delete('actrunner') or {
			return error('Could not delete actrunner service due to: ${err}')
		}
	}

	res := os.execute('sudo rm -rf /usr/local/bin/actrunner')
	if res.exit_code != 0 {
		return error('failed to uninstall actrunner: ${res.output}')
	}
	console.print_header('actrunner is uninstalled')
}
