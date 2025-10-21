module kubernetes

import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools
import time

@[params]
pub struct DeployArgs {
pub mut:
	deployment   Deployment
	wait         bool = true
	timeout_seconds int = 300
	poll_interval_ms int = 5000
}

// Deploy a Deployment resource
pub fn (mut c KubernetesClient) deploy(args DeployArgs) !Deployment {
	console.print_header('Deploying ${args.deployment.metadata.name}')
	
	// Check if deployment already exists
	existing := c.get[Deployment](
		resource_type: 'deployments'
		name: args.deployment.metadata.name
		namespace: args.deployment.metadata.namespace
	) or { none }
	
	mut deployed_deployment := match existing {
		Deployment { c.update[Deployment](args.deployment)! }
		else { c.create[Deployment](args.deployment)! }
	}
	
	console.print_green('Deployment created/updated: ${args.deployment.metadata.name}')
	
	if args.wait {
		c.wait_for_deployment_ready(
			name: args.deployment.metadata.name
			namespace: args.deployment.metadata.namespace
			timeout_seconds: args.timeout_seconds
		)!
	}
	
	return deployed_deployment
}

@[params]
pub struct WaitForDeploymentArgs {
pub mut:
	name              string
	namespace         string = 'default'
	timeout_seconds   int = 300
	poll_interval_ms  int = 5000
}

// Wait for deployment to be ready
pub fn (mut c KubernetesClient) wait_for_deployment_ready(args WaitForDeploymentArgs) ! {
	start_time := time.now()
	
	for {
		deployment := c.get[Deployment](
			resource_type: 'deployments'
			name: args.name
			namespace: args.namespace
		)!
		
		if deployment.status != none {
			status := deployment.status!
			if status.observed_generation >= deployment.metadata.resource_version.int() {
				if status.updated_replicas == deployment.spec.replicas {
					if status.ready_replicas == deployment.spec.replicas {
						console.print_green('Deployment ${args.name} is ready')
						return
					}
				}
			}
		}
		
		elapsed := time.now().unix_time() - start_time.unix_time()
		if elapsed > args.timeout_seconds {
			return error('Timeout waiting for deployment ${args.name} to be ready')
		}
		
		console.print_debug('Waiting for deployment ${args.name}...')
		time.sleep(args.poll_interval_ms * time.millisecond)
	}
}

@[params]
pub struct DeleteArgs {
pub mut:
	resource_type string // 'pods', 'deployments', 'services', etc.
	name          string
	namespace     string = 'default'
	grace_period_seconds int = 30
	wait          bool = true
	timeout_seconds int = 300
}

// Delete a resource
pub fn (mut c KubernetesClient) delete_resource(args DeleteArgs) ! {
	console.print_header('Deleting ${args.resource_type}/${args.name}')
	
	c.delete(
		resource_type: args.resource_type
		name: args.name
		namespace: args.namespace
	)!
	
	console.print_green('${args.resource_type}/${args.name} deleted')
	
	if args.wait {
		start_time := time.now()
		for {
			c.get[map[string]interface{}](
				resource_type: args.resource_type
				name: args.name
				namespace: args.namespace
			) or {
				console.print_green('${args.resource_type}/${args.name} fully removed')
				return
			}
			
			elapsed := time.now().unix_time() - start_time.unix_time()
			if elapsed > args.timeout_seconds {
				return error('Timeout waiting for ${args.resource_type}/${args.name} to be deleted')
			}
			
			time.sleep(5000 * time.millisecond)
		}
	}
}

@[params]
pub struct ScaleArgs {
pub mut:
	deployment_name string
	namespace       string = 'default'
	replicas        int
	wait            bool = true
	timeout_seconds int = 300
}

// Scale a deployment
pub fn (mut c KubernetesClient) scale_deployment(args ScaleArgs) !Deployment {
	console.print_header('Scaling ${args.deployment_name} to ${args.replicas} replicas')
	
	// Patch the deployment spec.replicas field
	patch_data := {
		'spec': {
			'replicas': args.replicas
		}
	}
	
	mut deployment := c.patch[Deployment](
		resource_type: 'deployments'
		name: args.deployment_name
		namespace: args.namespace
		patch_data: patch_data
	)!
	
	if args.wait {
		c.wait_for_deployment_ready(
			name: args.deployment_name
			namespace: args.namespace
			timeout_seconds: args.timeout_seconds
		)!
	}
	
	return deployment
}

@[params]
pub struct RollingRestartArgs {
pub mut:
	deployment_name string
	namespace       string = 'default'
	wait            bool = true
	timeout_seconds int = 600
}

// Perform rolling restart of a deployment
pub fn (mut c KubernetesClient) rolling_restart(args RollingRestartArgs) ! {
	console.print_header('Rolling restart of ${args.deployment_name}')
	
	now_timestamp := time.now().format_rfc3339()
	patch_data := {
		'spec': {
			'template': {
				'metadata': {
					'annotations': {
						'kubectl.kubernetes.io/restartedAt': now_timestamp
					}
				}
			}
		}
	}
	
	c.patch[Deployment](
		resource_type: 'deployments'
		name: args.deployment_name
		namespace: args.namespace
		patch_data: patch_data
	)!
	
	if args.wait {
		c.wait_for_deployment_ready(
			name: args.deployment_name
			namespace: args.namespace
			timeout_seconds: args.timeout_seconds
		)!
	}
	
	console.print_green('${args.deployment_name} rolling restart completed')
}

@[params]
pub struct GetLogsArgs {
pub mut:
	pod_name      string
	container_name string
	namespace     string = 'default'
	tail_lines    int = 100
	follow        bool
}

// Get pod logs
pub fn (mut c KubernetesClient) get_pod_logs(args GetLogsArgs) !string {
	mut prefix := '/api/v1/namespaces/${args.namespace}/pods/${args.pod_name}/log'
	prefix += '?tailLines=${args.tail_lines}'
	if args.container_name.len > 0 {
		prefix += '&container=${args.container_name}'
	}
	
	conn := c.connection()!
	return conn.get_text(prefix: prefix)!
}

@[params]
pub struct ExecArgs {
pub mut:
	pod_name      string
	container_name string
	command       []string
	namespace     string = 'default'
}

// Execute command in pod (requires WebSocket support - future enhancement)
pub fn (mut c KubernetesClient) exec_in_pod(args ExecArgs) ! {
	// TODO: Implement WebSocket-based exec
	return error('exec_in_pod requires WebSocket support - not yet implemented')
}

@[params]
pub struct PortForwardArgs {
pub mut:
	pod_name     string
	namespace    string = 'default'
	local_port   int
	remote_port  int
}

// Port forward to pod (requires WebSocket support - future enhancement)
pub fn (mut c KubernetesClient) port_forward(args PortForwardArgs) ! {
	// TODO: Implement WebSocket-based port forward
	return error('port_forward requires WebSocket support - not yet implemented')
}
