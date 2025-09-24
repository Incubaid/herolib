module zerofs

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.osal.systemd
import freeflowuniverse.herolib.osal.startupmanager
import freeflowuniverse.herolib.installers.ulist
import freeflowuniverse.herolib.installers.lang.golang
import freeflowuniverse.herolib.installers.lang.rust
import freeflowuniverse.herolib.installers.lang.python
import os

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut installer := get()!
	mut res := []startupmanager.ZProcessNewArgs{}
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// res << startupmanager.ZProcessNewArgs{
	//     name: 'zerofs'
	//     cmd: 'zerofs server'
	//     env: {
	//         'HOME': '/root'
	//     }
	// }

	return res
}

fn running_() !bool {
	mut installer := get()!
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// this checks health of zerofs
	// curl http://localhost:3333/api/v1/s --oauth2-bearer 1234 works
	// url:='http://127.0.0.1:${cfg.port}/api/v1'
	// mut conn := httpconnection.new(name: 'zerofs', url: url)!

	// if cfg.secret.len > 0 {
	//     conn.default_header.add(.authorization, 'Bearer ${cfg.secret}')
	// }
	// conn.default_header.add(.content_type, 'application/json')
	// console.print_debug("curl -X 'GET' '${url}'/tags --oauth2-bearer ${cfg.secret}")
	// r := conn.get_json_dict(prefix: 'tags', debug: false) or {return false}
	// println(r)
	// if true{panic("ssss")}
	// tags := r['Tags'] or { return false }
	// console.print_debug(tags)
	// console.print_debug('zerofs is answering.')
	return false
}

fn start_pre() ! {
}

fn start_post() ! {
}

fn stop_pre() ! {
}

fn stop_post() ! {
}

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed_() !bool {
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// res := os.execute('${osal.profile_path_source_and()!} zerofs version')
	// if res.exit_code != 0 {
	//     return false
	// }
	// r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	// if r.len != 1 {
	//     return error("couldn't parse zerofs version.\n${res.output}")
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
fn upload_() ! {
	// installers.upload(
	//     cmdname: 'zerofs'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/zerofs'
	// )!
}

fn install_() ! {
	console.print_header('install zerofs')
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// mut url := ''
	// if core.is_linux_arm()! {
	//     url = 'https://github.com/zerofs-dev/zerofs/releases/download/v${version}/zerofs_${version}_linux_arm64.tar.gz'
	// } else if core.is_linux_intel()! {
	//     url = 'https://github.com/zerofs-dev/zerofs/releases/download/v${version}/zerofs_${version}_linux_amd64.tar.gz'
	// } else if core.is_osx_arm()! {
	//     url = 'https://github.com/zerofs-dev/zerofs/releases/download/v${version}/zerofs_${version}_darwin_arm64.tar.gz'
	// } else if core.is_osx_intel()! {
	//     url = 'https://github.com/zerofs-dev/zerofs/releases/download/v${version}/zerofs_${version}_darwin_amd64.tar.gz'
	// } else {
	//     return error('unsported platform')
	// }

	// mut dest := osal.download(
	//     url: url
	//     minsize_kb: 9000
	//     expand_dir: '/tmp/zerofs'
	// )!

	// //dest.moveup_single_subdir()!

	// mut binpath := dest.file_get('zerofs')!
	// osal.cmd_add(
	//     cmdname: 'zerofs'
	//     source: binpath.path
	// )!
}

fn build_() ! {
	// url := 'https://github.com/threefoldtech/zerofs'

	// make sure we install base on the node
	// if core.platform()!= .ubuntu {
	//     return error('only support ubuntu for now')
	// }
	// golang.install()!

	// console.print_header('build zerofs')

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

fn destroy_() ! {
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
