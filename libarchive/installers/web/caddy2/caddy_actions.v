module caddy

import freeflowuniverse.herolib.osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.osal.systemd
import freeflowuniverse.herolib.osal.zinit
import freeflowuniverse.herolib.installers.ulist
import os

fn startupcmd() ![]zinit.ZProcessNewArgs {
	mut res := []zinit.ZProcessNewArgs{}
	res << zinit.ZProcessNewArgs{
		name: 'caddy'
		cmd:  'caddy run --config /etc/caddy/Caddyfile'
	}
	return res
}

fn running() !bool {
	res := os.execute('${osal.profile_path_source_and()!} caddy version')
	if res.exit_code == 0 {
		mut r := res.output.split_into_lines().filter(it.trim_space().len > 0)
		if r.len > 1 {
			r = r.filter(it.starts_with('v'))
		}
		if r.len != 1 {
			return error("couldn't parse caddy version.\n${r}")
		}
		if texttools.version(version) > texttools.version(r[0]) {
			return false
		}
		return true
	}
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
fn installed() !bool {
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// res := os.execute('${osal.profile_path_source_and()!} caddy version')
	// if res.exit_code != 0 {
	//     return false
	// }
	// r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	// if r.len != 1 {
	//     return error("couldn't parse caddy version.\n${res.output}")
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
	//     cmdname: 'caddy'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/caddy'
	// )!
}

fn install() ! {
	console.print_header('install caddy')

	mut cfg := get()!

	mut url := ''
	if core.is_linux_arm()! {
		url = 'https://github.com/caddyserver/xcaddy/releases/download/v${xcaddy_version}/xcaddy_${xcaddy_version}_linux_arm64.tar.gz'
	} else if core.is_linux_intel()! {
		url = 'https://github.com/caddyserver/xcaddy/releases/download/v${xcaddy_version}/xcaddy_${xcaddy_version}_linux_amd64.tar.gz'
	} else if core.is_osx_arm()! {
		url = 'https://github.com/caddyserver/xcaddy/releases/download/v${xcaddy_version}/xcaddy_${xcaddy_version}_mac_arm64.tar.gz'
	} else if core.is_osx_intel()! {
		url = 'https://github.com/caddyserver/xcaddy/releases/download/v${xcaddy_version}/xcaddy_${xcaddy_version}_mac_amd64.tar.gz'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 1000
		expand_dir: '/tmp/xcaddy_dir'
	)!

	mut binpath := dest.file_get('xcaddy')!
	osal.cmd_add(
		cmdname: 'xcaddy'
		source:  binpath.path
	)!

	console.print_header('Installing Caddy with xcaddy')

	plugins_str := cfg.plugins.map('--with ${it}').join(' ')

	// Define the xcaddy command to build Caddy with plugins
	path := '/tmp/caddyserver/caddy'
	cmd := 'source ${osal.profile_path()!} && xcaddy build v${caddy_version} ${plugins_str} --output ${path}'
	osal.exec(cmd: cmd)!
	osal.cmd_add(
		cmdname: 'caddy'
		source:  path
		reset:   true
	)!
}

fn destroy() ! {
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

// configure caddy as default webserver & start
// node, path, domain
// path e.g. /var/www
// domain e.g. www.myserver.com
pub fn configure_examples(config WebConfig) ! {
	mut config_file := $tmpl('templates/caddyfile_default')
	if config.domain.len > 0 {
		config_file = $tmpl('templates/caddyfile_domain')
	}
	os.mkdir_all(config.path)!

	default_html := '
	<!DOCTYPE html>
	<html>
		<head>
			<title>Caddy has now been installed.</title>
		</head>
		<body>
			Caddy has been installed and is working in /var/www.
		</body>
	</html>
	'
	osal.file_write('${config.path}/index.html', default_html)!

	configuration_set(content: config_file)!
}
