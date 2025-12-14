module hero_generator

import incubaid.herolib.ui.console
import os

// prepare_meta prepares the ModuleMeta from GenerateArgs and creates .heroscript
// Returns the meta for the caller to route to the appropriate generator
pub fn prepare_meta(args_ GenerateArgs) !ModuleMeta {
	mut args := args_

	console.print_header('Generate code for path: ${args.path} (reset:${args.reset})')

	if args.path == '' {
		return error('no path provided')
	}

	if args.name == '' {
		args.name = os.base(args.path)
	}

	// Generate classname if not provided
	if args.classname == '' {
		args.classname = name_to_classname(args.name)
	}

	// Set sensible defaults based on category
	mut templates := args.templates
	mut startupmanager := args.startupmanager

	// k8sapp always needs templates for YAML manifests
	if args.cat == .k8sapp {
		templates = true
		startupmanager = false
	}
	// clients don't use startup manager
	if args.cat == .client {
		startupmanager = false
	}

	// Build ModuleMeta from args
	mut meta := ModuleMeta{
		name:           args.name
		classname:      args.classname
		title:          args.title
		singleton:      args.singleton
		templates:      templates
		hasconfig:      args.hasconfig
		default:        args.default
		startupmanager: startupmanager
		build:          args.build
		cat:            args.cat
		path:           args.path
	}

	// Create .heroscript
	console.print_debug('Creating module: ${meta.classname} (${meta.cat})')
	create_heroscript(meta)!

	return meta
}

// get_meta returns the ModuleMeta for a given path by parsing .heroscript
pub fn get_meta(path string) !ModuleMeta {
	return args_get(path)
}
