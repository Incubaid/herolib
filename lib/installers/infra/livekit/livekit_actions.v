module livekit

import incubaid.herolib.osal.core as osal
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.installers.ulist
import net.http
import json
import os
import regex
import time

fn generate_keys() ! {
	mut obj := get()!
	result := os.execute('livekit-server generate-keys')

	if result.exit_code != 0 {
		return error('Failed to generate LiveKit keys')
	}

	// Regex pattern to extract API Key and API Secret
	api_pattern := r'API Key:\s*([\w\d]+)'
	secret_pattern := r'API Secret:\s*([\w\d]+)'

	mut api_regex := regex.regex_opt(api_pattern) or { return error('Invalid regex for API Key') }
	mut secret_regex := regex.regex_opt(secret_pattern) or {
		return error('Invalid regex for API Secret')
	}

	mut api_key := ''
	mut api_secret := ''

	mut start, mut end := api_regex.find(result.output)
	api_key = result.output.substr(start, end).all_after(':').trim_space()

	start, end = secret_regex.find(result.output)
	api_secret = result.output.substr(start, end).all_after(':').trim_space()

	if api_key == '' || api_secret == '' {
		return error('Failed to extract API Key or API Secret')
	}

	obj.apikey = api_key
	obj.apisecret = api_secret
}

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}
	mut installer := get()!
	res << startupmanager.ZProcessNewArgs{
		name:        'livekit'
		cmd:         'livekit-server --config ${installer.configpath} --bind 0.0.0.0'
		startuptype: .zinit
	}

	return res
}

fn running() !bool {
	console.print_header('checking if livekit server is running')
	mut installer := get()!

	myport := installer.nr * 2 + 7880
	endpoint := 'http://0.0.0.0:${myport}/'
	time.sleep(time.second * 2)

	response := http.get(endpoint) or {
		console.print_stderr('Error connecting to LiveKit server: ${err}')
		return false
	}

	if response.status_code != 200 {
		console.print_stderr('LiveKit server returned non-200 status code: ${response.status_code}')
		return false
	}

	if response.body.to_lower() != 'ok' {
		console.print_stderr('LiveKit server health check failed}')
		return false
	}

	console.print_header('the livekit server is running')
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

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()!} livekit-server -v')
	if res.exit_code != 0 {
		return false
	}

	r := res.output.split_into_lines().filter(it.contains('version'))
	if r.len != 1 {
		return error("couldn't parse livekit version.\n${res.output}")
	}

	installedversion := r[0].all_after_first('version')
	if texttools.version(version) != texttools.version(installedversion) {
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
	console.print_header('install livekit')
	osal.execute_silent('curl -sSL https://get.livekit.io | bash')!
	console.print_header('livekit is installed')
	console.print_header('generating livekit keys')
	generate_keys()!
	console.print_header('livekit keys are generated')
}

fn destroy() ! {
	console.print_header('removing livekit')
	osal.process_kill_recursive(name: 'livekit') or {
		return error('Could not kill livekit due to: ${err}')
	}
	res := os.execute('sudo rm -rf /usr/local/bin/livekit-server')
	if res.exit_code != 0 {
		return error('Failed to remove LiveKit server')
	}

	console.print_header('livekit removed')
}
