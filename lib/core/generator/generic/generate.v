module generic

import incubaid.herolib.ui.console
import os
import incubaid.herolib.core.pathlib

pub struct GenerateArgs {
pub mut:
	path  string
	reset bool
	force bool
	name  string
}

// will ask questions when not in force mode
// & generate the module
pub fn generate(args_ GenerateArgs) ! {
	mut myconsole := console.new()
	mut args := args_

	console.print_header('Generate code for path: ${args.path} (reset:${args.reset}, force:${args.force})')

	if args.path == '' {
		return error('no path provided')
	}

	if args.name == '' {
		args.name = os.base(args.path)
	}

	if args.force {
		mut config_path0 := pathlib.get_file(path: '${args.path}/.heroscript', create: false)!
		if !config_path0.exists() {
			return error("can't generate in force mode (non interactive) if ${config_path0.path} not found.")
		}
		generate_exec(args.path, args.reset)!
		return
	}

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
				generate_exec(args.path, args.reset)!
			} else {
				console.print_stderr('Generation aborted.')
			}
			return
		}
	}

	if pathok == false {
		yesno := myconsole.ask_yesno(description: 'Is this path ok?')!
		if !yesno {
			return error("can't continue without a valid path")
		}
	}

	mycat := myconsole.ask_dropdown(
		description: 'Category of the generator'
		question:    'What is the category of the generator?'
		items:       [
			'installer',
			'client',
		]
		warning:     'Please select a category'
	)!

	mut meta := ModuleMeta{}

	if mycat == 'installer' {
		meta.cat = .installer
	} else {
		meta.cat = .client
	}

	// if args.name==""{
	// 	yesno := myconsole.ask_yesno(description: 'Are you happy with name ${args.name}?')!
	// 	if !yesno {
	// 		return error("can't continue without a valid name, rename the directory you operate in.")
	// 	}
	// }

	meta.classname = myconsole.ask_question(
		description: 'Class name of the ${mycat}'
		question:    'What is the class name of the generator e.g. MyClass ?'
		warning:     'Please provide a valid class name for the generator'
		minlen:      4
	)!

	meta.title = myconsole.ask_question(
		description: 'Title of the ${mycat} (optional)'
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

	// args.supported_platforms = myconsole.ask_dropdown_multiple(
	// 	description: 'Supported platforms'
	// 	question:    'Which platforms are supported?'
	// 	items:       [
	// 		'osx',
	// 		'ubuntu',
	// 		'arch',
	// 	]
	// 	warning: 'Please select one or more platforms'
	// )!

	if meta.cat == .installer {
		meta.templates = myconsole.ask_yesno(
			description: 'Will there be templates available for your installer?'
		)!

		meta.startupmanager = myconsole.ask_yesno(
			description: 'Is this an installer which will be managed by a startup mananger?'
		)!

		meta.build = myconsole.ask_yesno(
			description: 'Are there builders for the installers (compilation)'
		)!
	}
	meta.path = args.path
	println(meta)
	create_heroscript(meta)!
	generate_exec(args.path, true)!
}

pub fn create_heroscript(args ModuleMeta) ! {
	mut script := ''
	if args.path == '' {
		return error('no path provided to create heroscript')
	}
	if args.cat == .installer {
		script = "
!!hero_code.generate_installer
    name:'${args.name}'
    classname:'${args.classname}'
    singleton:${if args.singleton {
			'1'
		} else {
			'0'
		}}
    templates:${if args.templates { '1' } else { '0' }}
    default:${if args.default {
			'1'
		} else {
			'0'
		}}
    title:'${args.title}'
    supported_platforms:''
    startupmanager:${if args.startupmanager {
			'1'
		} else {
			'0'
		}}
	hasconfig:${if args.hasconfig {
			'1'
		} else {
			'0'
		}}
    build:${if args.build {
			'1'
		} else {
			'0'
		}}"
	} else {
		script = "
!!hero_code.generate_client
    name:'${args.name}'
    classname:'${args.classname}'
    singleton:${if args.singleton {
			'1'
		} else {
			'0'
		}}
    default:${if args.default { '1' } else { '0' }}
	hasconfig:${if args.hasconfig {
			'1'
		} else {
			'0'
		}}"
	}
	if !os.exists(args.path) {
		os.mkdir(args.path)!
	}
	os.write_file('${args.path}/.heroscript', script)!
}
