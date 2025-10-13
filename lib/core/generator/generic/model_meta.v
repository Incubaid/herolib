module generic

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.playbook
import incubaid.herolib.ui.console
import os

pub struct ModuleMeta {
pub mut:
	name                string
	classname           string
	default             bool = true // means user can just get the object and a default will be created
	title               string
	supported_platforms []string // only relevant for installers for now
	singleton           bool     // means there can only be one
	templates           bool     // means we will use templates in the installer, client doesn't do this'
	startupmanager      bool = true
	build               bool
	cat                 Cat
	path                string
	hasconfig           bool = true
	play_name           string // e.g. docusaurus is what we look for
	module_path         string // e.g.incubaid.herolib.web.docusaurus
}

pub enum Cat {
	installer
	client
}

fn args_get(path string) !ModuleMeta {
	console.print_debug('generate code for path: ${path}')

	mut config_path := pathlib.get_file(path: '${path}/.heroscript', create: false)!

	if !config_path.exists() {
		return error("can't find path with .heroscript in ${path}, is a bug")
	}

	mut plbook := playbook.new(text: config_path.read()!) or {
		return error('failed to create playbook: ${err}')
	}

	mut install_actions := plbook.find(filter: 'hero_code.generate_installer')!
	mut client_actions := plbook.find(filter: 'hero_code.generate_client')!

	if install_actions.len > 1 {
		return error("found more than one 'hero_code.generate_installer' action in ${path}")
	}

	if client_actions.len > 1 {
		return error("found more than one 'hero_code.generate_client' action in ${path}")
	}

	if install_actions.len == 1 && client_actions.len == 1 {
		return error("found both 'hero_code.generate_installer' and 'hero_code.generate_client' actions in ${path}, can only be one or the other")
	}

	if install_actions.len == 1 {
		mut p := install_actions[0].params
		mut name := p.get('name')!
		if name == '' {
			name = os.base(path)
		}
		mut args := ModuleMeta{
			name:                name
			classname:           p.get('classname')!
			title:               p.get_default('title', '')!
			play_name:           p.get_default('play_name', name)!
			default:             p.get_default_true('default')
			supported_platforms: p.get_list_default('supported_platforms', [])!
			singleton:           p.get_default_false('singleton')
			templates:           p.get_default_false('templates')
			startupmanager:      p.get_default_true('startupmanager')
			hasconfig:           p.get_default_true('hasconfig')
			build:               p.get_default_false('build')
			cat:                 .installer
			path:                path
		}
		args.check()!
		return args
	}

	if client_actions.len == 1 {
		mut p := client_actions[0].params
		mut name := p.get('name')!
		if name == '' {
			name = os.base(path)
		}
		mut args := ModuleMeta{
			name:      name
			classname: p.get('classname')!
			title:     p.get_default('title', '')!
			default:   p.get_default_true('default')
			singleton: p.get_default_false('singleton')
			cat:       .client
			path:      path
			play_name: p.get_default('play_name', name)!
		}
		args.check()!
		return args
	}
	return error("can't find hero_code.generate_client or hero_code.generate_installer in ${path}")
}

fn (mut m ModuleMeta) check() ! {
	if m.name == '' {
		return error('name cannot be empty')
	}
	if m.classname == '' {
		return error('classname cannot be empty')
	}
	mut module_path := m.path.replace('/', '.')
	if module_path.contains('incubaid.herolib.lib.') {
		module_path = module_path.split('incubaid.herolib.lib.')[1]
	} else {
		return error('path should be inside incubaid.herolib, so that module_path can be determined, now is: ${m.path}')
	}
	m.module_path = 'incubaid.herolib.${module_path.trim_space()}'
}
