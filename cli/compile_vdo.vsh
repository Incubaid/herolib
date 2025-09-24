#!/usr/bin/env -S v -n -cg -w -parallel-cc -enable-globals run

// #!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run
import os
import flag

mut fp := flag.new_flag_parser(os.args)
fp.application('compile_vdo.vsh')
fp.version('v0.1.0')
fp.description('Compile vdo binary in debug or production mode')
fp.skip_executable()

prod_mode := fp.bool('prod', `p`, false, 'Build production version (optimized)')
help_requested := fp.bool('help', `h`, false, 'Show help message')

if help_requested {
	println(fp.usage())
	exit(0)
}

additional_args := fp.finalize() or {
	eprintln(err)
	println(fp.usage())
	exit(1)
}

if additional_args.len > 0 {
	eprintln('Unexpected arguments: ${additional_args.join(' ')}')
	println(fp.usage())
	exit(1)
}

// Change to the vdo directory
hero_dir := os.join_path(os.home_dir(), 'code/github/freeflowuniverse/herolib/cli')
os.chdir(hero_dir) or { panic('Failed to change directory to ${hero_dir}: ${err}') }

// Set HEROPATH based on OS
mut heropath := '/usr/local/bin/vdo'
if os.user_os() == 'macos' {
	heropath = os.join_path(os.home_dir(), 'hero/bin/vdo')
}

// Set compilation command based on OS and mode
compile_cmd := if os.user_os() == 'macos' {
	if prod_mode {
		'v -enable-globals -w -n -prod vdo.v'
	} else {
		'v -w -cg -gc none  -cc tcc -d use_openssl -enable-globals vdo.v'
	}
} else {
	if prod_mode {
		'v -cg -enable-globals -parallel-cc -w -n vdo.v'
	} else {
		'v -cg -enable-globals -w -n vdo.v'
	}
}

println('Building in ${if prod_mode { 'production' } else { 'debug' }} mode...')

if os.system(compile_cmd) != 0 {
	panic('Failed to compile vdo.v with command: ${compile_cmd}')
}

// Make executable
os.chmod('vdo', 0o755) or { panic('Failed to make vdo binary executable: ${err}') }

// Ensure destination directory exists
os.mkdir_all(os.dir(heropath)) or {
	panic('Failed to create directory ${os.dir(heropath)}: ${err}')
}
println(heropath)
// Copy to destination paths
os.cp('vdo', heropath) or { panic('Failed to copy vdo binary to ${heropath}: ${err}') }
os.cp('vdo', '/tmp/vdo') or { panic('Failed to copy vdo binary to /tmp/vdo: ${err}') }

// Clean up
os.rm('vdo') or { panic('Failed to remove temporary vdo binary: ${err}') }

println('**COMPILE OK**')
