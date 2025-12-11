module hero_generator

import os

// Cat represents the category of module to generate
pub enum Cat {
	installer
	client
	k8sapp
}

// ModuleMeta contains metadata about a module to be generated
pub struct ModuleMeta {
pub mut:
	name                string // e.g. docusaurus
	classname           string // e.g. Docusaurus
	title               string // e.g. Docusaurus Website Generator
	singleton           bool   // if true, only one instance can exist
	templates           bool   // if true, include template files
	hasconfig           bool = true // if true, module has a config struct
	default             bool = true // if true, create default instance on new()
	startupmanager      bool = true // if true, use startup manager for lifecycle
	build               bool // if true, include build/compilation support
	cat                 Cat = .installer // category of module
	path                string // e.g. /home/user/code/mymodule
	module_path         string // e.g. incubaid.herolib.web.docusaurus
	active              bool = true // if false then we skip generation
	supported_platforms []string // only relevant for installers for now
	play_name           string   // e.g. docusaurus is what we look for
}

// GenerateArgs contains the arguments for module generation
@[params]
pub struct GenerateArgs {
pub mut:
	path           string
	reset          bool
	force          bool // deprecated: use interactive instead
	name           string
	classname      string
	title          string
	singleton      bool
	templates      bool
	hasconfig      bool = true
	default        bool = true
	startupmanager bool = true
	build          bool
	cat            Cat = .installer
	interactive    bool // if true, use interactive mode with prompts
}

// name_to_classname converts a snake_case name to PascalCase class name
// e.g., "my_installer" -> "MyInstaller", "api_client" -> "ApiClient"
pub fn name_to_classname(name string) string {
	mut result := ''
	mut capitalize_next := true

	for c in name {
		if c == `_` {
			capitalize_next = true
		} else {
			if capitalize_next {
				result += c.ascii_str().to_upper()
				capitalize_next = false
			} else {
				result += c.ascii_str()
			}
		}
	}

	return result
}

// to_meta converts GenerateArgs to ModuleMeta
pub fn (args GenerateArgs) to_meta() ModuleMeta {
	mut name := args.name
	if name == '' {
		name = os.base(args.path)
	}
	mut classname := args.classname
	if classname == '' {
		classname = name_to_classname(name)
	}

	return ModuleMeta{
		name:           name
		classname:      classname
		title:          args.title
		singleton:      args.singleton
		templates:      args.templates
		hasconfig:      args.hasconfig
		default:        args.default
		startupmanager: args.startupmanager
		build:          args.build
		cat:            args.cat
		path:           args.path
	}
}

// check validates the ModuleMeta and populates the module_path
pub fn (mut m ModuleMeta) check() ! {
	if m.name == '' {
		return error('name cannot be empty')
	}
	if m.classname == '' {
		return error('classname cannot be empty')
	}
	mut module_path := m.path.replace('/', '.')
	if module_path.contains('incubaid.herolib.lib.') {
		// Path is inside lib/ directory (e.g., lib/installers/horus/coordinator)
		module_path = module_path.split('incubaid.herolib.lib.')[1]
	} else {
		return error('path should be inside incubaid.herolib, so that module_path can be determined, now is: ${m.path}')
	}
	m.module_path = 'incubaid.herolib.${module_path.trim_space()}'
}

// platform_check_str returns a V condition string for platform checks
pub fn (args ModuleMeta) platform_check_str() string {
	mut out := ''

	if 'osx' in args.supported_platforms {
		out += 'myplatform == .osx || '
	}
	if 'ubuntu' in args.supported_platforms {
		out += 'myplatform == .ubuntu ||'
	}
	if 'arch' in args.supported_platforms {
		out += 'myplatform == .arch ||'
	}
	out = out.trim_right('|')
	return out
}
