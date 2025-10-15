module wireguard_installer

import incubaid.herolib.osal.core as osal
import incubaid.herolib.installers.ulist
import incubaid.herolib.ui.console
import incubaid.herolib.core

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	osal.execute_silent('wg --version') or { return false }
	return true
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {}

fn install() ! {
	console.print_header('install wireguard')
	cmd := match core.platform()! {
		.ubuntu {
			'sudo apt install -y wireguard'
		}
		.osx {
			'sudo brew install -y wireguard-tools'
		}
		else {
			return error('unsupported platfrom ${core.platform()!}')
		}
	}

	osal.execute_stdout(cmd)!
	console.print_header('wireguard is installed')
}

fn destroy() ! {
	console.print_header('uninstall wireguard')

	cmd := match core.platform()! {
		.ubuntu {
			'sudo apt remove -y wireguard wireguard-tools'
		}
		.osx {
			'sudo brew uninstall -y wireguard-tools'
		}
		else {
			return error('unsupported platform ${core.platform()!}')
		}
	}

	osal.execute_stdout(cmd)!
	console.print_header('wireguard is uninstalled')
}
