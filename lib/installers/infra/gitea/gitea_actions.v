module gitea

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.installers.ulist
import freeflowuniverse.herolib.osal.startupmanager
import os

fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()!} gitea version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().len > 0)
		if r.len != 1 {
			return error("couldn't parse gitea version.\n${res.output}")
		}
		if texttools.version(version) > texttools.version(r[0]) {
			return false
		}
	} else {
		return false
	}
	return true
}

fn install() ! {
	console.print_header('install gitea')
	baseurl := 'https://github.com/go-gitea/gitea/releases/download/v${version}/gitea-${version}'

	mut url := ''
	if core.is_linux_arm()! {
		url = '${baseurl}-linux-arm64.xz'
	} else if core.is_linux_intel()! {
		url = '${baseurl}-linux-amd64.xz'
	} else if core.is_osx_arm()! {
		url = '${baseurl}-darwin-10.12-arm64.xz'
	} else if core.is_osx_intel()! {
		url = '${baseurl}-darwin-10.12-amd64.xz'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 9000
		expand_dir: '/tmp/gitea'
	)!

	mut binpath := dest.file_get('gitea')!
	osal.cmd_add(
		cmdname: 'gitea'
		source:  binpath.path
	)!
}

fn build() ! {
	install()!
}

fn start_pre() ! {
}

fn start_post() ! {
}

fn stop_pre() ! {
}

fn stop_post() ! {
}

fn destroy() ! {
	mut server := get()!
	server.stop()!

	osal.process_kill_recursive(name: 'gitea')!
	osal.cmd_delete('gitea')!
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {}

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut cfg := get()!
	mut res := []startupmanager.ZProcessNewArgs{}
	res << startupmanager.ZProcessNewArgs{
		name: 'gitea'
		cmd:  'gitea server'
		env:  {
			'HOME':         os.home_dir()
			'GITEA_CONFIG': cfg.config_path()
		}
	}

	return res

	// 	mut res := []startupmanager.ZProcessNewArgs{}
	// 	cfg := get()!
	// 	res << startupmanager.ZProcessNewArgs{
	// 		name: 'gitea'
	// 		// cmd:     'GITEA_WORK_DIR=${cfg.path} sudo -u git /var/lib/git/gitea web -c /etc/gitea_app.ini'
	// 		cmd:     '

	// # Variables
	// GITEA_USER="${cfg.run_user}"
	// GITEA_HOME="${cfg.path}"
	// GITEA_BINARY="/usr/local/bin/gitea"
	// GITEA_CONFIG="/etc/gitea_app.ini"
	// GITEA_DATA_PATH="\$GITEA_HOME/data"
	// GITEA_CUSTOM_PATH="\$GITEA_HOME/custom"
	// GITEA_LOG_PATH="\$GITEA_HOME/log"

	// # Ensure the script is run as root
	// if [[ \$EUID -ne 0 ]]; then
	//     echo "This script must be run as root."
	//     exit 1
	// fi

	// echo "Setting up Gitea..."

	// # Create Gitea user if it doesn\'t exist
	// if id -u "\$GITEA_USER" &>/dev/null; then
	//     echo "User \$GITEA_USER already exists."
	// else
	//     echo "Creating Gitea user..."
	//     if ! sudo adduser --system --shell /bin/bash --group --disabled-password --home "/var/lib/\$GITEA_USER" "\$GITEA_USER"; then
	//         echo "Failed to create user \$GITEA_USER."
	//         exit 1
	//     fi
	// fi

	// # Create necessary directories
	// echo "Creating directories..."
	// mkdir -p "\$GITEA_DATA_PATH" "\$GITEA_CUSTOM_PATH" "\$GITEA_LOG_PATH"
	// chown -R "\$GITEA_USER:\$GITEA_USER" "\$GITEA_HOME"
	// chmod -R 750 "\$GITEA_HOME"

	// chown "\$GITEA_USER:\$GITEA_USER" "\$GITEA_CONFIG"
	// chmod 640 "\$GITEA_CONFIG"

	// GITEA_WORK_DIR=\$GITEA_HOME sudo -u git gitea web -c \$GITEA_CONFIG
	// '
	// 		workdir: cfg.path
	// 	}
	// 	res << startupmanager.ZProcessNewArgs{
	// 		name:    'restart_gitea'
	// 		cmd:     'sleep 30 && zinit restart gitea && exit 1'
	// 		after:   ['gitea']
	// 		oneshot: true
	// 		workdir: cfg.path
	// 	}
	// 	return res
}

fn running() !bool {
	// TODO: extend with proper gitea client
	res := os.execute('curl -fsSL http://localhost:3000 || exit 1')
	return res.exit_code == 0
}
