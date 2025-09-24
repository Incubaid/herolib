module garage_s3

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.osal.startupmanager
import freeflowuniverse.herolib.installers.ulist
import freeflowuniverse.herolib.libarchive.zinit as zinit_lib
import freeflowuniverse.herolib.core.httpconnection
import os
import json

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}
	res << startupmanager.ZProcessNewArgs{
		name:        'garage_s3'
		cmd:         'garage_s3 -c /var/garage/config.toml server'
		startuptype: .zinit
		env:         {
			'HOME': '/root'
		}
	}

	return res
}

struct GarageS3InstanceStatus {
	status            string
	known_nodes       int @[json: 'knownNodes']
	connected_nodes   int @[json: 'connectedNodes']
	storage_nodes     int @[json: 'storageNodes']
	storage_nodes_ok  int @[json: 'storageNodesOk']
	partitions        int @[json: 'partitions']
	partitions_quorum int @[json: 'partitionsQuorum']
	partitions_all_ok int @[json: 'partitionsAllOk']
}

fn running() !bool {
	mut installer := get()!
	url := 'http://127.0.0.1:3903/'
	if installer.admin_token.len < 0 {
		return false
	}

	mut conn := httpconnection.new(name: 'garage_s3', url: url)!
	conn.default_header.add(.authorization, 'Bearer ${installer.admin_token}')

	r := conn.get_json_dict(prefix: 'v1/health', debug: false) or { return false }
	if r.len == 0 {
		return false
	}

	decoded_response := json.decode(GarageS3InstanceStatus, r.str()) or { return false }

	if decoded_response.status != 'healthy' {
		return false
	}
	return true
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
	res := os.execute('${osal.profile_path_source_and()!} garage_s3 version')
	if res.exit_code != 0 {
		return false
	}

	r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	if r.len != 1 {
		return error("couldn't parse garage_s3 version.\n${res.output}")
	}

	if texttools.version(version) > texttools.version(r[0]) {
		return false
	}

	return true
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {}

fn install() ! {
	console.print_header('install garage_s3')

	mut res := os.execute('garage_s3 --version')
	if res.exit_code == 0 {
		console.print_header('garage_s3 is already installed')
		return
	}

	p := core.platform()!

	if p != .ubuntu {
		return error('unsupported platform')
	}

	mut url := ''
	if core.is_linux_arm()! {
		url = 'https://garagehq.deuxfleurs.fr/_releases/v${version}/aarch64-unknown-linux-musl/garage'
	}
	if core.is_linux_intel()! {
		url = 'https://garagehq.deuxfleurs.fr/_releases/v${version}/x86_64-unknown-linux-musl/garage'
	}

	res = os.execute('wget --version')
	if res.exit_code == 0 {
		console.print_header('wget is already installed')
	} else {
		osal.package_install('wget') or {
			return error('Could not install wget, its required to install rclone.\nerror:\n${err}')
		}
	}

	// Check if garage_s3 is installed
	osal.execute_stdout('sudo wget -O /usr/local/bin/garage_s3 ${url}') or {
		return error('cannot install garage_s3 due to: ${err}')
	}

	res = os.execute('sudo chmod +x /usr/local/bin/garage_s3')
	if res.exit_code != 0 {
		return error('failed to install garage_s3: ${res.output}')
	}

	console.print_header('garage_s3 is installed')
}

fn destroy() ! {
	console.print_header('uninstall garage_s3')
	res := os.execute('sudo rm -rf /usr/local/bin/garage_s3')
	if res.exit_code != 0 {
		return error('failed to uninstall garage_s3: ${res.output}')
	}

	// mut zinit_factory := zinit_lib.Zinit{}

	// if zinit_factory.exists('garage_s3'){
	// 	zinit_factory.stop('garage_s3') or {
	// 		return error('Could not stop garage_s3 service due to: ${err}')
	// 	}
	// 	zinit_factory.delete('garage_s3') or {
	// 		return error('Could not delete garage_s3 service due to: ${err}')
	// 	}
	// }

	console.print_header('garage_s3 is uninstalled')
}
