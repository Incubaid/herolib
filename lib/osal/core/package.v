module core

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core

// update the package list
pub fn package_refresh() ! {
	platform_ := core.platform()!

	if cmd_exists('nix-env') {
		// nix package manager is installed
		// nothing to do
		return
	}

	if platform_ == .ubuntu {
		// Refresh the package list for Ubuntu/Debian
		exec(cmd: 'sudo apt-get update') or {
			return error('Could not update packages for Ubuntu\nerror:\n${err}')
		}
		return
	} else if platform_ == .osx {
		// Refresh the package list for macOS
		exec(cmd: 'brew update') or {
			return error('Could not update packages for macOS\nerror:\n${err}')
		}
		return
	} else if platform_ == .alpine {
		// Refresh the package list for Alpine Linux
		exec(cmd: 'apk update') or {
			return error('Could not update packages for Alpine\nerror:\n${err}')
		}
		return
	} else if platform_ == .arch {
		// Refresh the package list for Arch Linux
		exec(cmd: 'sudo pacman -Syu --noconfirm') or {
			return error('Could not update packages for Arch Linux\nerror:\n${err}')
		}
		return
	}

	return error("Only ubuntu, alpine, arch, and osx are supported for now. Found \"${platform_}\"")
}

// install a package using the right commands per platform
pub fn package_install(name_ string) ! {
	names := texttools.to_array(name_)
	name := names.join(' ')
	console.print_header('package install: ${name}')

	platform_ := core.platform()!
	cpu := core.cputype()!

	mut sudo_pre := ''
	if core.sudo_required()! {
		sudo_pre = 'sudo '
	}
	if platform_ == .osx {
		if cpu == .arm {
			exec(cmd: 'arch --arm64 brew install ${name}') or {
				return error('could not install package on macOS (ARM): ${name}\nerror:\n${err}')
			}
		} else {
			exec(cmd: 'brew install ${name}') or {
				return error('could not install package on macOS: ${name}\nerror:\n${err}')
			}
		}
	} else if platform_ == .ubuntu {
		exec(
			cmd: 'export DEBIAN_FRONTEND=noninteractive && ${sudo_pre}apt install -y ${name}  -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --allow-downgrades --allow-remove-essential --allow-change-held-packages'
		) or { return error('could not install package on Ubuntu: ${name}\nerror:\n${err}') }
	} else if platform_ == .alpine {
		exec(cmd: '${sudo_pre}apk add ${name}') or {
			return error('could not install package on Alpine: ${name}\nerror:\n${err}')
		}
	} else if platform_ == .arch {
		exec(cmd: '${sudo_pre}pacman --noconfirm -Su ${name}') or {
			return error('could not install package on Arch: ${name}\nerror:\n${err}')
		}
	} else {
		return error('Only ubuntu, alpine, arch, and osx supported for now')
	}
}

// remove a package using the right commands per platform
pub fn package_remove(name_ string) ! {
	names := texttools.to_array(name_)
	name := names.join(' ')
	console.print_header('package remove: ${name}')

	platform_ := core.platform()!
	cpu := core.cputype()!

	// Debugging: print out platform and cpu type
	println('Platform: ${platform_}, CPU: ${cpu}')

	// Check if name is empty
	if name == '' {
		return error('Package name is empty')
	}

	// Determine if sudo is required by checking if the user has sudo privileges
	use_sudo := core.sudo_required()!

	// Platform-specific package removal logic
	if platform_ == .osx {
		if cpu == .arm {
			exec(cmd: 'arch --arm64 brew uninstall ${name}', ignore_error: true)!
		} else {
			exec(cmd: 'brew uninstall ${name}', ignore_error: true)!
		}
	} else if platform_ == .ubuntu {
		// Use sudo if required
		cmd := if use_sudo {
			'sudo apt remove -y ${name} --allow-change-held-packages'
		} else {
			'apt remove -y ${name} --allow-change-held-packages'
		}
		exec(cmd: cmd, ignore_error: false)!
		exec(cmd: 'sudo apt autoremove -y', ignore_error: true)!
	} else if platform_ == .alpine {
		// Use sudo if required
		cmd := if use_sudo { 'sudo apk del ${name}' } else { 'apk del ${name}' }
		exec(cmd: cmd, ignore_error: false)!
	} else if platform_ == .arch {
		// Use sudo if required
		cmd := if use_sudo {
			'sudo pacman --noconfirm -R ${name}'
		} else {
			'pacman --noconfirm -R ${name}'
		}
		exec(cmd: cmd, ignore_error: true)!
	} else {
		return error('Only ubuntu, alpine, and osx supported for now')
	}
}
