module kubectl_installer

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.installers.ulist
import incubaid.herolib.core

// checks if kubectl is installed
fn installed() !bool {
	return osal.cmd_exists('kubectl')
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {
	// Not applicable for kubectl
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

fn install(args InstallArgs) ! {
	console.print_header('Installing kubectl')

	// Check if already installed and reset not requested
	if !args.reset && osal.cmd_exists('kubectl') {
		console.print_debug('kubectl is already installed')
		return
	}

	// Determine the correct URL based on platform
	mut kubectl_url := ''
	if core.is_linux_arm()! {
		kubectl_url = 'https://dl.k8s.io/release/${version}/bin/linux/arm64/kubectl'
	} else if core.is_linux_intel()! {
		kubectl_url = 'https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl'
	} else if core.is_osx_arm()! {
		kubectl_url = 'https://dl.k8s.io/release/${version}/bin/darwin/arm64/kubectl'
	} else if core.is_osx_intel()! {
		kubectl_url = 'https://dl.k8s.io/release/${version}/bin/darwin/amd64/kubectl'
	} else {
		return error('unsupported platform')
	}

	osal.download(
		url:  kubectl_url
		dest: '/tmp/kubectl'
	)!

	// Make it executable and add to PATH
	osal.exec(cmd: 'chmod +x /tmp/kubectl')!
	osal.cmd_add(
		cmdname: 'kubectl'
		source:  '/tmp/kubectl'
	)!

	console.print_header('kubectl ${version} installed successfully')
}

fn destroy() ! {
	console.print_header('Removing kubectl...')

	// Remove kubectl binary
	osal.cmd_delete('kubectl') or { console.print_debug('kubectl not found or already removed') }

	console.print_header('kubectl removed successfully')
}
