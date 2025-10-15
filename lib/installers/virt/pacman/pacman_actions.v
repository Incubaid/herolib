module pacman

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core
import incubaid.herolib.installers.ulist
import os

// checks if a certain version or above is installed
fn installed() !bool {
	console.print_header('checking if pacman is installed')
	res := os.execute('pacman -v')
	if res.exit_code != 0 {
		console.print_header('pacman is not installed')
		return false
	}
	console.print_header('pacman is installed')
	return true
}

fn ulist_get() !ulist.UList {
	return ulist.UList{}
}

fn upload() ! {
}

// use https://archlinux.org/mirrorlist/

fn install() ! {
	console.print_header('installing pacman')

	if core.platform()! == .arch {
		return
	}

	if core.platform()! != .ubuntu {
		return error('only ubuntu supported for this installer.')
	}

	mut cmd := 'apt update && apt upgrade -y'
	osal.execute_stdout(cmd)!

	cmd = 'mkdir -p /tmp/pacman'
	osal.execute_stdout(cmd)!

	cmd = 'cd /tmp/pacman && wget https://gitlab.com/trivoxel/utilities/deb-pacman/-/archive/${version}/deb-pacman-${version}.tar'
	osal.execute_stdout(cmd)!

	cmd = 'cd /tmp/pacman && tar -xf deb-pacman-v1.0.tar'
	osal.execute_stdout(cmd)!

	cmd = 'cd /tmp/pacman/deb-pacman-v1.0 && chmod +x pacman && sudo mv pacman /usr/local/bin'
	osal.execute_stdout(cmd)!

	console.print_header('pacman is installed')
}

fn destroy() ! {
	console.print_header('uninstall pacman')

	if core.platform()! == .arch {
		return
	}

	if core.platform()! != .ubuntu {
		return error('only ubuntu supported for this installer.')
	}

	mut cmd := 'rm -rf /tmp/pacman'
	osal.execute_stdout(cmd)!

	cmd = 'sudo rm -rf /usr/local/bin/pacman'
	osal.execute_stdout(cmd)!

	console.print_header('pacman is uninstalled')
}
