module herodb

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.installers.ulist
import incubaid.herolib.installers.lang.rust
import incubaid.herolib.develop.gittools

@[params]
pub struct StartArgs {
pub mut:
	reset bool
}

fn (self &HeroDBInstaller) startupcmd(args StartArgs) ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}

	// build the herodb startup command with configuration options
	mut cmd := 'herodb --data ${self.path} --port ${self.port} --socket ${self.rpc_socket}'
	if self.adminsecret.len > 0 {
		cmd += ' --admin-secret ${self.adminsecret}'
	}

	res << startupmanager.ZProcessNewArgs{
		name:        'herodb'
		cmd:         cmd
		reset:       args.reset
		startuptype: .zinit
		env:         {
			'HOME': '/root'
		}
	}

	return res
}

fn (self &HeroDBInstaller) running_check() !bool {
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// this checks health of herodb
	// curl http://localhost:3333/api/v1/s --oauth2-bearer 1234 works
	// url:='http://127.0.0.1:${cfg.port}/api/v1'
	// mut conn := httpconnection.new(name: 'herodb', url: url)!

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
	// console.print_debug('herodb is answering.')
	return false
}

fn (self &HeroDBInstaller) start_pre() ! {
}

fn (self &HeroDBInstaller) start_post() ! {
}

fn (self &HeroDBInstaller) stop_pre() ! {
}

fn (self &HeroDBInstaller) stop_post() ! {
}

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn (self &HeroDBInstaller) installed() !bool {
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// res := os.execute('${osal.profile_path_source_and()!} herodb version')
	// if res.exit_code != 0 {
	//     return false
	// }
	// r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	// if r.len != 1 {
	//     return error("couldn't parse herodb version.\n${res.output}")
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
	//     cmdname: 'herodb'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/herodb'
	// )!
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

fn (mut self HeroDBInstaller) install(args InstallArgs) ! {
	console.print_header('install herodb')
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// mut url := ''
	// if core.is_linux_arm()! {
	//     url = 'https://github.com/herodb-dev/herodb/releases/download/v${version}/herodb_${version}_linux_arm64.tar.gz'
	// } else if core.is_linux_intel()! {
	//     url = 'https://github.com/herodb-dev/herodb/releases/download/v${version}/herodb_${version}_linux_amd64.tar.gz'
	// } else if core.is_osx_arm()! {
	//     url = 'https://github.com/herodb-dev/herodb/releases/download/v${version}/herodb_${version}_darwin_arm64.tar.gz'
	// } else if osal.is_osx_intel()! {
	//     url = 'https://github.com/herodb-dev/herodb/releases/download/v${version}/herodb_${version}_darwin_amd64.tar.gz'
	// } else {
	//     return error('unsported platform')
	// }

	// mut dest := osal.download(
	//     url: url
	//     minsize_kb: 9000
	//     expand_dir: '/tmp/herodb'
	// )!

	// //dest.moveup_single_subdir()!

	// mut binpath := dest.file_get('herodb')!
	// osal.cmd_add(
	//     cmdname: 'herodb'
	//     source: binpath.path
	// )!
}

fn (mut self HeroDBInstaller) build() ! {
	url := 'https://forge.ourworld.tf/lhumina_code/herodb'

	// make sure we are on a supported platform
	if !core.is_linux()! {
		return error('only support linux for now')
	}

	mut i := rust.new()!
	i.install()!

	console.print_header('build herodb')

	mut gs := gittools.new(coderoot: '/tmp/builder')!
	mut repo := gs.get_repo(
		url:   url
		reset: true
		pull:  true
	)!
	gitpath := repo.path()

	cmd := '
	set -ex
	cd ${gitpath}
	source ~/.cargo/env
	cargo build --release
	'
	osal.execute_stdout(cmd)!

	// copy the built binary to the system path
	osal.cmd_add(
		cmdname: 'herodb'
		source:  '${gitpath}/target/release/herodb'
	)!
}

fn (mut self HeroDBInstaller) destroy() ! {
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
