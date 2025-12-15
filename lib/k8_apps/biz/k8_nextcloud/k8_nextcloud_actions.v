module k8_nextcloud

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

	// Try to get the nextcloud deployment
	deployments := k8s.get_deployments(k8app.namespace) or {
		// If we can't get deployments, it's not running
		return false
	}

	// Check if nextcloud deployment exists
	for deployment in deployments {
		if deployment.name == 'nextcloud' {
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
	//     cmdname: 'nextcloud'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/nextcloud'
	// )!
}

fn install() ! {
	console.print_header('Installing Nextcloud...')

	// Get installer config to access namespace
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client

	// 1. Check for dependencies
	console.print_info('Checking for kubectl...')
	core.kubectl_installed(mut k8s)!
	console.print_info('kubectl is installed and configured.')

	// 2. Generate and apply TFGW YAML first
	configure_tfgw()!
	console.print_info('Applying TFGW YAML file to the cluster...')
	res_tfgw := k8s.apply_yaml(installer.tfgw_path)!
	if !res_tfgw.success {
		return error('Failed to apply tfgw.yaml: ${res_tfgw.stderr}')
	}
	console.print_info('TFGW YAML file applied successfully.')

	// 3. Get the actual FQDN from TFGW status
	fqdn := core.get_tfgw_fqdn(tfgw_name: 'nextcloud', namespace: k8app.namespace, k8s: k8s)!

	// 4. Determine OnlyOffice FQDN (will be fetched later after OnlyOffice TFGW is applied)
	// For now, generate it from the same domain pattern but with 'office' suffix
	onlyoffice_fqdn := if installer.onlyoffice_enabled {
		// Extract domain from fqdn (e.g., gent02.grid.tf from nextclouddimo.gent02.grid.tf)
		domain := fqdn.all_after_first('.')
		'${k8app.hostname}office.${domain}'
	} else {
		''
	}

	// 5. Generate remaining YAML files with the actual FQDNs
	configure_with_fqdn(fqdn, onlyoffice_fqdn)!

	// 5. Apply Secrets YAML (must be before PostgreSQL)
	console.print_info('Applying Secrets YAML file to the cluster...')
	res_secrets := k8s.apply_yaml(installer.secrets_path)!
	if !res_secrets.success {
		return error('Failed to apply secrets.yaml: ${res_secrets.stderr}')
	}
	console.print_info('Secrets YAML file applied successfully.')

	// 6. Apply PostgreSQL YAML
	console.print_info('Applying PostgreSQL YAML file to the cluster...')
	res_postgres := k8s.apply_yaml(installer.postgres_path)!
	if !res_postgres.success {
		return error('Failed to apply postgres.yaml: ${res_postgres.stderr}')
	}
	console.print_info('PostgreSQL YAML file applied successfully.')

	// 7. Verify PostgreSQL pod is ready
	verify_postgres_ready(namespace: k8app.namespace)!

	// 8. Apply Redis YAML
	console.print_info('Applying Redis YAML file to the cluster...')
	res_redis := k8s.apply_yaml(installer.redis_path)!
	if !res_redis.success {
		return error('Failed to apply redis.yaml: ${res_redis.stderr}')
	}
	console.print_info('Redis YAML file applied successfully.')

	// 9. Verify Redis deployment is ready
	verify_redis_ready(namespace: k8app.namespace)!

	// 10. Apply Nextcloud YAML
	console.print_info('Applying Nextcloud YAML file to the cluster...')
	res_nextcloud := k8s.apply_yaml(installer.nextcloud_path)!
	if !res_nextcloud.success {
		return error('Failed to apply nextcloud.yaml: ${res_nextcloud.stderr}')
	}
	console.print_info('Nextcloud YAML file applied successfully.')

	// 11. Apply OnlyOffice YAML if enabled
	if installer.onlyoffice_enabled {
		console.print_info('Applying OnlyOffice YAML file to the cluster...')
		res_onlyoffice := k8s.apply_yaml(installer.onlyoffice_path)!
		if !res_onlyoffice.success {
			return error('Failed to apply onlyoffice.yaml: ${res_onlyoffice.stderr}')
		}
		console.print_info('OnlyOffice YAML file applied successfully.')
		
		// Verify OnlyOffice deployment
		verify_onlyoffice_ready(namespace: k8app.namespace)!
	}

	// 12. Verify Nextcloud deployment is running
	console.print_info('Verifying deployment status...')
	mut is_running := false
	for i in 0 .. core.max_deployment_retries {
		if installed()! {
			is_running = true
			break
		}
		console.print_info('Waiting for Nextcloud deployment to be ready... (${i + 1}/${core.max_deployment_retries})')
		time.sleep(core.deployment_check_interval_seconds * time.second)
	}

	if !is_running {
		return error('Nextcloud deployment failed to start.')
	}

	// 13. Verify Nextcloud is fully installed using occ status
	console.print_info('Verifying Nextcloud installation status...')
	verify_nextcloud_installed(namespace: k8app.namespace)!

	// 14. Configure OnlyOffice connector in Nextcloud if enabled
	if installer.onlyoffice_enabled {
		// Get actual OnlyOffice FQDN from TFGW (it was deployed in step 11)
		actual_onlyoffice_fqdn := core.get_tfgw_fqdn(tfgw_name: 'onlyoffice', namespace: k8app.namespace, k8s: k8s)!
		
		configure_onlyoffice_connector(
			namespace:       k8app.namespace
			jwt_secret:      installer.onlyoffice_jwt_secret
			public_url:      'https://${actual_onlyoffice_fqdn}'
			internal_url:    'http://onlyoffice'
		)!
	}


	console.print_header('Nextcloud installation successful!')
	console.print_header('You can access Nextcloud at https://${fqdn}')
	console.print_info('Admin user: ${installer.admin_user}')
	console.print_info('Admin password: ${installer.admin_password}')
	if installer.onlyoffice_enabled {
		console.print_info('OnlyOffice integration: Enabled')
	}
}

// params for verifying postgres pod is ready
@[params]
struct VerifyPostgresReady {
pub mut:
	namespace string // namespace name for postgres pod
}

// Function for verifying postgres pod is ready
fn verify_postgres_ready(args VerifyPostgresReady) ! {
	console.print_info('Verifying PostgreSQL StatefulSet is ready...')
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client
	mut is_ready := false

	for i in 0 .. core.max_deployment_retries {
		// Check if postgres statefulset pod exists and is running
		result := k8s.kubectl_exec(
			command: 'get pod nextcloud-postgres-0 -n ${args.namespace} -o jsonpath="{.status.phase}"'
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

// params for verifying redis deployment is ready
@[params]
struct VerifyRedisReady {
pub mut:
	namespace string // namespace name for redis deployment
}

// Function for verifying redis deployment is ready
fn verify_redis_ready(args VerifyRedisReady) ! {
	console.print_info('Verifying Redis deployment is ready...')
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client
	mut is_ready := false

	for i in 0 .. core.max_deployment_retries {
		// Check if redis deployment exists
		deployments := k8s.get_deployments(args.namespace) or {
			console.print_info('Waiting for Redis deployment to be created... (${i + 1}/${core.max_deployment_retries})')
			time.sleep(core.deployment_check_interval_seconds * time.second)
			continue
		}

		for deployment in deployments {
			if deployment.name == 'nextcloud-redis' {
				is_ready = true
				break
			}
		}

		if is_ready {
			break
		}

		console.print_info('Waiting for Redis deployment to be ready... (${i + 1}/${core.max_deployment_retries})')
		time.sleep(core.deployment_check_interval_seconds * time.second)
	}

	if !is_ready {
		console.print_stderr('Redis deployment failed to become ready.')
		return error('Redis deployment failed to become ready.')
	}
	console.print_info('Redis deployment is ready.')
}

// params for verifying nextcloud is installed
@[params]
struct VerifyNextcloudInstalled {
pub mut:
	namespace string // namespace name for nextcloud
}

// Verify Nextcloud is fully installed using occ status
fn verify_nextcloud_installed(args VerifyNextcloudInstalled) ! {
	console.print_info('Checking Nextcloud installation status via occ...')
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client
	mut is_installed := false

	// Give Nextcloud time to initialize and install
	for i in 0 .. core.max_deployment_retries * 2 {
		// Run occ status to check installation
		result := k8s.kubectl_exec(
			command: 'exec deploy/nextcloud -n ${args.namespace} -- su -s /bin/bash www-data -c "php /var/www/html/occ status --output=json"'
		) or {
			console.print_info('Waiting for Nextcloud to initialize... (${i + 1}/${core.max_deployment_retries * 2})')
			time.sleep(core.deployment_check_interval_seconds * time.second)
			continue
		}

		if result.success && result.stdout.contains('"installed":true') {
			is_installed = true
			console.print_info('Nextcloud occ status: installed = true')
			break
		} else if result.success && result.stdout.contains('"installed":false') {
			console.print_info('Nextcloud not yet installed, waiting... (${i + 1}/${core.max_deployment_retries * 2})')
			time.sleep(core.deployment_check_interval_seconds * time.second)
		} else {
			console.print_info('Waiting for Nextcloud installation... (${i + 1}/${core.max_deployment_retries * 2})')
			time.sleep(core.deployment_check_interval_seconds * time.second)
		}
	}

	if !is_installed {
		console.print_stderr('Nextcloud installation check timed out.')
		console.print_info('Note: Nextcloud may still be installing. You can manually complete setup at the web interface.')
		console.print_info('To check manually: kubectl -n ${args.namespace} exec deploy/nextcloud -- su -s /bin/bash www-data -c "php /var/www/html/occ status"')
	} else {
		console.print_info('Nextcloud is fully installed and ready.')
	}
}

// params for verifying OnlyOffice is ready
@[params]
struct VerifyOnlyOfficeReady {
pub mut:
	namespace string
}

// Verify OnlyOffice deployment is ready
fn verify_onlyoffice_ready(args VerifyOnlyOfficeReady) ! {
	console.print_info('Verifying OnlyOffice deployment is ready...')
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client
	mut is_ready := false

	for i in 0 .. core.max_deployment_retries {
		deployments := k8s.get_deployments(args.namespace) or {
			console.print_info('Waiting for OnlyOffice deployment to be created... (${i + 1}/${core.max_deployment_retries})')
			time.sleep(core.deployment_check_interval_seconds * time.second)
			continue
		}

		for deployment in deployments {
			if deployment.name == 'onlyoffice' {
				is_ready = true
				break
			}
		}

		if is_ready {
			break
		}

		console.print_info('Waiting for OnlyOffice deployment to be ready... (${i + 1}/${core.max_deployment_retries})')
		time.sleep(core.deployment_check_interval_seconds * time.second)
	}

	if !is_ready {
		console.print_stderr('OnlyOffice deployment failed to become ready.')
		return error('OnlyOffice deployment failed to become ready.')
	}
	console.print_info('OnlyOffice deployment is ready.')
}

// params for configuring OnlyOffice connector
@[params]
struct ConfigureOnlyOfficeConnector {
pub mut:
	namespace    string
	jwt_secret   string
	public_url   string  // Public URL for browser access (https://...)
	internal_url string  // Internal URL for server-side requests (http://onlyoffice)
}

// Configure Nextcloud to connect to OnlyOffice
fn configure_onlyoffice_connector(args ConfigureOnlyOfficeConnector) ! {
	console.print_info('Configuring OnlyOffice connector in Nextcloud...')
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client

	// Install and enable OnlyOffice app
	console.print_info('Installing OnlyOffice app in Nextcloud...')
	install_result := k8s.kubectl_exec(
		command: 'exec deploy/nextcloud -n ${args.namespace} -- su -s /bin/bash www-data -c "php /var/www/html/occ app:install onlyoffice"'
	) or {
		console.print_info('OnlyOffice app may already be installed, enabling...')
		k8s.kubectl_exec(
			command: 'exec deploy/nextcloud -n ${args.namespace} -- su -s /bin/bash www-data -c "php /var/www/html/occ app:enable onlyoffice"'
		) or {
			console.print_stderr('Failed to enable OnlyOffice app.')
			return error('Failed to enable OnlyOffice app.')
		}
		return
	}

	if !install_result.success && !install_result.stdout.contains('already installed') {
		console.print_info('Enabling OnlyOffice app...')
		k8s.kubectl_exec(
			command: 'exec deploy/nextcloud -n ${args.namespace} -- su -s /bin/bash www-data -c "php /var/www/html/occ app:enable onlyoffice"'
		) or {
			console.print_stderr('Failed to enable OnlyOffice app.')
			return error('Failed to enable OnlyOffice app.')
		}
	}

	// Configure OnlyOffice public server URL (for browser access)
	console.print_info('Configuring OnlyOffice public URL: ${args.public_url}')
	k8s.kubectl_exec(
		command: 'exec deploy/nextcloud -n ${args.namespace} -- su -s /bin/bash www-data -c "php /var/www/html/occ config:app:set onlyoffice DocumentServerUrl --value=${args.public_url}"'
	) or {
		console.print_stderr('Failed to configure OnlyOffice server URL.')
		return error('Failed to configure OnlyOffice server URL.')
	}

	// Configure OnlyOffice internal URL (for server-side requests from Nextcloud to OnlyOffice)
	console.print_info('Configuring OnlyOffice internal URL: ${args.internal_url}')
	k8s.kubectl_exec(
		command: 'exec deploy/nextcloud -n ${args.namespace} -- su -s /bin/bash www-data -c "php /var/www/html/occ config:app:set onlyoffice DocumentServerInternalUrl --value=${args.internal_url}/"'
	) or {
		console.print_stderr('Failed to configure OnlyOffice internal URL.')
		return error('Failed to configure OnlyOffice internal URL.')
	}

	// Configure Storage URL for OnlyOffice → Nextcloud internal requests
	console.print_info('Configuring OnlyOffice StorageUrl (Nextcloud internal): http://nextcloud-web/')
	k8s.kubectl_exec(
		command: 'exec deploy/nextcloud -n ${args.namespace} -- su -s /bin/bash www-data -c "php /var/www/html/occ config:app:set onlyoffice StorageUrl --value=http://nextcloud-web/"'
	) or {
		console.print_stderr('Failed to configure OnlyOffice StorageUrl.')
		return error('Failed to configure OnlyOffice StorageUrl.')
	}

	// Configure JWT secret
	console.print_info('Configuring OnlyOffice JWT secret...')
	k8s.kubectl_exec(
		command: 'exec deploy/nextcloud -n ${args.namespace} -- su -s /bin/bash www-data -c "php /var/www/html/occ config:app:set onlyoffice jwt_secret --value=${args.jwt_secret}"'
	) or {
		console.print_stderr('Failed to configure OnlyOffice JWT secret.')
		return error('Failed to configure OnlyOffice JWT secret.')
	}

	// Configure JWT header (must match ONLYOFFICE env JWT_HEADER)
	console.print_info('Configuring OnlyOffice JWT header: Authorization')
	k8s.kubectl_exec(
		command: 'exec deploy/nextcloud -n ${args.namespace} -- su -s /bin/bash www-data -c "php /var/www/html/occ config:app:set onlyoffice jwt_header --value=Authorization"'
	) or {
		console.print_stderr('Failed to configure OnlyOffice JWT header.')
		return error('Failed to configure OnlyOffice JWT header.')
	}

	console.print_info('OnlyOffice connector configured successfully.')
	console.print_info('  Public URL (browsers): ${args.public_url}')
	console.print_info('  Internal URL (NC→OO): ${args.internal_url}')
	console.print_info('  Storage URL (OO→NC): http://nextcloud-web/')
}


fn destroy() ! {
	installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client
	
	core.destroy_namespace(mut k8s, k8app.namespace)!
}
