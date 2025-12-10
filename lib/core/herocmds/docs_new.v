module herocmds

import os
import cli { Command, Flag }
import incubaid.herolib.ui.console
import incubaid.herolib.osal.core as osal
import incubaid.herolib.web.docusaurus
import incubaid.herolib.core.playcmds

pub fn cmd_docs_new(mut cmd_parent Command) {
	mut cmd := Command{
		name:          'new'
		description:   'Create a new documentation project scaffold with collections and ebooks.'
		required_args: 0
		execute:       cmd_docs_new_execute
	}

	cmd.add_flag(Flag{
		flag:        .string
		required:    true
		name:        'name'
		abbrev:      'n'
		description: 'Name of the project (used for collection and ebook names).'
	})

	cmd.add_flag(Flag{
		flag:        .string
		required:    true
		name:        'path'
		abbrev:      'p'
		description: 'Path where to create the project.'
	})

	cmd.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'code'
		abbrev:      'c'
		description: 'Open the generated project in VS Code.'
	})

	cmd.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'dev'
		abbrev:      'd'
		description: 'Run dev server after creating the project.'
	})

	cmd.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'open'
		abbrev:      'o'
		description: 'Open browser when running dev server (use with --dev).'
	})

	cmd.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'force'
		abbrev:      'f'
		description: 'Overwrite existing project if it exists.'
	})

	cmd_parent.add_command(cmd)
}

fn cmd_docs_new_execute(cmd Command) ! {
	name := cmd.flags.get_string('name') or { return error('Name is required') }
	path := cmd.flags.get_string('path') or { return error('Path is required') }
	open_code := cmd.flags.get_bool('code') or { false }
	dev := cmd.flags.get_bool('dev') or { false }
	open_browser := cmd.flags.get_bool('open') or { false }
	force := cmd.flags.get_bool('force') or { false }

	if !os.exists(path) {
		return error('Path does not exist: ${path}')
	}

	project_path := os.join_path(path, name)
	if os.exists(project_path) {
		if force {
			os.rmdir_all(project_path) or {
				return error('Failed to remove existing project: ${err}')
			}
		} else {
			return error('Project already exists at: ${project_path}. Use -force to overwrite.')
		}
	}

	console.print_header('Creating documentation project: ${name}')

	collections_path := os.join_path(project_path, 'collections', name)
	ebooks_path := os.join_path(project_path, 'ebooks', name)
	static_path := os.join_path(project_path, 'docusaurusbase', 'static', 'img')

	os.mkdir_all(collections_path)!
	os.mkdir_all(ebooks_path)!
	os.mkdir_all(static_path)!

	args := TemplateArgs{
		name:  name
		title: name.replace('_', ' ').title()
	}

	create_collection_files(collections_path, args)!
	create_ebook_files(ebooks_path, args)!
	create_static_files(static_path, args)!

	console.print_green('✓ Documentation project created successfully!')
	println('')
	print_usage_guide(project_path, ebooks_path, name)

	if open_code {
		console.print_header('Opening project in VS Code...')
		osal.exec(cmd: 'code "${project_path}"') or {
			console.print_stderr('Failed to open VS Code: ${err}')
		}
	}

	if dev {
		console.print_header('Starting development server...')
		playcmds.run(heroscript_path: ebooks_path)!
		mut dsite := docusaurus.dsite_get('')!
		dsite.dev(open: open_browser, watch_changes: false)!
	}
}

fn print_usage_guide(project_path string, ebooks_path string, name string) {
	console.print_item('Project path: ${project_path}')
	console.print_item('Collections: ${project_path}/collections/${name}')
	console.print_item('Ebooks: ${ebooks_path}')
}

struct TemplateArgs {
pub:
	name  string
	title string
}

fn create_collection_files(collections_path string, args TemplateArgs) ! {
	os.write_file(os.join_path(collections_path, '.collection'), 'name:${args.name}')!
	os.write_file(os.join_path(collections_path, 'introduction.md'), $tmpl('templates/docs_new/introduction.md'))!
	os.write_file(os.join_path(collections_path, 'usage.md'), $tmpl('templates/docs_new/usage.md'))!
	os.write_file(os.join_path(collections_path, 'support.md'), $tmpl('templates/docs_new/support.md'))!
}

fn create_ebook_files(ebooks_path string, args TemplateArgs) ! {
	os.write_file(os.join_path(ebooks_path, 'config.hero'), $tmpl('templates/docs_new/config.hero'))!
	os.write_file(os.join_path(ebooks_path, 'include.hero'), '')!
	os.write_file(os.join_path(ebooks_path, 'menus.hero'), $tmpl('templates/docs_new/menus.hero'))!
	os.write_file(os.join_path(ebooks_path, 'scan.hero'), $tmpl('templates/docs_new/scan.hero'))!
	os.write_file(os.join_path(ebooks_path, 'pages.hero'), $tmpl('templates/docs_new/pages.hero'))!
}

fn create_static_files(static_path string, args TemplateArgs) ! {
	// Copy the logo from embedded template
	logo_data := $embed_file('templates/docs_new/logo.png')
	os.write_file(os.join_path(static_path, 'logo.png'), logo_data.to_string())!
}
