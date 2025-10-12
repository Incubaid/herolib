module tailwind

import incubaid.herolib.osal.core as osal
import incubaid.herolib.core
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.installers.ulist
import os
//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('tailwindcss -h')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.contains('tailwindcss v'))
		if r.len != 1 {
			return error("couldn't parse tailwind version, expected 'tailwindcss v' on 1 row.\n${res.output}")
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

// uploads to S3 server if configured
fn upload() ! {
	// installers.upload(
	//     cmdname: 'tailwind'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/tailwind'
	// )!
}

fn install() ! {
	console.print_header('install tailwind')

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
		cmdname: 'tailwind'
		source:  dest.path
	)!
}

fn destroy() ! {}
