module playbook

import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.data.paramsparser
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.develop.gittools // Added import for gittools

enum State {
	start
	comment_for_action_maybe
	action
	othertext
}

// pub struct PlayBookNewArgs {
// 	path       string
// 	text       string
// 	git_url    string
// 	git_pull   bool
// 	git_branch string
// 	git_reset  bool
// 	prio       int = 50
// 	priorities map[int]string // filter and give priority, see filtersort method to know how to use
// replace    map[string]string
// }
pub fn (mut plbook PlayBook) add(args_ PlayBookNewArgs) ! {
	mut args := args_

	if args.git_url.len > 0 {
		mut git_path_args := gittools.GitPathGetArgs{
			git_url:   args.git_url
			git_pull:  args.git_pull
			git_reset: args.git_reset
		}
		newpath := gittools.path(git_path_args)!
		args.path = newpath.path
	}

	if plbook.path == '' && args.path != '' {
		plbook.path = args.path
	}

	if args.text.len > 0 && args.replace.len > 0 {
		// now we need to replace any placeholders in the text
		for key, value in args.replace {
			if key.starts_with('@') || key.starts_with('$') || key.starts_with('[')
				|| key.starts_with('{') {
				args.text = args.text.replace(key, value)
			} else {
				args.text = args.text.replace('@${key}', value)
				args.text = args.text.replace('$\{${key}\}', value)
				args.text = args.text.replace('\{${key}\}', value)
			}
		}
	}

	// walk over directory
	if args.path.len > 0 {
		// console.print_header("PLBOOK add path:'${args.path}'")
		mut p := pathlib.get(args.path)
		if !p.exists() {
			return error("can't find path:${p.path}")
		}
		if p.is_file() {
			c := p.read()!
			plbook.add(text: c, prio: args.prio, replace: args.replace)!
			return
		} else if p.is_dir() {
			// get .md and .hero files from dir
			mut ol0 := p.list(recursive: true, regex: [r'.*\.md$'])!
			mut paths := ol0.paths.clone()
			mut ol1 := p.list(recursive: true, regex: [r'.*\.hero$'])!
			paths << ol1.paths
			mut ol2 := p.list(recursive: true, regex: [r'.*\.heroscript$'])!
			paths << ol2.paths
			for mut p2 in paths {
				c2 := p2.read()!
				plbook.add(text: c2, prio: args.prio, replace: args.replace)!
			}
			return
		}
		return error("can't process path: ${args.path}, unknown type.")
	}
	// console.print_header('PLBOOK add text')
	// console.print_stdout(args.text)

	args.text = texttools.dedent(args.text)
	mut state := State.start

	mut action := &Action{}
	mut comments := []string{}
	mut paramsdata := []string{}

	for line_ in args.text.split_into_lines() {
		line := line_.replace('\t', '    ')
		line_strip := line.trim_space()

		if line_strip.len == 0 {
			continue
		}

		// console.print_header(' state:${state} action:'${action.name}' comments:'${comments.len}' -> '${line}'")

		if state == .action {
			if !line.starts_with('  ') || line_strip == '' || line_strip.starts_with('!') {
				state = .start
				// means we found end of action
				// console.print_debug("+++${paramsdata.join('\n')}+++")
				action.params = paramsparser.new(paramsdata.join('\n'))!
				action.params.delete('id')
				comments = []string{}
				paramsdata = []string{}
				action = &Action{}
				// console.print_header(' action end')
			} else {
				paramsdata << line
			}
		}

		if state == .comment_for_action_maybe {
			if line.starts_with('//') {
				comment_content := line_strip.trim_left('/ ')
				comments << comment_content
			} else {
				if line_strip.starts_with('!') {
					// we are at end of comment
					state = .start
				} else {
					state = .start
					plbook.othertext += comments.join('\n')
					if !plbook.othertext.ends_with('\n') {
						plbook.othertext += '\n'
					}
					comments = []string{}
				}
			}
		}

		if state == .start {
			if line_strip.starts_with('!') && !line_strip.starts_with('![') {
				// start with new action
				state = .action
				action = plbook.action_new(
					priority: args.prio
				)
				action.comments = comments.join('\n')
				comments = []string{}
				paramsdata = []string{}
				mut actionname := line_strip
				if line_strip.contains(' ') {
					actionname = line_strip.all_before(' ').trim_space()
					paramsdata << line_strip.all_after_first(' ').trim_space()
				}
				if actionname.starts_with('!!!!!') {
					return error('there is no action starting with 5 x !')
				} else if actionname.starts_with('!!!!') {
					action.actiontype = .wal
				} else if actionname.starts_with('!!!') {
					action.actiontype = .macro
				} else if actionname.starts_with('!!') {
					action.actiontype = .sal
				} else if actionname.starts_with('!') {
					action.actiontype = .dal
				} else {
					print_backtrace()
					panic('bug')
				}
				actionname = actionname.trim_left('!')
				splitted := actionname.split('.')
				if splitted.len == 1 {
					action.actor = 'core'
					action.name = texttools.name_fix(splitted[0])
				} else if splitted.len == 2 {
					action.actor = texttools.name_fix(splitted[0])
					action.name = texttools.name_fix(splitted[1])
				} else {
					print_backtrace()
					return error('for now we only support actions with 1 or 2 parts.\n${actionname}')
				}
				// console.print_header(' action new: ${action.actor}:${action.name} params:${paramsdata}')
				continue
			} else if line.starts_with('//') {
				state = .comment_for_action_maybe
				comment_content := line_strip.trim_left('/ ')
				comments << comment_content
				// } else {
				// plbook.othertext += '${line_strip}\n'
			}
		}
	}
	// process the last one
	if state == .action {
		if action.id != 0 {
			action.params = paramsparser.new(paramsdata.join('\n'))!
			action.params.delete('id')
		}
	}
	if state == .comment_for_action_maybe {
		plbook.othertext += comments.join('\n')
	}
	// if state == .start{
	// 	plbook.othertext+=line_strip
	// }	
}
