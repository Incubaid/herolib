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

// Args for describing a resource
@[params]
pub struct DescribeResourceArgs {
pub mut:
	resource      string // Resource type: pod, node, service, deployment, tfgw, etc.
	resource_name string // Name of the specific resource instance
	namespace     string // Namespace (empty string for cluster-scoped resources)
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

	// Check if this is a command that might produce large output
	is_large_output := args.command.contains('get nodes') || args.command.contains('get pods')
		|| args.command.contains('get deployments') || args.command.contains('get services')

	if is_large_output {
		// Use exec_fast for large outputs (avoids 8KB buffer limit in osal.exec)
		// exec_fast uses os.execute which doesn't have the pipe buffer limitation
		result_output := osal.exec_fast(
			cmd:          cmd
			ignore_error: true
		) or { return error('Failed to execute kubectl command: ${err}') }

		// Check if command succeeded by looking for error messages
		if result_output.contains('Error from server') || result_output.contains('error:')
			|| result_output.contains('Unable to connect') {
			return KubectlResult{
				exit_code: 1
				stdout:    result_output
				stderr:    result_output
				success:   false
			}
		}

		return KubectlResult{
			exit_code: 0
			stdout:    result_output
			stderr:    ''
			success:   result_output.len > 0
		}
	} else {
		// Use regular exec for normal commands (supports timeout and proper error handling)
		// Note: stdout must be true to prevent process from hanging when output buffer fills
		job := osal.exec(
			cmd:         cmd
			timeout:     args.timeout
			retry:       args.retry
			raise_error: false
			stdout:      true
		)!

		return KubectlResult{
			exit_code: job.exit_code
			stdout:    job.output
			stderr:    job.error
			success:   job.exit_code == 0
		}
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

// Get nodes from cluster
pub fn (mut k KubeClient) get_nodes() ![]Node {
	result := k.kubectl_exec(command: 'get nodes -o json')!
	if !result.success {
		return error('Failed to get nodes: ${result.stderr}')
	}

	// Parse JSON response using struct-based decoding
	node_list := json.decode(KubectlNodeListResponse, result.stdout) or {
		// Log error details for debugging
		console.print_stderr('Failed to parse nodes JSON response')
		console.print_stderr('Error: ${err}')
		console.print_stderr('Response length: ${result.stdout.len} bytes')
		if result.stdout.len > 0 {
			console.print_stderr('First 200 chars: ${result.stdout[..if result.stdout.len < 200 {
				result.stdout.len
			} else {
				200
			}]}')
		}
		return error('Failed to parse nodes JSON: ${err}')
	}

	mut nodes := []Node{}

	for item in node_list.items {
		// Extract IP addresses (handle dual-stack: multiple IPs of same type)
		mut internal_ips := []string{}
		mut external_ips := []string{}
		mut hostname := ''

		for addr in item.status.addresses {
			match addr.address_type {
				'InternalIP' {
					internal_ips << addr.address
				}
				'ExternalIP' {
					external_ips << addr.address
				}
				'Hostname' {
					hostname = addr.address
				}
				else {}
			}
		}

		// For backward compatibility, use first internal/external IP
		internal_ip := if internal_ips.len > 0 { internal_ips[0] } else { '' }
		external_ip := if external_ips.len > 0 { external_ips[0] } else { '' }

		// Determine node status from conditions
		mut node_status := 'Unknown'
		for condition in item.status.conditions {
			if condition.condition_type == 'Ready' {
				node_status = if condition.status == 'True' { 'Ready' } else { 'NotReady' }
				break
			}
		}

		// Extract roles from labels
		mut roles := []string{}
		for label_key, _ in item.metadata.labels {
			if label_key.starts_with('node-role.kubernetes.io/') {
				role := label_key.all_after('node-role.kubernetes.io/')
				if role.len > 0 {
					roles << role
				}
			}
		}

		// Create Node struct from kubectl response
		node := Node{
			name:              item.metadata.name
			internal_ip:       internal_ip
			external_ip:       external_ip
			internal_ips:      internal_ips
			external_ips:      external_ips
			hostname:          hostname
			status:            node_status
			roles:             roles
			kubelet_version:   item.status.node_info.kubelet_version
			os_image:          item.status.node_info.os_image
			kernel_version:    item.status.node_info.kernel_version
			container_runtime: item.status.node_info.container_runtime_version
			labels:            item.metadata.labels
			created_at:        item.metadata.creation_timestamp
		}

		nodes << node
	}

	return nodes
}

// Apply YAML file
pub fn (mut k KubeClient) apply_yaml(yaml_path string) !KubectlResult {
	// Validate before applying
	validation := yaml_validate(yaml_path)!
	if !validation.valid {
		return error('YAML validation failed: ${validation.errors.join(', ')}')
	}

	console.print_debug('Applying YAML file: ${yaml_path}')
	result := k.kubectl_exec(command: 'apply -f ${yaml_path}')!
	console.print_debug('Apply completed with exit code: ${result.exit_code}')

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

// Describe resource - provides detailed information about a specific resource
pub fn (mut k KubeClient) describe_resource(args DescribeResourceArgs) !KubectlResult {
	// Build the describe command
	mut cmd := 'describe ${args.resource} ${args.resource_name}'

	// Only add namespace flag if namespace is not empty (for namespaced resources)
	if args.namespace.len > 0 {
		cmd += ' -n ${args.namespace}'
	}

	// Execute the command
	result := k.kubectl_exec(command: cmd)!
	return result
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
