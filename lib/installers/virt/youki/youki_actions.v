module youki

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.develop.gittools
import incubaid.herolib.installers.ulist
import incubaid.herolib.installers.lang.rust as rust_installer

// checks if a certain version or above is installed
fn installed() !bool {
	if osal.cmd_exists('youki') {
		return true
	}
	return false
}

fn install() ! {
	console.print_header('install youki')
	destroy()!
	build()!
}

fn build() ! {
	// mut installer := get()!
	url := 'https://github.com/containers/youki'

	mut rust := rust_installer.get()!
	rust.install()!

	console.print_header('build youki')

	//, tag:'v0.4.1'
	mut gs := gittools.new(coderoot: '/tmp/youki')!
	mut repo := gs.get_repo(
		url:   url
		reset: true
		pull:  true
	)!

	mut gitpath := repo.path()

	cmd := '
    cd ${gitpath}
    source ~/.cargo/env
    bash scripts/build.sh -o /tmp/youki/build -r -c youki
    '
	osal.execute_stdout(cmd)!

	osal.cmd_add(
		cmdname: 'youki'
		source:  '/tmp/youki/build/youki'
	)!
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {}

fn destroy() ! {
	osal.package_remove('
       runc
    ')!

	osal.rm('
       youki
    ')!
}
