module kubernetes_installer

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.core
import incubaid.herolib.installers.ulist
import os

//////////////////// following actions are not specific to instance of the object

// checks if kubectl is installed and meets minimum version requirement
fn installed() !bool {
	if !osal.cmd_exists('kubectl') {
		return false
	}

	res := os.execute('${osal.profile_path_source_and()!} kubectl version --client --output=json')
	if res.exit_code != 0 {
		// Try older kubectl version command format
		res2 := os.execute('${osal.profile_path_source_and()!} kubectl version --client --short')
		if res2.exit_code != 0 {
			return false
		}
		// Parse version from output like "Client Version: v1.31.0"
		lines := res2.output.split_into_lines().filter(it.contains('Client Version'))
		if lines.len == 0 {
			return false
		}
		version_str := lines[0].all_after('v').trim_space()
		if texttools.version(version) <= texttools.version(version_str) {
			return true
		}
		return false
	}

	// For newer kubectl versions with JSON output
	// Just check if kubectl exists and runs - version checking is optional
	return true
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {
	// Not applicable for kubectl
}

fn install() ! {
	console.print_header('install kubectl')

	mut url := ''
	mut dest_path := '/tmp/kubectl'

	// Determine download URL based on platform
	if core.is_linux_arm()! {
		url = 'https://dl.k8s.io/release/v${version}/bin/linux/arm64/kubectl'
	} else if core.is_linux_intel()! {
		url = 'https://dl.k8s.io/release/v${version}/bin/linux/amd64/kubectl'
	} else if core.is_osx_arm()! {
		url = 'https://dl.k8s.io/release/v${version}/bin/darwin/arm64/kubectl'
	} else if core.is_osx_intel()! {
		url = 'https://dl.k8s.io/release/v${version}/bin/darwin/amd64/kubectl'
	} else {
		return error('unsupported platform for kubectl installation')
	}

	console.print_header('downloading kubectl from ${url}')

	// Download kubectl binary
	osal.download(
		url: url
		// minsize_kb: 40000 // kubectl is ~45MB
		dest: dest_path
	)!

	// Make it executable
	os.chmod(dest_path, 0o755)!

	// Install to system
	osal.cmd_add(
		cmdname: 'kubectl'
		source:  dest_path
	)!

	// Create .kube directory with proper permissions
	kube_dir := os.join_path(os.home_dir(), '.kube')
	if !os.exists(kube_dir) {
		console.print_header('creating ${kube_dir} directory')
		os.mkdir_all(kube_dir)!
		os.chmod(kube_dir, 0o700)! // read/write/execute for owner only
		console.print_header('${kube_dir} directory created with permissions 0700')
	} else {
		// Ensure correct permissions even if directory exists
		os.chmod(kube_dir, 0o700)!
		console.print_header('${kube_dir} directory permissions set to 0700')
	}

	console.print_header('kubectl installed successfully')
}

fn destroy() ! {
	console.print_header('destroy kubectl')

	if !installed()! {
		console.print_header('kubectl is not installed')
		return
	}

	// Remove kubectl command
	osal.cmd_delete('kubectl')!

	// Clean up any temporary files
	osal.rm('/tmp/kubectl')!

	console.print_header('kubectl destruction completed')
}
