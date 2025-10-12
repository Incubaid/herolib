module rclone

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import incubaid.herolib.installers.ulist
import os

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()!} rclone version')
	if res.exit_code != 0 {
		return false
	}
	r := res.output.split_into_lines().filter(it.contains('rclone v'))
	if r.len != 1 {
		return error("couldn't parse rclone version, expected 'rclone 0' on 1 row.\n${res.output}")
	}
	v := texttools.version(r[0].all_after('rclone'))
	if texttools.version(version) > v {
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
fn upload() ! {}

fn install() ! {
	console.print_header('install rclone')
	// Check if curl is installed
	mut res := os.execute('curl --version')
	if res.exit_code == 0 {
		console.print_header('curl is already installed')
	} else {
		osal.package_install('curl') or {
			return error('Could not install curl, its required to install rclone.\nerror:\n${err}')
		}
	}

	// Check if rclone is installed
	osal.execute_stdout('sudo -v ; curl https://rclone.org/install.sh | sudo bash') or {
		return error('cannot install rclone due to: ${err}')
	}

	console.print_header('rclone is installed')
}

fn destroy() ! {
	console.print_header('uninstall rclone')
	res := os.execute('sudo rm -rf /usr/local/bin/rclone /usr/local/rclone /usr/bin/rclone /usr/share/man/man1/rclone.1.gz')
	if res.exit_code != 0 {
		return error('failed to uninstall rclone: ${res.output}')
	}
	console.print_header('rclone is uninstalled')
}
