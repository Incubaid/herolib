module python

import freeflowuniverse.herolib.ui.console

fn test_python_env_creation() {
	console.print_debug('Testing Python environment creation')

	// Test basic environment creation
	py := new(name: 'test_env') or {
		console.print_stderr('Failed to create Python environment: ${err}')
		panic(err)
	}

	assert py.name == 'test_env'
	assert py.path.path.contains('test_env')
	console.print_debug('✅ Environment creation test passed')
}

fn test_python_env_with_dependencies() {
	console.print_debug('Testing Python environment with dependencies')

	// Test environment with initial dependencies
	py := new(
		name:             'test_deps'
		dependencies:     ['requests', 'click']
		dev_dependencies: ['pytest', 'black']
		reset:            true
	) or {
		console.print_stderr('Failed to create Python environment with dependencies: ${err}')
		panic(err)
	}

	assert py.exists()
	console.print_debug('✅ Environment with dependencies test passed')
}

fn test_python_package_management() {
	console.print_debug('Testing package management')

	py := new(name: 'test_packages', reset: true) or {
		console.print_stderr('Failed to create Python environment: ${err}')
		panic(err)
	}

	// Test adding packages
	py.add_dependencies(['ipython'], false) or {
		console.print_stderr('Failed to add dependencies: ${err}')
		panic(err)
	}

	// Test legacy pip method
	py.pip('requests') or {
		console.print_stderr('Failed to install via pip method: ${err}')
		panic(err)
	}

	console.print_debug('✅ Package management test passed')
}

fn test_python_freeze_functionality() {
	console.print_debug('Testing freeze functionality')

	py := new(
		name:         'test_freeze'
		dependencies: ['click']
		reset:        true
	) or {
		console.print_stderr('Failed to create Python environment: ${err}')
		panic(err)
	}

	// Test freeze
	requirements := py.freeze() or {
		console.print_stderr('Failed to freeze requirements: ${err}')
		panic(err)
	}

	assert requirements.len > 0
	console.print_debug('✅ Freeze functionality test passed')
}

fn test_python_template_generation() {
	console.print_debug('Testing template generation')

	py := new(name: 'test_templates', reset: true) or {
		console.print_stderr('Failed to create Python environment: ${err}')
		panic(err)
	}

	// Check that pyproject.toml was generated
	pyproject_exists := py.path.file_exists('pyproject.toml')
	assert pyproject_exists

	// Check that shell scripts were generated
	env_script_exists := py.path.file_exists('env.sh')
	install_script_exists := py.path.file_exists('install.sh')
	assert env_script_exists
	assert install_script_exists

	console.print_debug('✅ Template generation test passed')
}

// Main test function that runs all tests
fn test_python() {
	console.print_header('Running Python module tests')

	test_python_env_creation()
	test_python_env_with_dependencies()
	test_python_package_management()
	test_python_freeze_functionality()
	test_python_template_generation()

	console.print_green('🎉 All Python module tests passed!')
}
