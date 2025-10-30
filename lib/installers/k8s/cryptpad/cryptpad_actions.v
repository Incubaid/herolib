module cryptpad

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import incubaid.herolib.core
import incubaid.herolib.osal.startupmanager
import incubaid.herolib.installers.ulist
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
	if !osal.cmd_exists('kubectl') {
		return error('kubectl is not installed. Please install it to continue.')
	}
	// Check if kubectl is configured to connect to a cluster
	res := osal.exec(cmd: 'kubectl cluster-info', ignore_error: true)!
	if res.exit_code != 0 {
		return error('kubectl is not configured to connect to a Kubernetes cluster. Please check your kubeconfig.')
	}
}

fn running() !bool {
	installer := get()!
	res := osal.exec(
		cmd:          'kubectl get deployment cryptpad -n ${installer.namespace}'
		ignore_error: true
	)!
	return res.exit_code == 0
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
	res := osal.exec(
		cmd: 'kubectl get nodes -o jsonpath="{.items[*].status.addresses[?(@.type==\'InternalIP\')].address}" | tr \' \' \'\\n\' | grep \':\''
	)!
	if res.exit_code != 0 {
		return error('Failed to get master node IPs: ${res.output}')
	}
	for ip in res.output.split('\n') {
		if ip.len > 0 {
			master_ips << ip
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
	installer := get()!
	if installer.hostname == '' {
		return error('hostname is empty')
	}

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

	// 4. Apply the YAML files using `kubectl`.
	console.print_info('Applying Gateway YAML file to the cluster...')
	res1 := osal.exec(cmd: 'kubectl apply -f /tmp/tfgw-cryptpad.yaml')!
	if res1.exit_code != 0 {
		return error('Failed to apply tfgw-cryptpad.yaml: ${res1.output}')
	}
	console.print_info('Gateway YAML file applied successfully.')

	// 5. Verify TFGW deployments
	verify_tfgw_deployment(tfgw_name: 'cryptpad-main', namespace: installer.namespace)!
	verify_tfgw_deployment(tfgw_name: 'cryptpad-sandbox', namespace: installer.namespace)!

	// 6. Apply Cryptpad YAML
	console.print_info('Applying Cryptpad YAML file to the cluster...')
	res2 := osal.exec(cmd: 'kubectl apply -f /tmp/cryptpad.yaml')!
	if res2.exit_code != 0 {
		return error('Failed to apply cryptpad.yaml: ${res2.output}')
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
}

//  Function for verifying the generating of of the FQDN using tfgw crd
fn verify_tfgw_deployment(args VerifyTfgwDeployment) ! {
	console.print_info('Verifying TFGW deployment for ${args.tfgw_name}...')
	mut is_fqdn_generated := false
	for i in 0 .. max_deployment_retries {
		res := osal.exec(
			cmd:          'kubectl get tfgw ${args.tfgw_name} -n ${args.namespace} -o jsonpath="{.status.fqdn}"'
			ignore_error: true
		)!
		if res.exit_code == 0 && res.output != '' {
			is_fqdn_generated = true
			break
		}
		console.print_info('Waiting for FQDN to be generated for ${args.tfgw_name}... (${i + 1}/${max_deployment_retries})')
		time.sleep(deployment_check_interval_seconds * time.second)
	}

	if !is_fqdn_generated {
		console.print_stderr('Failed to get FQDN for ${args.tfgw_name}.')
		res := osal.exec(
			cmd:          'kubectl describe tfgw ${args.tfgw_name} -n ${args.namespace}'
			ignore_error: true
		)!
		console.print_stderr(res.output)
		return error('TFGW deployment failed for ${args.tfgw_name}.')
	}
	console.print_info('TFGW deployment for ${args.tfgw_name} verified successfully.')
}

fn destroy() ! {
	console.print_header('Destroying CryptPad...')
	installer := get()!
	res := osal.exec(cmd: 'kubectl delete ns ${installer.namespace}', ignore_error: true)!
	if res.exit_code != 0 {
		console.print_stderr('Failed to delete namespace ${installer.namespace}: ${res.output}')
	} else {
		console.print_info('Namespace ${installer.namespace} deleted.')
	}
}
