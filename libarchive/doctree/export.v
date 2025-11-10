module doctree

import incubaid.herolib.core.pathlib
import incubaid.herolib.data.doctree.collection { Collection }
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools.regext
import os

@[params]
pub struct TreeExportArgs {
pub mut:
	destination    string
	reset          bool = true
	keep_structure bool // wether the structure of the src collection will be preserved or not
	exclude_errors bool // wether error reporting should be exported as well
	toreplace      string
	concurrent     bool = true
	redis          bool = true
}

// export all collections to chosen directory .
// all names will be in name_fixed mode .
// all images in img/
pub fn (mut tree Tree) export(args_ TreeExportArgs) ! {
	mut args := args_
	if args.toreplace.len > 0 {
		mut ri := regext.regex_instructions_new()
		ri.add_from_text(args.toreplace)!
		tree.replacer = ri
	}

	if args.destination.len == 0 {
		args.destination = '${os.home_dir()}/hero/var/doctree/main'
	}
	console.print_header('export tree: name:${tree.name} to ${args.destination}')

	mut dest_path := pathlib.get_dir(path: args.destination, create: true)!
	if args.reset {
		dest_path.empty()!
	}

	tree.process_defs()!
	tree.process_includes()!
	tree.process_actions_and_macros()! // process other actions and macros

	file_paths := tree.generate_paths()!

	console.print_green('exporting collections')

	if args.concurrent {
		mut ths := []thread !{}
		for _, mut col in tree.collections {
			ths << spawn fn (mut col Collection, dest_path pathlib.Path, file_paths map[string]string, args TreeExportArgs) ! {
				col.export(
					destination:    dest_path
					file_paths:     file_paths
					reset:          args.reset
					keep_structure: args.keep_structure
					exclude_errors: args.exclude_errors
					redis:          args.redis
					// TODO: replacer: tree.replacer
				)!
			}(mut col, dest_path, file_paths, args)
		}
		for th in ths {
			th.wait() or { panic(err) }
		}
	} else {
		for _, mut col in tree.collections {
			col.export(
				destination:    dest_path
				file_paths:     file_paths
				reset:          args.reset
				keep_structure: args.keep_structure
				exclude_errors: args.exclude_errors
				replacer:       tree.replacer
				redis:          args.redis
			)!
		}
	}
}

fn (mut t Tree) generate_paths() !map[string]string {
	mut paths := map[string]string{}
	for _, col in t.collections {
		for _, page in col.pages {
			paths['${col.name}:${page.name}.md'] = '${col.name}/${page.name}.md'
		}

		for _, image in col.images {
			paths['${col.name}:${image.file_name()}'] = '${col.name}/img/${image.file_name()}'
		}

		for _, file in col.files {
			paths['${col.name}:${file.file_name()}'] = '${col.name}/img/${file.file_name()}'
		}
	}

	return paths
}
