module herocmds

import incubaid.herolib.ui.console
import incubaid.herolib.web.docusaurus
import incubaid.herolib.core.playcmds
import incubaid.herolib.develop.gittools
import os
import cli { Command, Flag }

pub fn cmd_docusaurus(mut cmdroot Command) Command {
	mut cmd_run := Command{
		name:          'docs'
		description:   'Generate, build, run docusaurus sites.'
		required_args: 0
		execute:       cmd_docusaurus_execute
	}

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'reset'
		abbrev:      'r'
		description: 'will reset.'
	})

	cmd_run.add_flag(Flag{
		flag:     .string
		required: false
		name:     'url'
		abbrev:   'u'
		// default: ''
		description: 'Url where docusaurus source is.'
	})

	cmd_run.add_flag(Flag{
		flag:     .string
		required: false
		name:     'path'
		abbrev:   'p'
		// default: ''
		description: 'Path where docusaurus configuration is.'
	})

	// cmd_run.add_flag(Flag{
	// 	flag:     .string
	// 	required: false
	// 	name:     'buildpath'
	// 	abbrev:   'b'
	// 	// default: ''
	// 	description: 'Path where docusaurus build is.'
	// })

	// cmd_run.add_flag(Flag{
	// 	flag:     .string
	// 	required: false
	// 	name:     'deploykey'
	// 	abbrev:   'dk'
	// 	// default: ''
	// 	description: 'Path of SSH Key used to deploy.'
	// })

	// cmd_run.add_flag(Flag{
	// 	flag:     .string
	// 	required: false
	// 	name:     'publish'
	// 	// default: ''
	// 	description: 'Path where to publish.'
	// })

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'buildpublish'
		abbrev:      'bp'
		description: 'build and publish.'
	})

	// cmd_run.add_flag(Flag{
	// 	flag:        .bool
	// 	required:    false
	// 	name:        'builddevpublish'
	// 	abbrev:      'bpd'
	// 	description: 'build dev version and publish.'
	// })

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'open'
		abbrev:      'o'
		description: 'open the site in browser.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'update'
		description: 'update your environment the template and the repo you are working on (git pull).'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'dev'
		abbrev:      'd'
		description: 'Run your dev environment on local browser.'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'host'
		abbrev:      'h'
		description: 'Host to bind the dev server to (default: localhost). Use 0.0.0.0 for container access.'
	})

	cmd_run.add_flag(Flag{
		flag:        .int
		required:    false
		name:        'port'
		description: 'Port to run the dev server on (default: 3000).'
	})

	// Add subcommands
	cmd_docs_new(mut cmd_run)

	cmdroot.add_command(cmd_run)
	return cmdroot
}

fn cmd_docusaurus_execute(cmd Command) ! {
	// ---------- FLAGS ----------
	mut open_ := cmd.flags.get_bool('open') or { false }
	mut buildpublish := cmd.flags.get_bool('buildpublish') or { false }
	// mut builddevpublish := cmd.flags.get_bool('builddevpublish') or { false }
	mut dev := cmd.flags.get_bool('dev') or { false }
	mut reset := cmd.flags.get_bool('reset') or { false }
	mut update := cmd.flags.get_bool('update') or { false }
	host := cmd.flags.get_string('host') or { 'localhost' }
	port := cmd.flags.get_int('port') or { 3000 }

	// ---------- PATH LOGIC ----------
	// Resolve the source directory that contains a “cfg” sub‑directory.
	mut path := cmd.flags.get_string('path') or { '' }
	mut url := cmd.flags.get_string('url') or { '' }

	if path == '' && url == '' {
		path = os.getwd()
	}

	docusaurus_path := gittools.path(
		git_url:   url
		path:      path
		git_reset: reset
		git_pull:  update
	)!

	console.print_header('Running Docusaurus for: ${docusaurus_path.path}')

	playcmds.run(
		heroscript_path: docusaurus_path.path
		reset:           false
	)!

	// TODO: We need to load the sitename instead, or maybe remove it
	mut dsite := docusaurus.dsite_get('')!

	if buildpublish {
		// Build and publish production-ready artifacts
		dsite.build_publish()!
	} else if dev {
		// Run local development server
		dsite.dev(
			open:          open_
			watch_changes: false
			host:          host
			port:          port
		)!
	} else {
		// Default: just build the static site
		dsite.build()!
	}
}
