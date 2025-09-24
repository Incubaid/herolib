module python

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.installers.base
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.installers.ulist
import freeflowuniverse.herolib.core.texttools
import os

//////////////////// following actions are not specific to instance of the object

fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()!} uv self version')
	if res.exit_code != 0 {
		return false
	}
	r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	if r.len != 1 {
		return error("couldn't parse python version.\n${res.output}")
	}
	r2 := r[0].split(' ')[1] or { return error("couldn't parse python version.\n${res.output}") }
	if texttools.version(version) <= texttools.version(r2) {
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
	//     cmdname: 'python'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/python'
	// )!
}

fn install() ! {
	console.print_header('install python')
	base.install()!

	osal.package_install('python3')!
	pl := core.platform()!
	if pl == .ubuntu {
		osal.package_install('python3')!
	} else if pl == .osx {
		osal.package_install('python@3.12')!
	} else {
		return error('only support osx & ubuntu.')
	}
	osal.execute_silent('curl -LsSf https://astral.sh/uv/install.sh | sh')!
	if pl == .ubuntu {
		osal.execute_silent('echo \'eval "$(uvx --generate-shell-completion bash)"\' >> ~/.bashrc')!
	} else if pl == .osx {
		osal.execute_silent('echo \'eval "$(uvx --generate-shell-completion bash)"\' >> ~/.bashrc')!
		osal.execute_silent('echo \'eval "$(uvx --generate-shell-completion bash)"\' >> ~/.zshrc')!
	} else {
		return error('only support osx & ubuntu.')
	}
}

fn destroy() ! {
	console.print_header('remove python uv')

	// //will remove all paths where go/bin is found
	// osal.profile_path_add_remove(paths2delete:"go/bin")!

	dir1 := osal.exec_fast(cmd: 'uv python dir', notempty: true)!
	dir2 := osal.exec_fast(cmd: 'uv tool dir', notempty: true)!
	dir3 := osal.exec_fast(cmd: 'uv cache dir', notempty: true)!

	osal.execute_silent('

	uv cache clean
	rm -rf "${dir1}"
	rm -rf "${dir2}"
	rm -rf "${dir3}"
	rm ~/.local/bin/uv ~/.local/bin/uvx
	')!
	osal.rm('
	   uv
	   uvx
	')!
}
