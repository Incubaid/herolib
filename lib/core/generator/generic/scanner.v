module generic

import os
import incubaid.herolib.core.pathlib
import incubaid.herolib.ui.console

// scan over a set of directories call the play where
pub fn scan(args_ GeneratorArgs) ! {
	mut args := args_
	console.print_header('Scan for generation of code for path: ${args.path} (reset:${args.force}, force:${args.force})')

	if args.path.len == 0 {
		args.path = os.getwd()
	}

	// now walk over all directories, find .heroscript
	mut pathroot := pathlib.get_dir(path: args.path, create: false)!
	mut plist := pathroot.list(
		recursive:      true
		ignore_default: false
		regex:          ['.heroscript']
	)!

	console.print_debug('Found ${plist.paths.len} directories with .heroscript file.')
	for mut p in plist.paths {
		pparent := p.parent()!
		args.force = true
		args.path = pparent.path
		generate(args)!
	}
	mut res := []GeneratorArgs{}
	for mut p in plist.paths {
		pparent := p.parent()!
		res << args_get(pparent.path)!
	}
	console.print_debug('Found ${res.len} generator args.')
	println(res)
	$dbg;
}
