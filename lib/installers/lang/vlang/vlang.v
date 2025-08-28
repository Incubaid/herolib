module vlang

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.ui.console
import os
import freeflowuniverse.herolib.installers.base
import freeflowuniverse.herolib.develop.gittools
// import freeflowuniverse.herolib.sysadmin.downloader

pub fn install(args_ InstallArgs) ! {
	mut args := args_
	version := '0.4.11'
	console.print_header('install vlang (reset: ${args.reset})')
	res := os.execute('${osal.profile_path_source_and()!} v --version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().starts_with('V'))
		if r.len != 1 {
			return error("couldn't parse v version.\n${res.output}")
		}
		myversion := r[0].all_after_first('V ').all_before(' ').trim_space()
		console.print_debug("V version: '${myversion}'")
		if texttools.version(version) > texttools.version(myversion) {
			// println(texttools.version(version))
			// println(texttools.version(myversion))
			// if true{panic("s")}
			args.reset = true
		}
	} else {
		args.reset = true
	}

	// install vlang if it was already done will return true
	if args.reset == false {
		return
	}

	base.develop()!

	osal.exec(cmd:'
		V_DIR="${os.home_dir()}/_code/v"

		mkdir -p "${os.home_dir()}/_code"

		cd ${os.home_dir()}/_code

		if [ ! -d "\${V_DIR}" ]; then
			echo "Cloning V..."
			git clone --depth=1 https://github.com/vlang/v "\${V_DIR}"
			
		else
			echo "V already exists, cleaning and updating..."
			cd "\${V_DIR}"
			git fetch origin
			git reset --hard origin/master
			git pull --rebase
		fi
		cd "\${V_DIR}"
		make
	')!

	mut extra := 'cd ${os.home_dir()}/_code/v'
	if core.is_linux()! {
		extra = '${extra}\n./v symlink'
	} else {
		extra = '${extra}\ncp v ${os.home_dir()}/hero/bin/'
	}
	osal.exec(cmd: extra, stdout: true)!
	
	console.print_header('compile done')

	osal.done_set('install_vlang', 'OK')!
	return
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}
