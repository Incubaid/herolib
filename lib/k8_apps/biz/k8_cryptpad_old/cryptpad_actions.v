module k8_cryptpad

import incubaid.herolib.ui.console
import incubaid.herolib.installers.ulist
import incubaid.herolib.k8_apps.core
import time

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client

	// Try to get the cryptpad deployment
	deployments := k8s.get_deployments(k8app.namespace) or {
		// If we can't get deployments, it's not running
		return false
	}

	// Check if cryptpad deployment exists
	for deployment in deployments {
		if deployment.name == 'cryptpad' {
			return true
		}
	}

	return false
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {
	// installers.upload(
	//     cmdname: 'cryptpad'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/cryptpad'
	// )!
}

fn install() ! {
	console.print_header('Installing CryptPad...')

	// Get installer config to access namespace
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client
	configure()!

	// 1. Check for dependencies.
	console.print_info('Checking for kubectl...')
	core.kubectl_installed(mut k8s)!
	console.print_info('kubectl is installed and configured.')

	// 4. Apply the YAML files using kubernetes client
	console.print_info('Applying Gateway YAML file to the cluster...')
	res1 := k8s.apply_yaml(installer.tfgw_cryptpad_path)!
	if !res1.success {
		return error('Failed to apply tfgw-cryptpad.yaml: ${res1.stderr}')
	}
	console.print_info('Gateway YAML file applied successfully.')

	// 5. Verify TFGW deployments
	core.verify_tfgw_deployment(tfgw_name: 'cryptpad-main', namespace: k8app.namespace, k8s: k8s)!
	core.verify_tfgw_deployment(tfgw_name: 'cryptpad-sandbox', namespace: k8app.namespace, k8s: k8s)!

	// 6. Apply Cryptpad YAML
	console.print_info('Applying Cryptpad YAML file to the cluster...')
	res2 := k8s.apply_yaml(installer.cryptpad_path)!
	if !res2.success {
		return error('Failed to apply cryptpad.yaml: ${res2.stderr}')
	}
	console.print_info('Cryptpad YAML file applied successfully.')

	// 7. Verify deployment status
	console.print_info('Verifying deployment status...')
	mut is_running := false
	for i in 0 .. core.max_deployment_retries {
		if installed()! {
			is_running = true
			break
		}
		console.print_info('Waiting for CryptPad deployment to be ready... (${i + 1}/${core.max_deployment_retries})')
		time.sleep(core.deployment_check_interval_seconds * time.second)
	}

	if is_running {
		console.print_header('CryptPad installation successful!')
	} else {
		return error('CryptPad deployment failed to start.')
	}
}

fn destroy() ! {
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client
	
	core.destroy_namespace(mut k8s, k8app.namespace)!
}
