module python

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console

// Export current environment dependencies to requirements.txt
pub fn (py PythonEnv) freeze() !string {
	console.print_debug('Freezing requirements for environment: ${py.name}')
	cmd := '
	cd ${py.path.path}
	source .venv/bin/activate
	uv pip freeze
	'
	result := osal.exec(cmd: cmd)!
	console.print_debug('Successfully froze requirements')
	return result.output
}

// Export dependencies to a requirements.txt file
pub fn (mut py PythonEnv) freeze_to_file(filename string) ! {
	requirements := py.freeze()!
	mut req_file := py.path.file_get_new(filename)!
	req_file.write(requirements)!
	console.print_debug('Requirements written to: ${filename}')
}

// Install dependencies from requirements.txt file
pub fn (py PythonEnv) install_from_requirements(filename string) ! {
	console.print_debug('Installing from requirements file: ${filename}')
	cmd := '
	cd ${py.path.path}
	source .venv/bin/activate
	uv pip install -r ${filename}
	'
	osal.exec(cmd: cmd)!
	console.print_debug('Successfully installed from requirements file')
}

// Export current lock state (equivalent to uv.lock)
pub fn (py PythonEnv) export_lock() !string {
	console.print_debug('Exporting lock state for environment: ${py.name}')
	cmd := '
	cd ${py.path.path}
	uv export --format requirements-txt
	'
	result := osal.exec(cmd: cmd)!
	console.print_debug('Successfully exported lock state')
	return result.output
}

// Export lock state to file
pub fn (mut py PythonEnv) export_lock_to_file(filename string) ! {
	lock_content := py.export_lock()!
	mut lock_file := py.path.file_get_new(filename)!
	lock_file.write(lock_content)!
	console.print_debug('Lock state written to: ${filename}')
}

// Restore environment from lock file
pub fn (py PythonEnv) restore_from_lock() ! {
	console.print_debug('Restoring environment from uv.lock')
	cmd := '
	cd ${py.path.path}
	uv sync --frozen
	'
	osal.exec(cmd: cmd)!
	console.print_debug('Successfully restored from lock file')
}
