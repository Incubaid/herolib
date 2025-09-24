module tailwind4

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.installers.ulist
import os
//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('tailwindcss4 -h')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.contains('tailwindcss v'))
		if r.len != 1 {
			return error("couldn't parse tailwind4 version, expected 'tailwindcss v' on 1 row.\n${res.output}")
		}

		v := texttools.version(r[0].all_after(' '))
		if v < texttools.version(version) {
			return false
		}
		return true
	} else {
		println('error in executing tailwindcss')
		println(res)
	}
	return false
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

fn upload() ! {
}

fn install() ! {
	console.print_header('install tailwind4')

	mut url := ''
	if core.is_linux_arm()! {
		url = 'https://github.com/tailwindlabs/tailwindcss/releases/download/v${version}/tailwindcss-linux-arm64'
	} else if core.is_linux_intel()! {
		url = 'https://github.com/tailwindlabs/tailwindcss/releases/download/v${version}/tailwindcss-linux-x64'
	} else if core.is_osx_arm()! {
		url = 'https://github.com/tailwindlabs/tailwindcss/releases/download/v${version}/tailwindcss-macos-arm64'
	} else if core.is_osx_intel()! {
		url = 'https://github.com/tailwindlabs/tailwindcss/releases/download/v${version}/tailwindcss-macos-x64'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 40000
		// reset: true
	)!

	osal.cmd_add(
		cmdname: 'tailwind4'
		source:  dest.path
	)!
}

fn destroy() ! {}
