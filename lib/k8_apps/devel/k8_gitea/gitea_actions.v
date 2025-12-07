module k8_gitea

import incubaid.herolib.ui.console
import incubaid.herolib.installers.ulist
import incubaid.herolib.k8_apps.core
import time

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
	core.kubectl_installed(mut k8s)!
	console.print_info('kubectl is installed and configured.')

	// 2. Apply the YAML files using kubernetes client
	console.print_info('Applying Gateway YAML file to the cluster...')
	res1 := k8s.apply_yaml(installer.tfgw_path)!
	if !res1.success {
		return error('Failed to apply tfgw-gitea.yaml: ${res1.stderr}')
	}
	console.print_info('Gateway YAML file applied successfully.')

	// 3. Verify TFGW deployment
	core.verify_tfgw_deployment(tfgw_name: 'gitea', namespace: installer.namespace, k8s: k8s)!

	// 4. Apply PostgreSQL YAML if postgres is selected
	if installer.db_type == 'postgres' {
		console.print_info('Applying PostgreSQL YAML file to the cluster...')
		res_postgres := k8s.apply_yaml(installer.postgres_path)!
		if !res_postgres.success {
			return error('Failed to apply postgres.yaml: ${res_postgres.stderr}')
		}
		console.print_info('PostgreSQL YAML file applied successfully.')

		// Verify PostgreSQL pod is ready
		verify_postgres_pod(namespace: installer.namespace)!
	}

	// 5. Apply Gitea App YAML
	console.print_info('Applying Gitea App YAML file to the cluster...')
	res2 := k8s.apply_yaml(installer.gitea_app_path)!
	if !res2.success {
		return error('Failed to apply gitea.yaml: ${res2.stderr}')
	}
	console.print_info('Gitea App YAML file applied successfully.')

	// 6. Verify deployment status
	console.print_info('Verifying deployment status...')
	mut is_running := false
	for i in 0 .. core.max_deployment_retries {
		if installed()! {
			is_running = true
			break
		}
		console.print_info('Waiting for Gitea deployment to be ready... (${i + 1}/${core.max_deployment_retries})')
		time.sleep(core.deployment_check_interval_seconds * time.second)
	}

	if is_running {
		console.print_header('Gitea installation successful!')
		console.print_header('You can access Gitea at https://${installer.hostname}.gent01.grid.tf')
	} else {
		return error('Gitea deployment failed to start.')
	}
}

// params for verifying postgres pod is ready
@[params]
struct VerifyPostgresPod {
pub mut:
	namespace string // namespace name for postgres pod
}

// Function for verifying postgres pod is ready
fn verify_postgres_pod(args VerifyPostgresPod) ! {
	console.print_info('Verifying PostgreSQL pod is ready...')
	installer := get()!
	mut k8s := installer.kube_client
	mut is_ready := false

	for i in 0 .. core.max_deployment_retries {
		// Check if postgres pod exists and is running
		result := k8s.kubectl_exec(
			command: 'get pod ${installer.db_host} -n ${args.namespace} -o jsonpath="{.status.phase}"'
		) or {
			console.print_info('Waiting for PostgreSQL pod to be created... (${i + 1}/${core.max_deployment_retries})')
			time.sleep(core.deployment_check_interval_seconds * time.second)
			continue
		}

		if result.success && result.stdout == 'Running' {
			is_ready = true
			break
		}
		console.print_info('Waiting for PostgreSQL pod to be ready... (${i + 1}/${core.max_deployment_retries})')
		time.sleep(core.deployment_check_interval_seconds * time.second)
	}

	if !is_ready {
		console.print_stderr('PostgreSQL pod failed to become ready.')
		return error('PostgreSQL pod failed to become ready.')
	}
	console.print_info('PostgreSQL pod is ready.')
}

fn destroy() ! {
	installer := get()!
	mut k8s := installer.kube_client
	
	core.destroy_namespace(mut k8s, installer.namespace)!
}
