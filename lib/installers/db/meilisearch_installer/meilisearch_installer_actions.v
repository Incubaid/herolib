module meilisearch_installer

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.startupmanager
import freeflowuniverse.herolib.installers.ulist
import freeflowuniverse.herolib.core.httpconnection
import freeflowuniverse.herolib.core.texttools
import os
import rand
import json

fn generate_master_key(length int) !string {
	mut key := []rune{}
	valid_chars := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

	for _ in 0 .. length {
		random_index := rand.int_in_range(0, valid_chars.len)!
		key << valid_chars[random_index]
	}

	return key.string()
}

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}
	mut installer := get()!
	mut env := 'development'
	if installer.production {
		env = 'production'
	}
	res << startupmanager.ZProcessNewArgs{
		name:        'meilisearch'
		cmd:         'meilisearch --no-analytics --http-addr ${installer.host}:${installer.port} --env ${env} --db-path ${installer.path} --master-key ${installer.masterkey}'
		startuptype: .zinit
		start:       true
		restart:     true
	}

	return res
}

struct MeilisearchVersionResponse {
	version     string @[json: 'pkgVersion']
	commit_date string @[json: 'commitDate']
	commit_sha  string @[json: 'commitSha']
}

fn running() !bool {
	mut cfg := get()!
	url := 'http://${cfg.host}:${cfg.port}'
	mut conn := httpconnection.new(name: 'meilisearchinstaller', url: url)!
	conn.default_header.add(.authorization, 'Bearer ${cfg.masterkey}')
	response := conn.get(prefix: 'version', debug: true) or {
		return error('Failed to get meilisearch version: ${err}')
	}
	decoded_response := json.decode(MeilisearchVersionResponse, response) or {
		return error('Failed to decode meilisearch version: ${err}')
	}

	if decoded_response.version == '' {
		console.print_stderr('Meilisearch is not running')
		return false
	}

	console.print_header('Meilisearch is running')
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
	res := os.execute('${osal.profile_path_source_and()!} meilisearch -V')
	if res.exit_code != 0 {
		return false
	}
	r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	if r.len != 1 {
		return error("couldn't parse meilisearch version.\n${res.output}")
	}
	r2 := r[0].all_after('meilisearch').trim(' ')
	if texttools.version(version) != texttools.version(r2) {
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
	cfg := get()!
	console.print_header('install meilisearch')
	// Check if meilisearch is installed
	mut res := os.execute('meilisearch --version')
	if res.exit_code == 0 {
		console.print_header('meilisearch is already installed')
		return
	}

	// Check if curl is installed
	res = os.execute('curl --version')
	if res.exit_code == 0 {
		console.print_header('curl is already installed')
	} else {
		osal.package_install('curl') or {
			return error('Could not install curl, its required to install meilisearch.\nerror:\n${err}')
		}
	}

	if os.exists('${cfg.path}') {
		os.rmdir_all('${cfg.path}') or {
			return error('Could not remove directory ${cfg.path}.\nerror:\n${err}')
		}
	}

	os.mkdir('${cfg.path}') or {
		return error('Could not create directory ${cfg.path}.\nerror:\n${err}')
	}

	mut cmd := 'cd ${cfg.path} && curl -L https://install.meilisearch.com | sh'
	osal.execute_stdout(cmd)!

	cmd = 'mv /tmp/meilisearch/meilisearch /usr/local/bin/meilisearch'
	osal.execute_stdout(cmd)!

	console.print_header('meilisearch is installed')
}

fn build() ! {}

fn destroy() ! {
	console.print_header('destroy meilisearch')
	mut cfg := get()!
	if os.exists('${cfg.path}') {
		console.print_header('removing directory ${cfg.path}')
		os.rmdir_all('${cfg.path}') or {
			return error('Could not remove directory ${cfg.path}.\nerror:\n${err}')
		}
	}

	res := os.execute('meilisearch --version')
	if res.exit_code == 0 {
		console.print_header('removing meilisearch binary')
		osal.execute_silent('sudo rm -rf /usr/local/bin/meilisearch')!
	}

	mut zinit_factory := zinit.new()!
	if zinit_factory.exists('meilisearch') {
		zinit_factory.stop('meilisearch') or {
			return error('Could not stop meilisearch service due to: ${err}')
		}
		zinit_factory.delete('meilisearch') or {
			return error('Could not delete meilisearch service due to: ${err}')
		}
	}

	console.print_header('meilisearch is destroyed')
}
