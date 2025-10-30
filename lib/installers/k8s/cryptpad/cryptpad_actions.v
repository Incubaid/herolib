module cryptpad

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.installers.ulist
import incubaid.herolib.virt.kubernetes
import os
import strings
import time

const max_deployment_retries = 30
const deployment_check_interval_seconds = 2

fn startupcmd() ![]startupmanager.ZProcessNewArgs {
	// We don't have a long-running process to manage with startupmanager for this installer,
	// but we'll keep the function for consistency.
	return []startupmanager.ZProcessNewArgs{}
}

fn kubectl_installed() ! {
	// Check if kubectl command exists
	if !osal.cmd_exists('kubectl') {
		return error('kubectl is not installed. Please install it to continue.')
	}

	// Check if kubectl is configured to connect to a cluster
	mut k8s := kubernetes.get()!
	if !k8s.test_connection()! {
		return error('kubectl is not configured to connect to a Kubernetes cluster. Please check your kubeconfig.')
	}
}

fn running() !bool {
	installer := get()!
	mut k8s := kubernetes.get()!

	// Try to get the cryptpad deployment
	deployments := k8s.get_deployments(installer.namespace) or {
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

fn start_pre() ! {
}

fn start_post() ! {
}

fn stop_pre() ! {
}

fn stop_post() ! {
}

//////////////////// following actions are not specific to instance of the object

// checks if a certain version or above is installed
fn installed() !bool {
	return running()
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	return ulist.UList{}
}

fn upload() ! {
	// Not needed for this installer.
}

fn get_master_node_ips() ![]string {
	mut master_ips := []string{}
	mut k8s := kubernetes.get()!

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

struct ConfigValues {
pub mut:
	hostname  string
	backends  string
	namespace string
}

fn install() ! {
	console.print_header('Installing CryptPad...')

	// Get installer config to access namespace
	installer := get()!
	if installer.hostname == '' {
		return error('hostname is empty')
	}

	// Configure kubernetes client with the correct namespace
	mut k8s := kubernetes.get()!
	k8s.config.namespace = installer.namespace

	// 1. Check for dependencies.
	console.print_info('Checking for kubectl...')
	kubectl_installed()!
	console.print_info('kubectl is installed and configured.')

	// 2. Get Kubernetes master node IPs.
	console.print_info('Getting Kubernetes master node IPs...')
	master_ips := get_master_node_ips()!
	console.print_info('Master node IPs: ${master_ips}')

	// 3. Generate YAML files from templates.
	console.print_info('Generating YAML files from templates...')

	mut backends_str_builder := strings.new_builder(100)
	for ip in master_ips {
		backends_str_builder.writeln('    - "http://[${ip}]:80"')
	}
	config_values := ConfigValues{
		hostname:  installer.hostname
		backends:  backends_str_builder.str()
		namespace: installer.namespace
	}

	// Write to tfgw file
	temp := $tmpl('./templates/tfgw-cryptpad.yaml')
	os.write_file('/tmp/tfgw-cryptpad.yaml', temp)!

	// write to cryptpad yaml file
	temp2 := $tmpl('./templates/cryptpad.yaml')
	os.write_file('/tmp/cryptpad.yaml', temp2)!
	console.print_info('YAML files generated successfully.')

	// 4. Apply the YAML files using kubernetes client
	console.print_info('Applying Gateway YAML file to the cluster...')
	res1 := k8s.apply_yaml('/tmp/tfgw-cryptpad.yaml')!
	if !res1.success {
		return error('Failed to apply tfgw-cryptpad.yaml: ${res1.stderr}')
	}
	console.print_info('Gateway YAML file applied successfully.')

	// 5. Verify TFGW deployments
	verify_tfgw_deployment(tfgw_name: 'cryptpad-main', namespace: installer.namespace)!
	verify_tfgw_deployment(tfgw_name: 'cryptpad-sandbox', namespace: installer.namespace)!

	// 6. Apply Cryptpad YAML
	console.print_info('Applying Cryptpad YAML file to the cluster...')
	res2 := k8s.apply_yaml('/tmp/cryptpad.yaml')!
	if !res2.success {
		return error('Failed to apply cryptpad.yaml: ${res2.stderr}')
	}
	console.print_info('Cryptpad YAML file applied successfully.')

	// 7. Verify deployment status
	console.print_info('Verifying deployment status...')
	mut is_running := false
	for i in 0 .. max_deployment_retries {
		if running()! {
			is_running = true
			break
		}
		console.print_info('Waiting for CryptPad deployment to be ready... (${i + 1}/${max_deployment_retries})')
		time.sleep(deployment_check_interval_seconds * time.second)
	}

	if is_running {
		console.print_header('CryptPad installation successful!')
	} else {
		return error('CryptPad deployment failed to start.')
	}
}

// params for verifying the generating of the FQDN using tfgw crd
@[params]
struct VerifyTfgwDeployment {
pub mut:
	tfgw_name string // tfgw serivce generating the FQDN
	namespace string // namespace name for cryptpad deployments/services
	retry     int = 30
}

//  Function for verifying the generating of of the FQDN using tfgw crd
fn verify_tfgw_deployment(args VerifyTfgwDeployment) ! {
	console.print_info('Verifying TFGW deployment for ${args.tfgw_name}...')
	mut k8s := kubernetes.get()!
	mut is_fqdn_generated := false

	for i in 0 .. args.retry {
		// Use kubectl_exec for custom resource (TFGW) with jsonpath
		result := k8s.kubectl_exec(
			command: 'get tfgw ${args.tfgw_name} -n ${args.namespace} -o jsonpath="{.status.fqdn}"'
		) or {
			console.print_info('Waiting for FQDN to be generated for ${args.tfgw_name}... (${i + 1}/${args.retry})')
			time.sleep(2 * time.second)
			continue
		}

		if result.success && result.stdout != '' {
			is_fqdn_generated = true
			break
		}
		console.print_info('Waiting for FQDN to be generated for ${args.tfgw_name}... (${i + 1}/${args.retry})')
		time.sleep(2 * time.second)
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
	console.print_header('Destroying CryptPad...')
	installer := get()!
	mut k8s := kubernetes.get()!

	// Delete the namespace using kubernetes client
	result := k8s.delete_resource('namespace', installer.namespace, '') or {
		console.print_stderr('Failed to delete namespace ${installer.namespace}: ${err}')
		return
	}

	if !result.success {
		console.print_stderr('Failed to delete namespace ${installer.namespace}: ${result.stderr}')
	} else {
		console.print_info('Namespace ${installer.namespace} deleted.')
	}
}
