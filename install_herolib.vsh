#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import os
import flag

fn addtoscript(tofind string, toadd string) ! {
	home_dir := os.home_dir()
	mut rc_file := '${home_dir}/.zprofile'
	if !os.exists(rc_file) {
		rc_file = '${home_dir}/.bashrc'
		if !os.exists(rc_file) {
			return error('No .zprofile or .bashrc found in home directory')
		}
	}

	// Read current content
	mut content := os.read_file(rc_file)!

	// Remove existing alias if present
	lines := content.split('\n')
	mut new_lines := []string{}
	mut prev_is_emtpy := false
	for line in lines {
		if prev_is_emtpy {
			if line.trim_space() == '' {
				continue
			} else {
				prev_is_emtpy = false
			}
		}
		if line.trim_space() == '' {
			prev_is_emtpy = true
		}

		if !line.contains(tofind) {
			new_lines << line
		}
	}
	new_lines << toadd
	new_lines << ''
	// Write back to file
	new_content := new_lines.join('\n')
	os.write_file(rc_file, new_content)!
}

vroot := @VROOT
abs_dir_of_script := dir(@FILE)

// Reset symlinks if requested
println('Resetting all symlinks...')
os.rm('${os.home_dir()}/.vmodules/incubaid/herolib') or {}

// Create necessary directories
os.mkdir_all('${os.home_dir()}/.vmodules/freeflowuniverse') or {
	panic('Failed to create directory ~/.vmodules/freeflowuniverse: ${err}')
}

// Create new symlinks
os.symlink('${abs_dir_of_script}/lib', '${os.home_dir()}/.vmodules/incubaid/herolib') or {
	panic('Failed to create herolib symlink: ${err}')
}

println('Herolib installation completed successfully!')

// Add vtest alias
addtoscript('alias vtest=', "alias vtest='v -stats -enable-globals -show-c-output -n -w -cg -gc none  -cc tcc test' ") or {
	eprintln('Failed to add vtest alias: ${err}')
	exit(1)
}

// Add vrun alias
addtoscript('alias vrun=', "alias vrun='v -stats -enable-globals -show-c-output -n -w -cg -gc none  -cc tcc run' ") or {
	eprintln('Failed to add vrun alias: ${err}')
	exit(1)
}

addtoscript('HOME/hero/bin', 'export PATH="\$PATH:\$HOME/hero/bin"') or {
	eprintln('Failed to add path to hero, ${err}')
	exit(1)
}

//  ulimit -n 32000

println('Added vtest alias to shell configuration')
