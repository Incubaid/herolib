module core

import incubaid.herolib.virt.kubernetes
import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import time

// Common constants for deployment verification
pub const max_deployment_retries = 30
pub const deployment_check_interval_seconds = 2

pub struct K8App {
pub mut:
	kube_client kubernetes.KubeClient @[skip]
	namespace string
	hostname  string
	app_name string
	app_instance string
}

@[params]
pub struct K8AppArgs {
pub mut:
	namespace string = "default" //namespace where deployed
	app_instance string @[required]
	app_name string @[required] //e.g. cryptpad, nextcloud, etc
}

// Validate and truncate hostname to meet TFGW 36-character limit
// TFGW gateway names cannot exceed 36 characters
// We reserve 4 characters for potential suffixes added by templates (e.g., "sb" for sandbox)
pub fn validate_hostname(hostname string) string {
	max_length := 32  // Reserve 4 chars for suffixes like "sb", "-main", etc.
	if hostname.len <= max_length {
		return hostname
	}
	// Truncate to max length
	truncated := hostname[..max_length]
	console.print_debug('Hostname "${hostname}" (${hostname.len} chars) truncated to "${truncated}" (${max_length} chars) to meet TFGW limit (36 chars with suffixes)')
	return truncated
}

//get a k8 app instance as to be used in installers
pub fn k8app(args_ K8AppArgs)!K8App {
	mut args := args_

	args.namespace = name_fix(args.namespace) //im place we deployed
	args.app_name = name_fix(args.app_name)
	args.app_instance = name_fix(args.app_instance)

	mut kube_client := kubernetes.get(create: true)!
	kube_client.config.namespace = args.namespace

	// Generate hostname and validate it doesn't exceed TFGW limit
	// TFGW hostnames must be alphanumeric only (no dashes or underscores)
	raw_hostname := texttools.name_fix("${args.app_name}${args.app_instance}").replace('_', '').replace('-', '')
	validated_hostname := validate_hostname(raw_hostname)

	mut app := K8App{
		namespace: args.namespace
		hostname:  validated_hostname
		app_name: args.app_name
		app_instance: args.app_instance
		kube_client: kube_client
	}
	
	return app
}

// Get Kubernetes master node IPs (IPv6)
// Extracts IPv6 internal IPs from all k8s nodes for backend configuration
pub fn get_master_node_ips(mut k8s kubernetes.KubeClient) ![]string {
	mut master_ips := []string{}

	// Get all nodes using the kubernetes client
	nodes := k8s.get_nodes()!

	// Extract IPv6 internal IPs from all nodes (dual-stack support)
	for node in nodes {
		// Check all internal IPs (not just the first one) for IPv6 addresses
		for ip in node.internal_ips {
			if ip.len > 0 && ip.contains(':') {
				master_ips << ip
			}
		}
	}
	return master_ips
}

// Parameters for verifying TFGW deployment
@[params]
pub struct VerifyTfgwArgs {
pub mut:
	tfgw_name string @[required] // tfgw service generating the FQDN
	namespace string @[required] // namespace name for deployments/services
	k8s       kubernetes.KubeClient @[required]
	retry     int = max_deployment_retries
}

// Verify TFGW deployment FQDN generation
// Checks if TFGW custom resource has generated an FQDN with retry logic
pub fn verify_tfgw_deployment(args VerifyTfgwArgs) ! {
	console.print_info('Verifying TFGW deployment for ${args.tfgw_name}...')
	mut k8s := args.k8s
	mut is_fqdn_generated := false

	for i in 0 .. args.retry {
		// Use kubectl_exec for custom resource (TFGW) with jsonpath
		result := k8s.kubectl_exec(
			command: 'get tfgw ${args.tfgw_name} -n ${args.namespace} -o jsonpath="{.status.fqdn}"'
		) or {
			console.print_info('Waiting for FQDN to be generated for ${args.tfgw_name}... (${i + 1}/${args.retry})')
			time.sleep(deployment_check_interval_seconds * time.second)
			continue
		}

		if result.success && result.stdout != '' {
			is_fqdn_generated = true
			break
		}
		console.print_info('Waiting for FQDN to be generated for ${args.tfgw_name}... (${i + 1}/${args.retry})')
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

// Check if kubectl is installed and configured
pub fn kubectl_installed(mut k8s kubernetes.KubeClient) ! {
	// Check if kubectl command exists
	if !osal.cmd_exists('kubectl') {
		return error('kubectl is not installed. Please install it to continue.')
	}

	// Check if kubectl is configured to connect to a cluster
	if !k8s.test_connection()! {
		return error('kubectl is not configured to connect to a Kubernetes cluster. Please check your kubeconfig.')
	}
}

// Destroy namespace with proper error handling
pub fn destroy_namespace(mut k8s kubernetes.KubeClient, namespace string) ! {
	console.print_header('Destroying namespace ${namespace}...')
	console.print_debug('Attempting to delete namespace: ${namespace}')

	// Delete the namespace using kubernetes client
	result := k8s.delete_resource('namespace', namespace, '') or {
		console.print_stderr('Failed to delete namespace ${namespace}: ${err}')
		return error('Failed to delete namespace ${namespace}: ${err}')
	}

	console.print_debug('Delete command completed. Exit code: ${result.exit_code}, Success: ${result.success}')

	if !result.success {
		// Namespace not found is OK - it means it's already deleted
		if result.stderr.contains('NotFound') {
			console.print_info('Namespace ${namespace} does not exist (already deleted).')
		} else {
			console.print_stderr('Failed to delete namespace ${namespace}: ${result.stderr}')
			return error('Failed to delete namespace ${namespace}: ${result.stderr}')
		}
	} else {
		console.print_info('Namespace ${namespace} deleted successfully.')
	}
}

// Parameters for verifying deployment readiness
@[params]
pub struct VerifyDeploymentArgs {
pub mut:
	deployment_name string @[required] // name of the deployment to check
	namespace       string @[required] // namespace where deployment is located
	k8s             kubernetes.KubeClient @[required]
	retry           int = max_deployment_retries
}

// Verify deployment is ready with retry logic
pub fn verify_deployment_ready(args VerifyDeploymentArgs) !bool {
	mut k8s := args.k8s
	
	for i in 0 .. args.retry {
		// Try to get the deployment
		deployments := k8s.get_deployments(args.namespace) or {
			console.print_info('Waiting for deployment ${args.deployment_name} to be ready... (${i + 1}/${args.retry})')
			time.sleep(deployment_check_interval_seconds * time.second)
			continue
		}

		// Check if deployment exists
		for deployment in deployments {
			if deployment.name == args.deployment_name {
				return true
			}
		}
		
		console.print_info('Waiting for deployment ${args.deployment_name} to be ready... (${i + 1}/${args.retry})')
		time.sleep(deployment_check_interval_seconds * time.second)
	}

	return false
}

// Parameters for verifying pod readiness
@[params]
pub struct VerifyPodArgs {
pub mut:
	pod_name  string @[required] // name of the pod to check
	namespace string @[required] // namespace where pod is located
	k8s       kubernetes.KubeClient @[required]
	retry     int = max_deployment_retries
}

// Verify pod is ready with retry logic
// Checks if a pod exists and is in Running phase
pub fn verify_pod_ready(args VerifyPodArgs) ! {
	console.print_info('Verifying pod ${args.pod_name} is ready...')
	mut k8s := args.k8s
	mut is_ready := false

	for i in 0 .. args.retry {
		// Check if pod exists and is running
		result := k8s.kubectl_exec(
			command: 'get pod ${args.pod_name} -n ${args.namespace} -o jsonpath="{.status.phase}"'
		) or {
			console.print_info('Waiting for pod ${args.pod_name} to be created... (${i + 1}/${args.retry})')
			time.sleep(deployment_check_interval_seconds * time.second)
			continue
		}

		if result.success && result.stdout == 'Running' {
			is_ready = true
			break
		}
		console.print_info('Waiting for pod ${args.pod_name} to be ready... (${i + 1}/${args.retry})')
		time.sleep(deployment_check_interval_seconds * time.second)
	}

	if !is_ready {
		console.print_stderr('Pod ${args.pod_name} failed to become ready.')
		return error('Pod ${args.pod_name} failed to become ready.')
	}
	console.print_info('Pod ${args.pod_name} is ready.')
}