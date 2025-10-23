module herocmds

import incubaid.herolib.ui.console
import incubaid.herolib.data.atlas
import incubaid.herolib.core.playcmds
import incubaid.herolib.develop.gittools
import os
import cli { Command, Flag }

pub fn cmd_atlas(mut cmdroot Command) Command {
	mut cmd_run := Command{
		name:          'atlas'
		description:   'Scan and export atlas collections.'
		required_args: 0
		execute:       cmd_atlas_execute
	}

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'reset'
		abbrev:      'r'
		description: 'Reset and clean before operations.'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'url'
		abbrev:      'u'
		description: 'Git URL where atlas source is.'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'path'
		abbrev:      'p'
		description: 'Path where atlas collections are located.'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'path_meta'
		abbrev:      'pm'
		description: 'Path where collection.json... will be saved too.'
	})


	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'name'
		abbrev:      'n'
		description: 'Atlas instance name (default: "default").'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'destination'
		abbrev:      'd'
		description: 'Export destination path.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'scan'
		abbrev:      's'
		description: 'Scan directories for collections.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'export'
		abbrev:      'e'
		description: 'Export collections to destination.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'no-include'
		description: 'Skip processing !!include actions during export.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'no-redis'
		description: 'Skip storing metadata in Redis during export.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'update'
		description: 'Update environment and git pull before operations.'
	})

	cmdroot.add_command(cmd_run)
	return cmdroot
}

fn cmd_atlas_execute(cmd Command) ! {
	// ---------- FLAGS ----------
	mut reset := cmd.flags.get_bool('reset') or { false }
	mut update := cmd.flags.get_bool('update') or { false }
	mut scan := cmd.flags.get_bool('scan') or { false }
	mut export := cmd.flags.get_bool('export') or { false }
	
	// Include and redis default to true unless explicitly disabled
	mut no_include := cmd.flags.get_bool('no-include') or { false }
	mut no_redis := cmd.flags.get_bool('no-redis') or { false }
	mut include := !no_include
	mut redis := !no_redis

	// ---------- PATH LOGIC ----------
	mut path := cmd.flags.get_string('path') or { '' }
	mut path_meta := cmd.flags.get_string('path_meta') or { '' }
	mut url := cmd.flags.get_string('url') or { '' }
	mut name := cmd.flags.get_string('name') or { 'default' }
	mut destination := cmd.flags.get_string('destination') or { '' }

	if path == '' && url == '' {
		path = os.getwd()
	}

	atlas_path := gittools.path(
		git_url:   url
		path:      path
		git_reset: reset
		git_pull:  update
	)!

	console.print_header('Running Atlas for: ${atlas_path.path}')

	// Run HeroScript if exists
	playcmds.run(
		heroscript_path: atlas_path.path
		reset:           false
	)!

	// Create or get atlas instance
	mut a := if atlas.atlas_exists(name) {
		atlas.atlas_get(name)!
	} else {
		atlas.new(name: name)!
	}

	// Default behavior: scan and export if no flags specified
	if !scan && !export {
		scan = true
		export = true
	}

	// Execute operations
	if scan {
		console.print_header('Scanning collections...')
		a.scan(path: atlas_path.path, meta_path: path_meta)!
		console.print_green('✓ Scan complete: ${a.collections.len} collection(s) found')
	}

	if export {
		if destination == '' {
			destination = '${atlas_path.path}/output'
		}
		
		console.print_header('Exporting collections to: ${destination}')
		console.print_item('Include processing: ${include}')
		console.print_item('Redis metadata: ${redis}')
		
		a.export(
			destination: destination
			reset:       reset
			include:     include
			redis:       redis
		)!
		
		console.print_green('✓ Export complete to ${destination}')
		
		// Print any errors encountered during export
		for _, col in a.collections {
			if col.has_errors() {
				col.print_errors()
			}
		}
	}
}