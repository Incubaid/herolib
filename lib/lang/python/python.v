module python

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.ui.console
import os

pub struct PythonEnv {
pub mut:
	name string
	path pathlib.Path
}

@[params]
pub struct PythonEnvArgs {
pub mut:
	name             string = 'default'
	reset            bool
	python_version   string = '3.11'
	dependencies     []string
	dev_dependencies []string
	description      string = 'A Python project managed by Herolib'
}

pub fn new(args_ PythonEnvArgs) !PythonEnv {
	console.print_debug('Creating new Python environment with name: ${args_.name}')
	mut args := args_
	name := texttools.name_fix(args.name)

	pp := '${os.home_dir()}/hero/python/${name}'
	console.print_debug('Python environment path: ${pp}')

	mut py := PythonEnv{
		name: name
		path: pathlib.get_dir(path: pp, create: true)!
	}

	// Check if environment needs to be reset
	if !py.exists() || args.reset {
		console.print_debug('Python environment needs initialization')
		py.init_env(args)!
	}

	return py
}

// Check if the Python environment exists and is properly configured
pub fn (py PythonEnv) exists() bool {
	return os.exists('${py.path.path}/.venv/bin/activate')
		&& os.exists('${py.path.path}/pyproject.toml')
}

// Initialize the Python environment using uv
pub fn (mut py PythonEnv) init_env(args PythonEnvArgs) ! {
	console.print_green('Initializing Python environment at: ${py.path.path}')

	// Remove existing environment if reset is requested
	if args.reset && py.path.exists() {
		console.print_debug('Removing existing environment for reset')
		py.path.delete()!
		py.path = pathlib.get_dir(path: py.path.path, create: true)!
	}

	// Check if uv is installed
	if !osal.cmd_exists('uv') {
		return error('uv is not installed. Please install uv first: curl -LsSf https://astral.sh/uv/install.sh | sh')
	}

	// Generate project files from templates
	template_args := TemplateArgs{
		name:             py.name
		python_version:   args.python_version
		dependencies:     args.dependencies
		dev_dependencies: args.dev_dependencies
		description:      args.description
	}

	py.generate_all_templates(template_args)!

	// Initialize uv project
	cmd := '
	cd ${py.path.path}
	uv venv --python ${args.python_version}
	'
	osal.exec(cmd: cmd)!

	// Sync dependencies if any are specified
	if args.dependencies.len > 0 || args.dev_dependencies.len > 0 {
		py.sync()!
	}

	console.print_debug('Python environment initialization complete')
}

// Sync dependencies using uv
pub fn (py PythonEnv) sync() ! {
	console.print_green('Syncing dependencies for Python environment: ${py.name}')
	cmd := '
	cd ${py.path.path}
	uv sync
	'
	osal.exec(cmd: cmd)!
	console.print_debug('Dependency sync complete')
}

// Add dependencies to the project
pub fn (py PythonEnv) add_dependencies(packages []string, dev bool) ! {
	if packages.len == 0 {
		return
	}

	console.print_debug('Adding Python packages: ${packages.join(', ')}')
	packages_str := packages.join(' ')

	mut cmd := '
	cd ${py.path.path}
	uv add ${packages_str}'

	if dev {
		cmd += ' --dev'
	}

	osal.exec(cmd: cmd)!
	console.print_debug('Successfully added packages: ${packages.join(', ')}')
}

// Remove dependencies from the project
pub fn (py PythonEnv) remove_dependencies(packages []string, dev bool) ! {
	if packages.len == 0 {
		return
	}

	console.print_debug('Removing Python packages: ${packages.join(', ')}')
	packages_str := packages.join(' ')

	mut cmd := '
	cd ${py.path.path}
	uv remove ${packages_str}'

	if dev {
		cmd += ' --dev'
	}

	osal.exec(cmd: cmd)!
	console.print_debug('Successfully removed packages: ${packages.join(', ')}')
}

// Legacy pip method for backward compatibility - now uses uv add
pub fn (py PythonEnv) pip(packages string) ! {
	package_list := packages.split(',').map(it.trim_space()).filter(it.len > 0)
	py.add_dependencies(package_list, false)!
}

// Legacy pip_uninstall method for backward compatibility - now uses uv remove
pub fn (py PythonEnv) pip_uninstall(packages string) ! {
	package_list := packages.split(',').map(it.trim_space()).filter(it.len > 0)
	py.remove_dependencies(package_list, false)!
}

// Get list of installed packages
pub fn (py PythonEnv) list_packages() ![]string {
	cmd := '
	cd ${py.path.path}
	source .venv/bin/activate
	uv pip list --format=freeze
	'
	result := osal.exec(cmd: cmd)!
	return result.output.split_into_lines().filter(it.trim_space().len > 0)
}

// Update all dependencies
pub fn (py PythonEnv) update() ! {
	console.print_green('Updating dependencies in Python environment: ${py.name}')
	cmd := '
	cd ${py.path.path}
	uv lock --upgrade
	uv sync
	'
	osal.exec(cmd: cmd)!
	console.print_debug('Dependencies update complete')
}

// Run a command in the Python environment
pub fn (py PythonEnv) run(command string) !osal.Job {
	cmd := '
	cd ${py.path.path}
	source .venv/bin/activate
	${command}
	'
	return osal.exec(cmd: cmd)!
}
