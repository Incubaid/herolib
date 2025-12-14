module hero_generator

import os
import incubaid.herolib.core.pathlib
import incubaid.herolib.ui.console
import incubaid.herolib.osal.core as osal

pub struct ScannerArgs {
pub mut:
	path string
}

// ScanResult holds the result of scanning for .heroscript files
pub struct ScanResult {
pub:
	modules      []ModuleMeta
	generate_all bool // true if scanning from herolib root
}

// scan_modules finds all .heroscript files and returns their metadata
// The caller is responsible for routing to the appropriate generators
pub fn scan_modules(args_ ScannerArgs) !ScanResult {
	mut args := args_
	console.print_header('Scan for .heroscript files in: ${args.path}')

	if args.path == '.' {
		args.path = os.getwd()
	}

	mut generate_all := false
	if args.path == '' {
		args.path = '${os.home_dir()}/code/github/incubaid/herolib/lib'
		generate_all = true
	}

	// Walk over all directories, find .heroscript
	mut pathroot := pathlib.get_dir(path: args.path, create: false)!
	mut plist := pathroot.list(
		recursive:      true
		ignore_default: false
		regex:          ['.heroscript']
	)!

	console.print_debug('Found ${plist.paths.len} directories with .heroscript file.')

	mut res := []ModuleMeta{}
	for mut p in plist.paths {
		pparent := p.parent()!
		// Skip libwip directories - they are work-in-progress and not part of the main lib
		if pparent.path.contains('/libwip/') {
			console.print_debug('Skipping ${pparent.path} (in libwip/)')
			continue
		}
		mut t := args_get(pparent.path)!
		if t.active {
			res << t
		} else {
			console.print_debug('Skipping ${t.name} (active=false)')
		}
	}

	return ScanResult{
		modules:      res
		generate_all: generate_all
	}
}

// register_in_factory adds a module's import and play() call to factory.v
// This is called when generating a new module so it's automatically registered
pub fn register_in_factory(meta ModuleMeta) ! {
	factory_path := get_factory_path(meta.path) or {
		console.print_debug('Could not determine factory.v path, skipping registration')
		return
	}

	mut content := os.read_file(factory_path) or {
		return error('Failed to read factory.v: ${err}')
	}

	import_line := 'import ${meta.module_path}'
	module_short_name := meta.module_path.split('.').last()
	play_call := '${module_short_name}.play(mut plbook)!'

	// Skip if already registered (check both import and play call)
	if content.contains(import_line) && content.contains(play_call) {
		console.print_debug('Module ${meta.module_path} already registered in factory.v')
		return
	}

	mut lines := content.split('\n')
	mut modified := false

	// Add import after the last import line (if not already present)
	if !content.contains(import_line) {
		last_import_idx := find_last_import_line(lines)
		lines.insert(last_import_idx + 1, import_line)
		modified = true
	}

	// Add play call before the emptycheck block (if not already present)
	if !content.contains(play_call) {
		play_insert_idx := find_line_containing(lines, 'if args.emptycheck {')
		if play_insert_idx > 0 {
			lines.insert(play_insert_idx, '\t' + play_call)
			modified = true
		}
	}

	if !modified {
		console.print_debug('No changes needed for ${meta.name} in factory.v')
		return
	}

	os.write_file(factory_path, lines.join('\n')) or {
		return error('Failed to write factory.v: ${err}')
	}

	console.print_debug('Formatting factory.v')
	osal.execute_silent('v fmt -w ${factory_path}')!
	console.print_green('Registered ${meta.name} in factory.v')
}

// get_factory_path derives factory.v path from a module path within herolib
fn get_factory_path(module_path string) ?string {
	// Find herolib root by looking for 'incubaid/herolib' in the path
	if idx := module_path.index('incubaid/herolib') {
		herolib_root := module_path[..idx + 'incubaid/herolib'.len]
		return '${herolib_root}/lib/core/playcmds/factory.v'
	}
	return none
}

// find_last_import_line returns the index of the last import statement
fn find_last_import_line(lines []string) int {
	mut last_idx := 0
	for i, line in lines {
		if line.trim_space().starts_with('import ') {
			last_idx = i
		}
	}
	return last_idx
}

// find_line_containing returns the index of the first line containing the pattern
fn find_line_containing(lines []string, pattern string) int {
	for i, line in lines {
		if line.contains(pattern) {
			return i
		}
	}
	return 0
}
