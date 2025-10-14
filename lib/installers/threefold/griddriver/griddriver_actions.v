module griddriver

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core
import incubaid.herolib.core.texttools
import incubaid.herolib.installers.ulist
import os

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('griddriver --version')
	if res.exit_code != 0 {
		return false
	}

	r := res.output.split(' ')
	if r.len != 3 {
		return error("couldn't parse griddriver version.\n${res.output}")
	}

	if texttools.version(version) > texttools.version(r[2]) {
		return false
	}

	return true
}

fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {}

fn build() ! {
	// griddriver is distributed as a binary, no build needed
	// just call install
	install()!
}

fn install() ! {
	console.print_header('installing griddriver')
	mut url := ''
	if core.is_linux_arm()! {
		url = 'https://github.com/threefoldtech/griddriver/releases/download/v${version}/griddriver_${version}_linux_arm64'
	} else if core.is_linux_intel()! {
		url = 'https://github.com/threefoldtech/griddriver/releases/download/v${version}/griddriver_${version}_linux_amd64'
	} else if core.is_osx_arm()! {
		url = 'https://github.com/threefoldtech/griddriver/releases/download/v${version}/griddriver_${version}_darwin_arm64'
	} else if core.is_osx_intel()! {
		url = 'https://github.com/threefoldtech/griddriver/releases/download/v${version}/griddriver_${version}_darwin_amd64'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 1000
	)!

	osal.cmd_add(
		cmdname: 'griddriver'
		source:  dest.path
	)!
	console.print_header('install griddriver OK')
}

fn destroy() ! {
	console.print_header('uninstall griddriver')
	binpath := osal.bin_path()!
	mut res := os.execute('sudo rm -rf ${binpath}/griddriver')
	if res.exit_code != 0 {
		return error('failed to uninstall griddriver: ${res.output}')
	}

	console.print_header('uninstall griddriver OK')
}
