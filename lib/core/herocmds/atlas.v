module herocmds

import incubaid.herolib.ui.console
import incubaid.herolib.core.playcmds
import incubaid.herolib.develop.gittools
import incubaid.herolib.web.docusaurus
import os
import cli { Command, Flag }

pub fn cmd_doctree(mut cmdroot Command) Command {
	mut cmd_run := Command{
		name:          'doctree'
		description:   'Scan and export doctree collections.'
		required_args: 0
		execute:       cmd_doctree_execute
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
		description: 'Git URL where doctree source is.'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'path'
		abbrev:      'p'
		description: 'Path where doctree collections are located.'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'name'
		abbrev:      'n'
		description: 'DocTree instance name (default: "default").'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'destination'
		description: 'Export destination path.'
		abbrev:      'd'
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

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'dev'
		description: 'Run development server after export (requires docusaurus config).'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'open'
		abbrev:      'o'
		description: 'Open browser when running dev server (use with --dev).'
	})

	cmdroot.add_command(cmd_run)
	return cmdroot
}

fn cmd_doctree_execute(cmd Command) ! {
	// ---------- FLAGS ----------
	mut reset := cmd.flags.get_bool('reset') or { false }
	mut update := cmd.flags.get_bool('update') or { false }
	mut scan := cmd.flags.get_bool('scan') or { false }
	mut export := cmd.flags.get_bool('export') or { false }
	mut dev := cmd.flags.get_bool('dev') or { false }
	mut open_ := cmd.flags.get_bool('open') or { false }

	// Include and redis default to true unless explicitly disabled
	mut no_include := cmd.flags.get_bool('no-include') or { false }
	mut no_redis := cmd.flags.get_bool('no-redis') or { false }
	mut include := !no_include
	mut redis := !no_redis

	// ---------- PATH LOGIC ----------
	mut path := cmd.flags.get_string('path') or { '' }
	mut url := cmd.flags.get_string('url') or { '' }
	mut name := cmd.flags.get_string('name') or { 'default' }

	mut destination := cmd.flags.get_string('destination') or { '' }

	if path == '' && url == '' {
		path = os.getwd()
	}

	doctree_path := gittools.path(
		git_url:   url
		path:      path
		git_reset: reset
		git_pull:  update
	)!

	console.print_header('Running DocTree for: ${doctree_path.path}')

	// Run HeroScript if exists
	playcmds.run(
		heroscript_path: doctree_path.path
		reset:           reset
		emptycheck:      false
	)!

	// Create or get doctree instance
	mut a := if doctree.exists(name) {
		doctree.get(name)!
	} else {
		doctree.new(name: name)!
	}

	// Default behavior: scan and export if no flags specified
	if !scan && !export {
		scan = true
		export = true
	}

	// Execute operations
	if scan {
		console.print_header('Scanning collections...')
		a.scan(path: doctree_path.path)!
		console.print_green('✓ Scan complete: ${a.collections.len} collection(s) found')
	}

	if export {
		if destination == '' {
			destination = '${doctree_path.path}/output'
		}

		console.print_header('Exporting collections to: ${destination}')
		console.print_item('Include processing: ${include}')
		console.print_item('Redis metadata: ${redis}')

		// Export even if there are errors - we want to export what we can
		a.export(
			destination: destination
			reset:       reset
			include:     include
			redis:       redis
		) or { console.print_item('Export completed with errors: ${err}') }

		console.print_green('✓ Export complete to ${destination}')

		// Print any errors encountered during export
		for _, col in a.collections {
			if col.has_errors() {
				col.print_errors()
			}
		}

		// Run dev server if -dev flag is set
		if dev {
			console.print_header('Starting development server...')
			console.print_item('DocTree export directory: ${destination}')
			console.print_item('Looking for docusaurus configuration in: ${doctree_path.path}')

			// Run the docusaurus dev server using the exported doctree content
			// This will look for a .heroscript file in the doctree_path that configures docusaurus
			// with use_doctree:true and doctree_export_dir pointing to the destination
			playcmds.run(
				heroscript_path: doctree_path.path
				reset:           reset
			)!

			// Get the docusaurus site and run dev server
			mut dsite := docusaurus.dsite_get('')!
			dsite.dev(
				open:          open_
				watch_changes: false
			)!
		}
	}
}
