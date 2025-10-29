module kubernetes

import incubaid.herolib.osal.core as osal
import incubaid.herolib.core.httpconnection
import incubaid.herolib.core.pathlib
import incubaid.herolib.ui.console
import json
import os

// Execute kubectl command with proper error handling
pub fn (mut k KubeClient) kubectl_exec(args KubectlExecArgs) !KubectlResult {
	mut cmd := 'kubectl'

	if k.config.namespace.len > 0 {
		cmd += '--namespace=${k.config.namespace} '
	}

	if k.kubeconfig_path.len > 0 {
		cmd += '--kubeconfig=${k.kubeconfig_path} '
	}

	if k.config.context.len > 0 {
		cmd += '--context=${k.config.context} '
	}

	cmd += args.command

	console.print_debug('executing: ${cmd}')

	job := osal.exec(
		cmd:         cmd
		timeout:     args.timeout
		retry:       args.retry
		raise_error: false
	)!

	return KubectlResult{
		exit_code: job.exit_code
		stdout:    job.output
		stderr:    job.error
		success:   job.exit_code == 0
	}
}

@[params]
pub struct KubectlExecArgs {
pub mut:
	command string
	timeout int = 30
	retry   int = 0
}

pub struct KubectlResult {
pub mut:
	exit_code int
	stdout    string
	stderr    string
	success   bool
}

// Test connection to cluster
pub fn (mut k KubeClient) test_connection() !bool {
	result := k.kubectl_exec(command: 'cluster-info')!
	if result.success {
		k.connected = true
		return true
	}
	return false
}

// Get cluster info
pub fn (mut k KubeClient) cluster_info() !ClusterInfo {
	// Get API server version
	result := k.kubectl_exec(command: 'version -o json')!
	if !result.success {
		return error('Failed to get cluster version: ${result.stderr}')
	}

	println(result.stdout)

	$dbg;
	// version_data := json.decode(map[string]interface{}, result.stdout)!
	// server_version := version_data['serverVersion'] or { return error('No serverVersion') }

	// // Get node count
	// nodes_result := k.kubectl_exec(command: 'get nodes -o json')!
	// nodes_count := if nodes_result.success {
	// 	nodes_data := json.decode(map[string]interface{}, nodes_result.stdout)!
	// 	items := nodes_data['items'] or { []interface{}{} }
	// 	items.len
	// } else {
	// 	0
	// }

	// // Get namespace count
	// ns_result := k.kubectl_exec(command: 'get namespaces -o json')!
	// ns_count := if ns_result.success {
	// 	ns_data := json.decode(map[string]interface{}, ns_result.stdout)!
	// 	items := ns_data['items'] or { []interface{}{} }
	// 	items.len
	// } else {
	// 	0
	// }

	// // Get running pods count
	// pods_result := k.kubectl_exec(command: 'get pods --all-namespaces -o json')!
	// pods_count := if pods_result.success {
	// 	pods_data := json.decode(map[string]interface{}, pods_result.stdout)!
	// 	items := pods_data['items'] or { []interface{}{} }
	// 	items.len
	// } else {
	// 	0
	// }

	// return ClusterInfo{
	// 	version: 'v1.0.0'
	// 	nodes: nodes_count
	// 	namespaces: ns_count
	// 	running_pods: pods_count
	// 	api_server: k.config.api_server
	// }
	return ClusterInfo{}
}

// Get resources (Pods, Deployments, Services, etc.)
pub fn (mut k KubeClient) get_pods(namespace string) ! {
	result := k.kubectl_exec(command: 'get pods -n ${namespace} -o json')!
	if !result.success {
		return error('Failed to get pods: ${result.stderr}')
	}

	println(result.stdout)
	$dbg;
	// data := json.decode(map[string]interface{}, result.stdout)!
	// items := data['items'] or { []interface{}{} }
	// return items as []map[string]interface{}

	panic('Not implemented')
}

pub fn (mut k KubeClient) get_deployments(namespace string) ! {
	result := k.kubectl_exec(command: 'get deployments -n ${namespace} -o json')!
	if !result.success {
		return error('Failed to get deployments: ${result.stderr}')
	}

	// data := json.decode(map[string]interface{}, result.stdout)!
	// items := data['items'] or { []interface{}{} }
	// return items as []map[string]interface{}
	panic('Not implemented')
}

pub fn (mut k KubeClient) get_services(namespace string) ! {
	result := k.kubectl_exec(command: 'get services -n ${namespace} -o json')!
	if !result.success {
		return error('Failed to get services: ${result.stderr}')
	}

	// data := json.decode(map[string]interface{}, result.stdout)!
	// items := data['items'] or { []interface{}{} }
	// return items as []map[string]interface{}
	panic('Not implemented')
}

// Apply YAML file
pub fn (mut k KubeClient) apply_yaml(yaml_path string) !KubectlResult {
	// Validate before applying
	validation := yaml_validate(yaml_path)!
	if !validation.valid {
		return error('YAML validation failed: ${validation.errors.join(', ')}')
	}

	result := k.kubectl_exec(command: 'apply -f ${yaml_path}')!
	if result.success {
		console.print_green('Applied: ${validation.kind}/${validation.metadata.name}')
	}
	return result
}

// Delete resource
pub fn (mut k KubeClient) delete_resource(kind string, name string, namespace string) !KubectlResult {
	result := k.kubectl_exec(command: 'delete ${kind} ${name} -n ${namespace}')!
	return result
}

// Describe resource
pub fn (mut k KubeClient) describe_resource(kind string, name string, namespace string) !string {
	result := k.kubectl_exec(command: 'describe ${kind} ${name} -n ${namespace}')!
	if !result.success {
		return error('Failed to describe resource: ${result.stderr}')
	}
	return result.stdout
}

// Port forward
pub fn (mut k KubeClient) port_forward(pod_name string, local_port int, remote_port int, namespace string) !string {
	cmd := 'port-forward ${pod_name} ${local_port}:${remote_port} -n ${namespace}'
	result := k.kubectl_exec(command: cmd, timeout: 300)!
	return result.stdout
}

// Get logs
pub fn (mut k KubeClient) logs(pod_name string, namespace string, follow bool) !string {
	mut cmd := 'logs ${pod_name} -n ${namespace}'
	if follow {
		cmd += ' -f'
	}
	result := k.kubectl_exec(command: cmd, timeout: 300)!
	if !result.success {
		return error('Failed to get logs: ${result.stderr}')
	}
	return result.stdout
}

// Exec into container
pub fn (mut k KubeClient) exec_pod(pod_name string, namespace string, container string, cmd_args []string) !string {
	mut cmd := 'exec -it ${pod_name} -n ${namespace}'
	if container.len > 0 {
		cmd += ' -c ${container}'
	}
	cmd += ' -- ${cmd_args.join(' ')}'

	result := k.kubectl_exec(command: cmd, timeout: 300)!
	if !result.success {
		return error('Exec failed: ${result.stderr}')
	}
	return result.stdout
}

// Create namespace
pub fn (mut k KubeClient) create_namespace(namespace_name string) !KubectlResult {
	result := k.kubectl_exec(command: 'create namespace ${namespace_name}')!
	return result
}

// Watch resources (returns status)
pub fn (mut k KubeClient) watch_deployment(name string, namespace string, timeout_seconds int) !bool {
	cmd := 'rollout status deployment/${name} -n ${namespace} --timeout=${timeout_seconds}s'
	result := k.kubectl_exec(command: cmd, timeout: timeout_seconds + 10)!
	return result.success
}
