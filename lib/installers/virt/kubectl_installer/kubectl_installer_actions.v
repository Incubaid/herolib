module kubectl_installer

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.installers.ulist

//////////////////// INSTALLATION ACTIONS ////////////////////

// checks if kubectl is installed
fn (self &KubectlInstaller) installed() !bool {
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

fn (mut self KubectlInstaller) install(args InstallArgs) ! {
	console.print_header('Installing kubectl ${self.kubectl_version}...')

	// Check if already installed and reset not requested
	if !args.reset && osal.cmd_exists('kubectl') {
		console.print_debug('kubectl is already installed')
		return
	}

	// Download kubectl binary
	kubectl_url := 'https://dl.k8s.io/release/${self.kubectl_version}/bin/linux/amd64/kubectl'

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

	console.print_header('kubectl ${self.kubectl_version} installed successfully')
}

fn (mut self KubectlInstaller) destroy() ! {
	console.print_header('Removing kubectl...')

	// Remove kubectl binary
	osal.cmd_delete('kubectl') or { console.print_debug('kubectl not found or already removed') }

	console.print_header('kubectl removed successfully')
}
