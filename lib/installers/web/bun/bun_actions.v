module bun

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import incubaid.herolib.installers.ulist
import os

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	checkcmd := '${os.home_dir()}/.bun/bin/bun -version'
	res := os.execute(checkcmd)
	if res.exit_code != 0 {
		println(res)
		println(checkcmd)
		return false
	}
	r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	if r.len != 1 {
		return error("couldn't parse bun version.\n${res.output}")
	}
	// println(' ${texttools.version(version)} <= ${texttools.version(r[0])}')
	if texttools.version(version) <= texttools.version(r[0]) {
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
fn upload() ! {
	// installers.upload(
	//     cmdname: 'bun'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/bun'
	// )!
}

fn install() ! {
	console.print_header('install bun')
	destroy()!
	osal.exec(cmd: 'unset BUN_INSTALL && curl -fsSL https://bun.sh/install | bash')!
}

fn destroy() ! {
	// osal.process_kill_recursive(name:'bun')!

	osal.cmd_delete('bun')!

	// Note: bun is not an apt package, it's installed via curl script
	// so we don't try to remove it via package manager

	// will remove all paths where bun is found
	osal.profile_path_add_remove(paths2delete: 'bun')!

	osal.rm('
        ~/.bun
    ')!
}
