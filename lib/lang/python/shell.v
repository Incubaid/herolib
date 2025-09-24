module python

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console

// Open an interactive shell in the Python environment
pub fn (py PythonEnv) shell() ! {
	console.print_green('Opening interactive shell for Python environment: ${py.name}')
	cmd := '
	cd ${py.path.path}
	source .venv/bin/activate
	exec \$SHELL
	'
	osal.execute_interactive(cmd)!
}

// Open a Python REPL in the environment
pub fn (py PythonEnv) python_shell() ! {
	console.print_green('Opening Python REPL for environment: ${py.name}')
	cmd := '
	cd ${py.path.path}
	source .venv/bin/activate
	python
	'
	osal.execute_interactive(cmd)!
}

// Open IPython if available, fallback to regular Python
pub fn (py PythonEnv) ipython_shell() ! {
	console.print_green('Opening IPython shell for environment: ${py.name}')

	// Check if IPython is available
	check_cmd := '
	cd ${py.path.path}
	source .venv/bin/activate
	python -c "import IPython"
	'

	check_result := osal.exec(cmd: check_cmd, raise_error: false)!

	mut shell_cmd := ''
	if check_result.exit_code == 0 {
		shell_cmd = '
		cd ${py.path.path}
		source .venv/bin/activate
		ipython
		'
	} else {
		console.print_debug('IPython not available, falling back to regular Python shell')
		shell_cmd = '
		cd ${py.path.path}
		source .venv/bin/activate
		python
		'
	}

	osal.execute_interactive(shell_cmd)!
}

// Run a specific Python script in the environment
pub fn (py PythonEnv) run_script(script_path string) !osal.Job {
	console.print_debug('Running Python script: ${script_path}')
	cmd := '
	cd ${py.path.path}
	source .venv/bin/activate
	python ${script_path}
	'
	return osal.exec(cmd: cmd)!
}

// Run a uv command in the environment context
pub fn (py PythonEnv) uv_run(command string) !osal.Job {
	console.print_debug('Running uv command: ${command}')
	cmd := '
	cd ${py.path.path}
	uv ${command}
	'
	return osal.exec(cmd: cmd)!
}
