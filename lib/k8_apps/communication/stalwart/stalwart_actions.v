module stalwart

import incubaid.herolib.ui.console
import incubaid.herolib.installers.ulist
import incubaid.herolib.k8_apps.core
import time

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
pub fn installed() !bool {
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client

	// Try to get the stalwart deployment
	deployments := k8s.get_deployments(k8app.namespace) or {
		// If we can't get deployments, it's not running
		return false
	}

	// Check if stalwart deployment exists
	for deployment in deployments {
		if deployment.name == 'stalwart' {
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
	//     cmdname: 'stalwart'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/stalwart'
	// )!
}

fn install() ! {
	console.print_header('Installing Stalwart Mail Server...')

	// Get installer config to access namespace
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client
	configure()!

	// 1. Check for dependencies.
	console.print_info('Checking for kubectl...')
	core.kubectl_installed(mut k8s)!
	console.print_info('kubectl is installed and configured.')

	// 2. Apply the YAML files using kubernetes client
	console.print_info('Applying Gateway YAML file to the cluster...')
	res1 := k8s.apply_yaml(installer.tfgw_path)!
	if !res1.success {
		return error('Failed to apply tfgw-stalwart.yaml: ${res1.stderr}')
	}
	console.print_info('Gateway YAML file applied successfully.')

	// 3. Verify TFGW deployment
	core.verify_tfgw_deployment(tfgw_name: 'stalwart-tfgw', namespace: k8app.namespace, k8s: k8s)!

	// 4. Apply Stalwart App YAML
	console.print_info('Applying Stalwart App YAML file to the cluster...')
	res2 := k8s.apply_yaml(installer.stalwart_app_path)!
	if !res2.success {
		return error('Failed to apply stalwart-app.yaml: ${res2.stderr}')
	}
	console.print_info('Stalwart App YAML file applied successfully.')

	// 5. Verify deployment status
	console.print_info('Verifying deployment status...')
	mut is_running := false
	for i in 0 .. core.max_deployment_retries {
		if installed()! {
			is_running = true
			break
		}
		console.print_info('Waiting for Stalwart deployment to be ready... (${i + 1}/${core.max_deployment_retries})')
		time.sleep(core.deployment_check_interval_seconds * time.second)
	}

	if is_running {
		console.print_header('Stalwart Mail Server installation successful!')
		console.print_header('You can access Stalwart Web UI at https://${installer.hostname}.gent01.grid.tf')
		console.print_header('Admin user: ${installer.admin_user}')
		console.print_info('Mail ports (SMTP/IMAP/POP3) are available via LoadBalancer service.')
	} else {
		return error('Stalwart deployment failed to start.')
	}
}

fn destroy() ! {
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client

	core.destroy_namespace(mut k8s, k8app.namespace)!
}
