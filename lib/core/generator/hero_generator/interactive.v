module hero_generator

import incubaid.herolib.ui.console
import incubaid.herolib.core.pathlib

// InteractiveResult holds the result of interactive prompts
pub struct InteractiveResult {
pub:
	meta         ModuleMeta
	run_it       bool // true if user wants to run generation
	use_existing bool // true if using existing .heroscript
}

// prompt_interactive runs the interactive prompt-based generator
// Returns the meta and whether the user wants to proceed
pub fn prompt_interactive(args_ GenerateArgs) !InteractiveResult {
	mut myconsole := console.new()
	mut args := args_

	console.clear()
	console.print_header('Configure generation of code for a module on path:')
	console.print_green('Path: ${args.path}')
	console.lf()

	mut config_path := pathlib.get_file(path: '${args.path}/.heroscript', create: false)!
	mut pathok := false
	if config_path.exists() {
		console.print_stdout(config_path.read()!)
		console.lf()
		myyes := myconsole.ask_yesno(
			description: 'We found this heroscript, do you want to make a new one?'
		)!
		if myyes {
			config_path.delete()!
			pathok = true
		} else {
			myyes2 := myconsole.ask_yesno(description: 'Do you want to run it?')!
			if myyes2 {
				// User wants to run existing heroscript
				meta := args_get(args.path)!
				return InteractiveResult{
					meta:         meta
					run_it:       true
					use_existing: true
				}
			} else {
				console.print_stderr('Generation aborted.')
				return InteractiveResult{
					run_it: false
				}
			}
		}
	}

	if pathok == false {
		yesno := myconsole.ask_yesno(description: 'Is this path ok?')!
		if !yesno {
			return error("can't continue without a valid path")
		}
	}

	mut meta := ModuleMeta{}

	// Use category from CLI if specified
	meta.cat = args.cat
	cat_name := match meta.cat {
		.installer { 'installer' }
		.client { 'client' }
		.k8sapp { 'k8sapp' }
	}

	meta.classname = myconsole.ask_question(
		description: 'Class name of the ${cat_name}'
		question:    'What is the class name of the generator e.g. MyClass ?'
		warning:     'Please provide a valid class name for the generator'
		minlen:      4
	)!

	meta.title = myconsole.ask_question(
		description: 'Title of the ${cat_name} (optional)'
	)!

	if meta.cat == .installer {
		meta.hasconfig = myconsole.ask_yesno(
			description: 'Does your installer have a config (normally yes)?'
		)!
	}

	if meta.hasconfig {
		meta.default = myconsole.ask_yesno(
			description: 'Is it ok when doing new() that a default is created (normally yes)?'
		)!
		meta.singleton = !myconsole.ask_yesno(
			description: 'Can there be multiple instances (normally yes)?'
		)!
	}

	if meta.cat == .installer {
		meta.templates = myconsole.ask_yesno(
			description: 'Will there be templates available for your installer?'
		)!

		meta.startupmanager = myconsole.ask_yesno(
			description: 'Is this an installer which will be managed by a startup manager?'
		)!

		meta.build = myconsole.ask_yesno(
			description: 'Are there builders for the installers (compilation)'
		)!
	}

	meta.path = args.path
	println(meta)
	create_heroscript(meta)!

	return InteractiveResult{
		meta:   meta
		run_it: true
	}
}
