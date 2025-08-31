module podman

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.installers.ulist
import os

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()!} podman -v')
	if res.exit_code != 0 {
		println(res)
		return false
	}
	r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	if r.len != 1 {
		return error("couldn't parse podman version.\n${res.output}")
	}
	if texttools.version(version) <= texttools.version(r[0].all_after('version')) {
		return true
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
	console.print_header('install podman')

	// Linux installation using package manager
	if core.is_linux_arm()! || core.is_linux_intel()! {
		console.print_header('installing podman on linux')
		osal.package_install('podman,buildah,crun,mmdebstrap')!
		console.print_header('podman is installed')
		return
	}

	if core.is_osx_arm()! || core.is_osx_intel()! {
		console.print_header('installing podman on macos')
		osal.exec(cmd: 'brew install podman')!
		console.print_header('podman is installed')
		return
	}

	return error('unsupported platform')
}

fn destroy() ! {
	console.print_header('destroy podman')

	if !installed()! {
		console.print_header('podman is not installed')
		return
	}

	// Stop any running podman processes
	osal.exec(cmd: 'pkill -f podman', ignore_error: true)!

	if core.is_linux_arm()! || core.is_linux_intel()! {
		console.print_header('destroying podman on linux')
		osal.package_remove('
		   podman
		   buildah
		   mmdebstrap
		   crun
		')!
	} else if core.is_osx_arm()! || core.is_osx_intel()! {
		console.print_header('destroying podman on macos')
		osal.exec(cmd: 'brew uninstall podman')!
	} else {
		return error('unsupported platform')
	}

	// Remove temporary directories (common to all platforms)
	osal.rm('
	   /tmp/podman
	   /tmp/conmon
	')!

	console.print_header('podman destruction completed')
}
