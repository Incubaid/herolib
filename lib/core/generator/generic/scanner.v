module generic

import os
import incubaid.herolib.core.pathlib
import incubaid.herolib.ui.console

pub struct ScannerArgs {
pub mut:
	path     string
	generate bool
}

// scan over a set of directories call the play where
pub fn scan(args_ ScannerArgs) ! {
	mut args := args_
	console.print_header('Scan for generation of code for path: ${args.path} (generate:${args.generate})')

	if args.path == '.' {
		args.path = os.getwd()
	}

	mut generateall := false
	if args.path == '' {
		args.path = '${os.home_dir()}/code/github/incubaid/herolib/lib'
		generateall = true
	}

	// now walk over all directories, find .heroscript
	mut pathroot := pathlib.get_dir(path: args.path, create: false)!
	mut plist := pathroot.list(
		recursive:      true
		ignore_default: false
		regex:          ['.heroscript']
	)!

	console.print_debug('Found ${plist.paths.len} directories with .heroscript file.')
	if args.generate {
		console.print_debug('Now generating code for all found .heroscript files.')
		for mut p in plist.paths {
			pparent := p.parent()!
			generate(path: pparent.path, force: true)!
		}
	}
	mut res := []ModuleMeta{}
	for mut p in plist.paths {
		pparent := p.parent()!
		mut t := args_get(pparent.path)!
		if t.active {
			res << t
		} else {
			console.print_debug('Skipping generation for ${t.name} as active is false.')
		}
	}
	if generateall {
		console.print_debug('Found ${res.len} generator args.')
		generate_play_all(res)!
	}
}
