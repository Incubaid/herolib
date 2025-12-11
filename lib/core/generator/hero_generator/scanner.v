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

// generate_play_all generates the play_all.v file with imports and play calls for all modules
pub fn generate_play_all(meta_items []ModuleMeta) ! {
	mut path := pathlib.get('${os.home_dir()}/code/github/incubaid/herolib/lib/core/playcmds/play_all.v')
	mut templ_1 := $tmpl('templates/play_all.vtemplate')
	pathlib.template_write(templ_1, path.path, true)!
	console.print_debug('formatting ${path.path}')
	osal.execute_silent('v fmt -w ${path.path}')!
}
