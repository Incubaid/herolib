#!/usr/bin/env -S v -n -g -cg -w -parallel-cc -showcc -enable-globals run

// #!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run
import os
import flag

mut fp := flag.new_flag_parser(os.args)
fp.application('compile.vsh')
fp.version('v0.1.0')
fp.description('Compile hero binary in debug or production mode')
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

// Determine the hero directory dynamically
// Get the directory where this script is located
script_dir := os.dir(os.executable())
// The script is in cli/, so the herolib root is one level up
herolib_root := os.dir(script_dir)
hero_dir := os.join_path(herolib_root, 'cli')

// Verify the directory exists and contains hero.v
if !os.exists(hero_dir) {
	panic('Hero CLI directory not found: ${hero_dir}')
}
hero_v_path := os.join_path(hero_dir, 'hero.v')
if !os.exists(hero_v_path) {
	panic('hero.v not found in: ${hero_dir}')
}

println('Using hero directory: ${hero_dir}')
os.chdir(hero_dir) or { panic('Failed to change directory to ${hero_dir}: ${err}') }

// Set HEROPATH based on OS
mut heropath := '/usr/local/bin/hero'
if os.user_os() == 'macos' {
	heropath = os.join_path(os.home_dir(), 'hero/bin/hero')
}

// Set compilation command based on OS and mode
compile_cmd := if os.user_os() == 'macos' {
	if prod_mode {
		'v -enable-globals -g -w -n -prod hero.v'
	} else {
		'v  -n -g -w -cg -gc none -cc tcc -d use_openssl -enable-globals hero.v'
		// 'v  -n -g -w -cg -gc none -cc tcc -d use_openssl -enable-globals hero.v'		
		// 'v -cg -enable-globals -parallel-cc -w -n -d use_openssl hero.v'
	}
} else {
	if prod_mode {
		'v -cg -enable-globals -parallel-cc -w -n -d use_openssl hero.v'
	} else {
		'v -cg -enable-globals -w -n -d use_openssl hero.v'
	}
}

println('Building in ${if prod_mode { 'production' } else { 'debug' }} mode...')
eprintln(compile_cmd)

if os.system(compile_cmd) != 0 {
	panic('Failed to compile hero.v with command: ${compile_cmd}')
}

// Make executable
os.chmod('hero', 0o755) or { panic('Failed to make hero binary executable: ${err}') }

// Ensure destination directory exists
os.mkdir_all(os.dir(heropath)) or {
	panic('Failed to create directory ${os.dir(heropath)}: ${err}')
}
println(heropath)
// Copy to destination paths
os.cp('hero', heropath) or { panic('Failed to copy hero binary to ${heropath}: ${err}') }
os.cp('hero', '/tmp/hero') or { panic('Failed to copy hero binary to /tmp/hero: ${err}') }

// Clean up
os.rm('hero') or { panic('Failed to remove temporary hero binary: ${err}') }

println('**COMPILE OK**')
