module core

import freeflowuniverse.herolib.core

fn test_package_management() {
	platform_ := core.platform()!

	if platform_ == .osx {
		// Check if brew is installed
		if !cmd_exists('brew') {
			eprintln('WARNING: Homebrew is not installed. Please install it to run package management tests on OSX.')
			return
		}
	}

	is_wget_installed := cmd_exists('wget')

	if is_wget_installed {
		// Clean up - remove wget
		package_remove('wget') or { assert false, 'Failed to remove wget: ${err}' }
		assert !cmd_exists('wget')
		// Reinstalling wget as it was previously installed
		package_install('wget') or { assert false, 'Failed to install wget: ${err}' }
		assert cmd_exists('wget')
		return
	}

	// Intstall wget and verify it is installed
	package_install('wget') or { assert false, 'Failed to install wget: ${err}' }
	assert cmd_exists('wget')

	// Clean up - remove wget
	package_remove('wget') or { assert false, 'Failed to remove wget: ${err}' }
	assert !cmd_exists('wget')
}
