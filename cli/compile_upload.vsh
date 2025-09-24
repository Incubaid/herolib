#!/usr/bin/env -S v run

import os

fn get_platform_id() string {
	os_name := os.user_os()
	arch := os.uname().machine

	return match os_name {
		'linux' {
			match arch {
				'aarch64', 'arm64' { 'linux-arm64' }
				'x86_64' { 'linux-i64' }
				else { 'unknown' }
			}
		}
		'macos' {
			match arch {
				'arm64' { 'macos-arm64' }
				'x86_64' { 'macos-i64' }
				else { 'unknown' }
			}
		}
		else {
			'unknown'
		}
	}
}

fn read_secrets() ! {
	secret_file := os.join_path(os.home_dir(), 'code/git.threefold.info/despiegk/hero_secrets/mysecrets.sh')
	if os.exists(secret_file) {
		println('Reading secrets from ${secret_file}')
		content := os.read_file(secret_file)!
		lines := content.split('\n')
		for line in lines {
			if line.contains('export') {
				parts := line.replace('export ', '').split('=')
				if parts.len == 2 {
					key := parts[0].trim_space()
					value := parts[1].trim_space().trim('"').trim("'")
					os.setenv(key, value, true)
				}
			}
		}
	}
}

fn s3_configure() ! {
	read_secrets()!

	// Check if environment variables are set
	s3keyid := os.getenv_opt('S3KEYID') or { return error('S3KEYID is not set') }
	s3appid := os.getenv_opt('S3APPID') or { return error('S3APPID is not set') }

	// Create rclone config file
	rclone_dir := os.join_path(os.home_dir(), '.config/rclone')
	os.mkdir_all(rclone_dir) or { return error('Failed to create rclone directory: ${err}') }

	rclone_conf := os.join_path(rclone_dir, 'rclone.conf')
	config_content := '[b2]
type = b2
account = ${s3keyid}
key = ${s3appid}
hard_delete = true'

	os.write_file(rclone_conf, config_content) or {
		return error('Failed to write rclone config: ${err}')
	}

	println('made S3 config on: ${rclone_conf}')
	content := os.read_file(rclone_conf) or { return error('Failed to read rclone config: ${err}') }
	println(content)
}

fn hero_upload() ! {
	hero_path := os.find_abs_path_of_executable('hero') or {
		return error("Error: 'hero' command not found in PATH")
	}

	s3_configure()!

	platform_id := get_platform_id()
	rclone_conf := os.join_path(os.home_dir(), '.config/rclone/rclone.conf')

	println('Uploading hero binary for platform: ${platform_id}')

	// List contents
	os.execute_or_panic('rclone --config="${rclone_conf}" lsl b2:threefold/${platform_id}/')

	// Copy hero binary
	os.execute_or_panic('rclone --config="${rclone_conf}" copy "${hero_path}" b2:threefold/${platform_id}/')
}

fn main() {
	// os.execute_or_panic('${os.home_dir()}/code/github/freeflowuniverse/herolib/cli/compile.vsh -p')
	println('compile hero can take 60 sec+ on osx.')
	os.execute_or_panic('${os.home_dir()}/code/github/freeflowuniverse/herolib/cli/compile.vsh -p')
	println('upload:')
	hero_upload() or {
		eprintln(err)
		exit(1)
	}
}
