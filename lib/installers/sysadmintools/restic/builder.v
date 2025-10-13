module restic

// import incubaid.herolib.installers.base
import incubaid.herolib.installers.lang.golang
import incubaid.herolib.osal.core as osal
import incubaid.herolib.develop.gittools
import incubaid.herolib.ui.console

const url = 'https://github.com/restic/restic'

@[params]
pub struct BuildArgs {
pub mut:
	reset    bool
	bin_push bool = true
}

// install restic will return true if it was already installed
pub fn build(args BuildArgs) ! {
	// make sure we install base on the node
	if core.platform() != .ubuntu {
		return error('only support ubuntu for now')
	}
	golang.install()!

	// install restic if it was already done will return true
	console.print_header('build restic')

	mut gs := gittools.new(coderoot: '/tmp/builder')!
	mut repo := gs.get_repo(
		url:   url
		reset: true
		pull:  true
	)!

	mut gitpath := repo.path()

	cmd := '
	source ~/.cargo/env
	cd ${gitpath}
	exit 1 #todo
	'
	osal.execute_stdout(cmd)!

	// if args.bin_push {
	// 	installers.bin_push(
	// 		cmdname: 'restic'
	// 		source: '/tmp/builder/github/threefoldtech/restic/target/x86_64-unknown-linux-musl/release/restic'
	// 	)!
	// }
}
