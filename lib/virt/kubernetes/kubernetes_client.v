module kubernetes

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import json

@[params]
pub struct KubectlExecArgs {
pub mut:
	command string
	timeout int = 30
	retry   int
}

pub struct KubectlResult {
pub mut:
	exit_code int
	stdout    string
	stderr    string
	success   bool
}

// Execute kubectl command with proper error handling
pub fn (mut k KubeClient) kubectl_exec(args KubectlExecArgs) !KubectlResult {
	mut cmd := 'kubectl'

	if k.config.namespace.len > 0 {
		cmd += ' --namespace=${k.config.namespace}'
	}

	if k.kubeconfig_path.len > 0 {
		cmd += ' --kubeconfig=${k.kubeconfig_path}'
	}

	if k.config.context.len > 0 {
		cmd += ' --context=${k.config.context}'
	}

	cmd += ' ${args.command}'

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

	// Parse version JSON using struct-based decoding
	mut version_str := 'unknown'
	version_response := json.decode(KubectlVersionResponse, result.stdout) or {
		console.print_debug('Failed to parse version JSON: ${err}')
		KubectlVersionResponse{}
	}
	if version_response.server_version.git_version.len > 0 {
		version_str = version_response.server_version.git_version
	}

	// Get node count
	nodes_result := k.kubectl_exec(command: 'get nodes -o json')!
	mut nodes_count := 0
	if nodes_result.success {
		nodes_list := json.decode(KubectlListResponse, nodes_result.stdout) or {
			console.print_debug('Failed to parse nodes JSON: ${err}')
			KubectlListResponse{}
		}
		nodes_count = nodes_list.items.len
	}

	// Get namespace count
	ns_result := k.kubectl_exec(command: 'get namespaces -o json')!
	mut ns_count := 0
	if ns_result.success {
		ns_list := json.decode(KubectlListResponse, ns_result.stdout) or {
			console.print_debug('Failed to parse namespaces JSON: ${err}')
			KubectlListResponse{}
		}
		ns_count = ns_list.items.len
	}

	// Get running pods count
	pods_result := k.kubectl_exec(command: 'get pods --all-namespaces -o json')!
	mut pods_count := 0
	if pods_result.success {
		pods_list := json.decode(KubectlListResponse, pods_result.stdout) or {
			console.print_debug('Failed to parse pods JSON: ${err}')
			KubectlListResponse{}
		}
		pods_count = pods_list.items.len
	}

	return ClusterInfo{
		version:      version_str
		nodes:        nodes_count
		namespaces:   ns_count
		running_pods: pods_count
		api_server:   k.config.api_server
	}
}

// Get resources (Pods, Deployments, Services, etc.)
pub fn (mut k KubeClient) get_pods(namespace string) ![]Pod {
	result := k.kubectl_exec(command: 'get pods -n ${namespace} -o json')!
	if !result.success {
		return error('Failed to get pods: ${result.stderr}')
	}

	// Parse JSON response using struct-based decoding
	pod_list := json.decode(KubectlPodListResponse, result.stdout) or {
		return error('Failed to parse pods JSON: ${err}')
	}

	mut pods := []Pod{}

	for item in pod_list.items {
		// Extract container names
		mut container_names := []string{}
		for container in item.spec.containers {
			container_names << container.name
		}

		// Create Pod struct from kubectl response
		pod := Pod{
			name:       item.metadata.name
			namespace:  item.metadata.namespace
			status:     item.status.phase
			node:       item.spec.node_name
			ip:         item.status.pod_ip
			containers: container_names
			labels:     item.metadata.labels
			created_at: item.metadata.creation_timestamp
		}

		pods << pod
	}

	return pods
}

pub fn (mut k KubeClient) get_deployments(namespace string) ![]Deployment {
	result := k.kubectl_exec(command: 'get deployments -n ${namespace} -o json')!
	if !result.success {
		return error('Failed to get deployments: ${result.stderr}')
	}

	// Parse JSON response using struct-based decoding
	deployment_list := json.decode(KubectlDeploymentListResponse, result.stdout) or {
		return error('Failed to parse deployments JSON: ${err}')
	}

	mut deployments := []Deployment{}

	for item in deployment_list.items {
		// Create Deployment struct from kubectl response
		deployment := Deployment{
			name:               item.metadata.name
			namespace:          item.metadata.namespace
			replicas:           item.spec.replicas
			ready_replicas:     item.status.ready_replicas
			available_replicas: item.status.available_replicas
			updated_replicas:   item.status.updated_replicas
			labels:             item.metadata.labels
			created_at:         item.metadata.creation_timestamp
		}

		deployments << deployment
	}

	return deployments
}

pub fn (mut k KubeClient) get_services(namespace string) ![]Service {
	result := k.kubectl_exec(command: 'get services -n ${namespace} -o json')!
	if !result.success {
		return error('Failed to get services: ${result.stderr}')
	}

	// Parse JSON response using struct-based decoding
	service_list := json.decode(KubectlServiceListResponse, result.stdout) or {
		return error('Failed to parse services JSON: ${err}')
	}

	mut services := []Service{}

	for item in service_list.items {
		// Build port strings (e.g., "80/TCP", "443/TCP")
		mut port_strings := []string{}
		for port in item.spec.ports {
			port_strings << '${port.port}/${port.protocol}'
		}

		// Get external IP from LoadBalancer status if available
		mut external_ip := ''
		if item.status.load_balancer.ingress.len > 0 {
			external_ip = item.status.load_balancer.ingress[0].ip
		}
		// Also check spec.external_ips
		if external_ip.len == 0 && item.spec.external_ips.len > 0 {
			external_ip = item.spec.external_ips[0]
		}

		// Create Service struct from kubectl response
		service := Service{
			name:         item.metadata.name
			namespace:    item.metadata.namespace
			service_type: item.spec.service_type
			cluster_ip:   item.spec.cluster_ip
			external_ip:  external_ip
			ports:        port_strings
			labels:       item.metadata.labels
			created_at:   item.metadata.creation_timestamp
		}

		services << service
	}

	return services
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
