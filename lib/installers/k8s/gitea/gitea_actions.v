module gitea

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.installers.ulist
import time

const max_deployment_retries = 30
const deployment_check_interval_seconds = 2

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
pub fn installed() !bool {
	installer := get()!
	mut k8s := installer.kube_client

	// Try to get the gitea deployment
	deployments := k8s.get_deployments(installer.namespace) or {
		// If we can't get deployments, it's not running
		return false
	}

	// Check if gitea deployment exists
	for deployment in deployments {
		if deployment.name == 'gitea' {
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
	//     cmdname: 'gitea'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/gitea'
	// )!
}

fn install() ! {
	console.print_header('Installing Gitea...')

	// Get installer config to access namespace
	installer := get()!
	mut k8s := installer.kube_client
	configure()!

	// 1. Check for dependencies.
	console.print_info('Checking for kubectl...')
	kubectl_installed()!
	console.print_info('kubectl is installed and configured.')

	// 2. Apply the YAML files using kubernetes client
	console.print_info('Applying Gateway YAML file to the cluster...')
	res1 := k8s.apply_yaml('/tmp/gitea/tfgw-gitea.yaml')!
	if !res1.success {
		return error('Failed to apply tfgw-gitea.yaml: ${res1.stderr}')
	}
	console.print_info('Gateway YAML file applied successfully.')

	// 3. Verify TFGW deployment
	verify_tfgw_deployment(tfgw_name: 'gitea', namespace: installer.namespace)!

	// 4. Apply Gitea App YAML
	console.print_info('Applying Gitea App YAML file to the cluster...')
	res2 := k8s.apply_yaml('/tmp/gitea/gitea.yaml')!
	if !res2.success {
		return error('Failed to apply gitea.yaml: ${res2.stderr}')
	}
	console.print_info('Gitea App YAML file applied successfully.')

	// 5. Verify deployment status
	console.print_info('Verifying deployment status...')
	mut is_running := false
	for i in 0 .. max_deployment_retries {
		if installed()! {
			is_running = true
			break
		}
		console.print_info('Waiting for Gitea deployment to be ready... (${i + 1}/${max_deployment_retries})')
		time.sleep(deployment_check_interval_seconds * time.second)
	}

	if is_running {
		console.print_header('Gitea installation successful!')
		console.print_header('You can access Gitea at https://${installer.hostname}.gent01.grid.tf')
	} else {
		return error('Gitea deployment failed to start.')
	}
}

// params for verifying the generating of the FQDN using tfgw crd
@[params]
struct VerifyTfgwDeployment {
pub mut:
	tfgw_name string // tfgw serivce generating the FQDN
	namespace string // namespace name for gitea deployments/services
}

// Function for verifying the generating of of the FQDN using tfgw crd
fn verify_tfgw_deployment(args VerifyTfgwDeployment) ! {
	console.print_info('Verifying TFGW deployment for ${args.tfgw_name}...')
	installer := get()!
	mut k8s := installer.kube_client
	mut is_fqdn_generated := false

	for i in 0 .. max_deployment_retries {
		// Use kubectl_exec for custom resource (TFGW) with jsonpath
		result := k8s.kubectl_exec(
			command: 'get tfgw ${args.tfgw_name} -n ${args.namespace} -o jsonpath="{.status.fqdn}"'
		) or {
			console.print_info('Waiting for FQDN to be generated for ${args.tfgw_name}... (${i + 1}/${max_deployment_retries})')
			time.sleep(deployment_check_interval_seconds * time.second)
			continue
		}

		if result.success && result.stdout != '' {
			is_fqdn_generated = true
			break
		}
		console.print_info('Waiting for FQDN to be generated for ${args.tfgw_name}... (${i + 1}/${max_deployment_retries})')
		time.sleep(deployment_check_interval_seconds * time.second)
	}

	if !is_fqdn_generated {
		console.print_stderr('Failed to get FQDN for ${args.tfgw_name}.')
		// Use describe_resource to get detailed information about the TFGW resource
		result := k8s.describe_resource(
			resource:      'tfgw'
			resource_name: args.tfgw_name
			namespace:     args.namespace
		) or { return error('TFGW deployment failed for ${args.tfgw_name}.') }
		console.print_stderr(result.stdout)
		return error('TFGW deployment failed for ${args.tfgw_name}.')
	}
	console.print_info('TFGW deployment for ${args.tfgw_name} verified successfully.')
}

fn destroy() ! {
	console.print_header('Destroying Gitea...')
	installer := get()!
	mut k8s := installer.kube_client

	console.print_debug('Attempting to delete namespace: ${installer.namespace}')

	// Delete the namespace using kubernetes client
	result := k8s.delete_resource('namespace', installer.namespace, '') or {
		console.print_stderr('Failed to delete namespace ${installer.namespace}: ${err}')
		return error('Failed to delete namespace ${installer.namespace}: ${err}')
	}

	console.print_debug('Delete command completed. Exit code: ${result.exit_code}, Success: ${result.success}')

	if !result.success {
		// Namespace not found is OK - it means it's already deleted
		if result.stderr.contains('NotFound') {
			console.print_info('Namespace ${installer.namespace} does not exist (already deleted).')
		} else {
			console.print_stderr('Failed to delete namespace ${installer.namespace}: ${result.stderr}')
			return error('Failed to delete namespace ${installer.namespace}: ${result.stderr}')
		}
	} else {
		console.print_info('Namespace ${installer.namespace} deleted successfully.')
	}
}

fn kubectl_installed() ! {
	// Check if kubectl command exists
	if !osal.cmd_exists('kubectl') {
		return error('kubectl is not installed. Please install it to continue.')
	}

	// Check if kubectl is configured to connect to a cluster
	installer := get()!
	mut k8s := installer.kube_client

	if !k8s.test_connection()! {
		return error('kubectl is not configured to connect to a Kubernetes cluster. Please check your kubeconfig.')
	}
}
