module hero_generator

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.playbook
import incubaid.herolib.data.paramsparser as params
import os

// args_get reads the .heroscript file and returns ModuleMeta
pub fn args_get(path string) !ModuleMeta {
	mut config_path := pathlib.get_file(path: '${path}/.heroscript', create: false)!

	if !config_path.exists() {
		return error("can't find path with .heroscript in ${path}, is a bug")
	}

	mut plbook := playbook.new(text: config_path.read()!) or {
		return error('failed to create playbook: ${err}')
	}

	mut install_actions := plbook.find(filter: 'hero_code.generate_installer')!
	mut client_actions := plbook.find(filter: 'hero_code.generate_client')!
	mut k8s_actions := plbook.find(filter: 'hero_code.generate_k8s')!

	if install_actions.len > 1 || k8s_actions.len > 1 || client_actions.len > 1 {
		return error("found more than one 'hero_code.generate_...' action in ${path}")
	}

	if install_actions.len + client_actions.len + k8s_actions.len > 1 {
		return error("found multiple 'hero_code.generate_...' actions in ${path}, can only be one or the other")
	}

	mut p := params.Params{}
	mut cat := Cat.installer

	if install_actions.len == 1 {
		p = install_actions[0].params
	}
	if k8s_actions.len == 1 {
		p = k8s_actions[0].params
		cat = .k8sapp
	}
	if client_actions.len == 1 {
		p = client_actions[0].params
		cat = .client
	}

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
		active:              p.get_default_true('active')
		cat:                 cat
		path:                path
	}

	args.check()!

	// Category-specific defaults
	if args.cat == .client {
		args.startupmanager = false
	}

	return args
}

// create_heroscript generates the .heroscript file for a module
pub fn create_heroscript(args ModuleMeta) ! {
	mut script := ''
	if args.path == '' {
		return error('no path provided to create heroscript')
	}
	
	match args.cat {
		.installer {
			script = create_installer_heroscript(args)
		}
		.k8sapp {
			script = create_k8sapp_heroscript(args)
		}
		.client {
			script = create_client_heroscript(args)
		}
	}
	
	if !os.exists(args.path) {
		os.mkdir(args.path)!
	}
	os.write_file('${args.path}/.heroscript', script)!
}

fn bool_str(b bool) string {
	return if b { '1' } else { '0' }
}

fn create_installer_heroscript(args ModuleMeta) string {
	return "
!!hero_code.generate_installer
    name:'${args.name}'
    classname:'${args.classname}'
    singleton:${bool_str(args.singleton)}
    templates:${bool_str(args.templates)}
    default:${bool_str(args.default)}
    title:'${args.title}'
    supported_platforms:''
    startupmanager:${bool_str(args.startupmanager)}
    hasconfig:${bool_str(args.hasconfig)}
    build:${bool_str(args.build)}"
}

fn create_k8sapp_heroscript(args ModuleMeta) string {
	return "
!!hero_code.generate_k8s
    name:'${args.name}'
    classname:'${args.classname}'
    singleton:${bool_str(args.singleton)}
    templates:${bool_str(args.templates)}
    default:${bool_str(args.default)}
    hasconfig:${bool_str(args.hasconfig)}
    startupmanager:0"
}

fn create_client_heroscript(args ModuleMeta) string {
	return "
!!hero_code.generate_client
    name:'${args.name}'
    classname:'${args.classname}'
    singleton:${bool_str(args.singleton)}
    default:${bool_str(args.default)}
    hasconfig:${bool_str(args.hasconfig)}"
}

