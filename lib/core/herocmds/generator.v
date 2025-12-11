module herocmds

import incubaid.herolib.core.generator.hero_generator
import incubaid.herolib.core.generator.hero_generator.installer
import incubaid.herolib.core.generator.hero_generator.client
import incubaid.herolib.core.generator.hero_generator.k8sapp
import incubaid.herolib.ui.console
import os
import cli { Command, Flag }

pub fn cmd_generator(mut cmdroot Command) {
	mut cmd_generate := Command{
		name:        'generate'
		description: 'Generator for V language code in hero context.\nUse subcommands: installer, client, k8sapp, scan'
		execute:     fn (cmd Command) ! {
			// Print help when no subcommand is provided
			println(cmd.help_message())
		}
	}

	// Add subcommands for each category
	cmd_generate.add_command(create_category_subcommand(.installer))
	cmd_generate.add_command(create_category_subcommand(.client))
	cmd_generate.add_command(create_category_subcommand(.k8sapp))

	// Add scan subcommand
	mut cmd_scan := Command{
		name:        'scan'
		description: 'Scan directories for .heroscript files and regenerate code.'
		execute:     cmd_scan_execute
	}
	cmd_scan.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'path'
		abbrev:      'p'
		description: 'Path to scan (default: current directory).'
	})
	cmd_scan.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'generate'
		abbrev:      'g'
		description: 'Generate code after scanning.'
	})
	cmd_generate.add_command(cmd_scan)

	cmdroot.add_command(cmd_generate)
}

// create_category_subcommand creates a subcommand for installer/client/k8sapp
fn create_category_subcommand(cat hero_generator.Cat) Command {
	cat_name := match cat {
		.installer { 'installer' }
		.client { 'client' }
		.k8sapp { 'k8sapp' }
	}

	mut cmd := Command{
		name:        cat_name
		description: 'Generate a ${cat_name} module.'
		execute:     fn [cat] (cmd Command) ! {
			cmd_category_execute(cmd, cat)!
		}
	}

	// Required flags
	cmd.add_flag(Flag{
		flag:        .string
		required:    true
		name:        'name'
		abbrev:      'n'
		description: 'Module name (e.g., my_installer). Auto-converted to class name (MyInstaller).'
	})

	cmd.add_flag(Flag{
		flag:        .string
		required:    true
		name:        'path'
		abbrev:      'p'
		description: 'Target directory path (must exist). Example: lib/installers/my_installer'
	})

	// Optional flags
	cmd.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'title'
		abbrev:      't'
		description: 'Title for the module (optional).'
	})

	cmd.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'singleton'
		description: 'Only one instance can exist (default: false).'
	})

	cmd.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'templates'
		description: 'Include template files (default: true for installers, false for clients).'
	})

	cmd.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'no-config'
		description: 'Module has no config struct (default: has config).'
	})

	cmd.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'no-default'
		description: 'Do not create default instance on new() (default: creates default).'
	})

	cmd.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'no-startupmanager'
		description: 'Disable startup manager (default: enabled for installers).'
	})

	cmd.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'build'
		abbrev:      'b'
		description: 'Include build/compilation support (default: false).'
	})

	cmd.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'reset'
		abbrev:      'r'
		description: 'Reset/overwrite existing files (default: false).'
	})

	cmd.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'interactive'
		abbrev:      'i'
		description: 'Use interactive mode with prompts (default: non-interactive).'
	})

	return cmd
}

// cmd_category_execute handles the execution of installer/client/k8sapp subcommands
fn cmd_category_execute(cmd Command, cat hero_generator.Cat) ! {
	interactive := cmd.flags.get_bool('interactive') or { false }
	reset := cmd.flags.get_bool('reset') or { false }

	// If interactive mode, use interactive prompts
	if interactive {
		path := resolve_path(cmd.flags.get_string('path') or { '' })!
		result := hero_generator.prompt_interactive(
			path: path
			cat:  cat
		)!
		if result.run_it {
			run_generator(result.meta, reset)!
		}
		return
	}

	// Non-interactive mode (default)
	name := cmd.flags.get_string('name') or { return error('-name flag is required') }
	path_raw := cmd.flags.get_string('path') or { return error('-path flag is required') }
	path := resolve_path(path_raw)!

	// Get optional flags
	title := cmd.flags.get_string('title') or { '' }
	singleton := cmd.flags.get_bool('singleton') or { false }
	templates := cmd.flags.get_bool('templates') or { cat == .installer }
	no_config := cmd.flags.get_bool('no-config') or { false }
	no_default := cmd.flags.get_bool('no-default') or { false }
	no_startupmanager := cmd.flags.get_bool('no-startupmanager') or { false }
	build := cmd.flags.get_bool('build') or { false }

	// Prepare meta and create .heroscript
	meta := hero_generator.prepare_meta(
		path:           path
		cat:            cat
		name:           name
		title:          title
		singleton:      singleton
		templates:      templates
		hasconfig:      !no_config
		default:        !no_default
		startupmanager: if cat == .client { false } else { !no_startupmanager }
		build:          build
	)!

	// Run the appropriate generator
	run_generator(meta, reset)!
	console.print_green('✓ Module generated successfully at ${path}')
}

// run_generator routes to the appropriate type-specific generator
fn run_generator(meta hero_generator.ModuleMeta, reset bool) ! {
	match meta.cat {
		.installer { installer.generate_exec(meta, reset)! }
		.client { client.generate_exec(meta, reset)! }
		.k8sapp { k8sapp.generate_exec(meta, reset)! }
	}
	// Register the module in factory.v so it can be used via heroscript
	hero_generator.register_in_factory(meta)!
}

// cmd_scan_execute handles the scan subcommand
fn cmd_scan_execute(cmd Command) ! {
	path_raw := cmd.flags.get_string('path') or { '.' }
	generate := cmd.flags.get_bool('generate') or { false }
	path := resolve_path(path_raw)!

	result := hero_generator.scan_modules(path: path)!

	if generate {
		console.print_debug('Generating code for ${result.modules.len} modules...')
		for meta in result.modules {
			run_generator(meta, false)!
		}
	}
}

// resolve_path normalizes and validates a path
fn resolve_path(path_raw string) !string {
	mut path := path_raw

	// Handle "." as current working directory
	if path == '.' || path == '' {
		path = os.getwd()
	} else {
		// Expand home directory
		path = path.replace('~', os.home_dir())

		// Convert relative paths to absolute paths
		if !os.is_abs_path(path) {
			path = os.join_path(os.getwd(), path)
		}

		// Resolve to real path (handles symlinks and normalizes path)
		path = os.real_path(path)
	}

	// Validate that path exists
	if !os.exists(path) {
		return error('Path does not exist: ${path}')
	}

	return path
}
