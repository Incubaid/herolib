module kubectl

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import incubaid.herolib.installers.ulist
import incubaid.herolib.installers.lang.golang
import incubaid.herolib.installers.lang.rust
import incubaid.herolib.installers.lang.python
import os

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn (self &Kubectl) installed() !bool {
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// res := os.execute('${osal.profile_path_source_and()!} kubectl version')
	// if res.exit_code != 0 {
	//     return false
	// }
	// r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	// if r.len != 1 {
	//     return error("couldn't parse kubectl version.\n${res.output}")
	// }
	// if texttools.version(version) == texttools.version(r[0]) {
	//     return true
	// }
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
	//     cmdname: 'kubectl'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/kubectl'
	// )!
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

fn (mut self Kubectl) install(args InstallArgs) ! {
	console.print_header('install kubectl')
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// mut url := ''
	// if core.is_linux_arm()! {
	//     url = 'https://github.com/kubectl-dev/kubectl/releases/download/v${version}/kubectl_${version}_linux_arm64.tar.gz'
	// } else if core.is_linux_intel()! {
	//     url = 'https://github.com/kubectl-dev/kubectl/releases/download/v${version}/kubectl_${version}_linux_amd64.tar.gz'
	// } else if core.is_osx_arm()! {
	//     url = 'https://github.com/kubectl-dev/kubectl/releases/download/v${version}/kubectl_${version}_darwin_arm64.tar.gz'
	// } else if osal.is_osx_intel()! {
	//     url = 'https://github.com/kubectl-dev/kubectl/releases/download/v${version}/kubectl_${version}_darwin_amd64.tar.gz'
	// } else {
	//     return error('unsported platform')
	// }

	// mut dest := osal.download(
	//     url: url
	//     minsize_kb: 9000
	//     expand_dir: '/tmp/kubectl'
	// )!

	// //dest.moveup_single_subdir()!

	// mut binpath := dest.file_get('kubectl')!
	// osal.cmd_add(
	//     cmdname: 'kubectl'
	//     source: binpath.path
	// )!
}

fn (mut self Kubectl) build() ! {
	// url := 'https://github.com/threefoldtech/kubectl'

	// make sure we install base on the node
	// if core.platform() != .ubuntu {
	//     return error('only support ubuntu for now')
	// }
	// golang.install()!

	// console.print_header('build kubectl')

	// gitpath := gittools.get_repo(coderoot: '/tmp/builder', url: url, reset: true, pull: true)!

	// cmd := '
	// cd ${gitpath}
	// source ~/.cargo/env
	// exit 1 #todo
	// '
	// osal.execute_stdout(cmd)!
	//
	// //now copy to the default bin path
	// mut binpath := dest.file_get('...')!
	// adds it to path
	// osal.cmd_add(
	//     cmdname: 'griddriver2'
	//     source: binpath.path
	// )!
}

fn (mut self Kubectl) destroy() ! {
	self.stop()!

	// mut systemdfactory := systemd.new()!
	// systemdfactory.destroy("zinit")!

	// osal.process_kill_recursive(name:'zinit')!
	// osal.cmd_delete('zinit')!

	// osal.package_remove('
	//    podman
	//    conmon
	//    buildah
	//    skopeo
	//    runc
	// ')!

	// //will remove all paths where go/bin is found
	// osal.profile_path_add_remove(paths2delete:"go/bin")!

	// osal.rm("
	//    podman
	//    conmon
	//    buildah
	//    skopeo
	//    runc
	//    /var/lib/containers
	//    /var/lib/podman
	//    /var/lib/buildah
	//    /tmp/podman
	//    /tmp/conmon
	// ")!
}
