module kubernetes

// ============================================================================
// Unit Tests for Kubernetes Client Module
// These tests verify struct creation and data handling without executing
// real kubectl commands (unit tests only, not integration tests)
// ============================================================================

fn test_model_creation() ! {
	mut client := new(name: 'test-cluster')!
	assert client.name == 'test-cluster'
}

// ============================================================================
// Unit Tests for Data Structures and JSON Parsing
// ============================================================================

// Test Pod struct creation and field access
fn test_pod_struct_creation() ! {
	mut pod := Pod{
		name:       'test-pod'
		namespace:  'default'
		status:     'Running'
		node:       'node-1'
		ip:         '10.244.0.5'
		containers: ['nginx', 'sidecar']
		labels:     {
			'app': 'web'
			'env': 'prod'
		}
		created_at: '2024-01-15T10:30:00Z'
	}

	assert pod.name == 'test-pod'
	assert pod.namespace == 'default'
	assert pod.status == 'Running'
	assert pod.node == 'node-1'
	assert pod.ip == '10.244.0.5'
	assert pod.containers.len == 2
	assert pod.containers[0] == 'nginx'
	assert pod.containers[1] == 'sidecar'
	assert pod.labels['app'] == 'web'
	assert pod.labels['env'] == 'prod'
	assert pod.created_at == '2024-01-15T10:30:00Z'
}

// Test Deployment struct creation
fn test_deployment_struct_creation() ! {
	mut deployment := Deployment{
		name:               'nginx-deployment'
		namespace:          'default'
		replicas:           3
		ready_replicas:     3
		available_replicas: 3
		updated_replicas:   3
		labels:             {
			'app': 'nginx'
		}
		created_at:         '2024-01-15T09:00:00Z'
	}

	assert deployment.name == 'nginx-deployment'
	assert deployment.namespace == 'default'
	assert deployment.replicas == 3
	assert deployment.ready_replicas == 3
	assert deployment.available_replicas == 3
	assert deployment.updated_replicas == 3
	assert deployment.labels['app'] == 'nginx'
	assert deployment.created_at == '2024-01-15T09:00:00Z'
}

// Test Service struct creation with ClusterIP
fn test_service_struct_creation() ! {
	mut service := Service{
		name:         'nginx-service'
		namespace:    'default'
		service_type: 'ClusterIP'
		cluster_ip:   '10.96.100.50'
		external_ip:  ''
		ports:        ['80/TCP', '443/TCP']
		labels:       {
			'app': 'nginx'
		}
		created_at:   '2024-01-15T09:30:00Z'
	}

	assert service.name == 'nginx-service'
	assert service.namespace == 'default'
	assert service.service_type == 'ClusterIP'
	assert service.cluster_ip == '10.96.100.50'
	assert service.external_ip == ''
	assert service.ports.len == 2
	assert service.ports[0] == '80/TCP'
	assert service.ports[1] == '443/TCP'
	assert service.labels['app'] == 'nginx'
	assert service.created_at == '2024-01-15T09:30:00Z'
}

// Test Service with LoadBalancer type and external IP
fn test_service_loadbalancer_type() ! {
	mut service := Service{
		name:         'web-lb-service'
		namespace:    'default'
		service_type: 'LoadBalancer'
		cluster_ip:   '10.96.100.52'
		external_ip:  '203.0.113.10'
		ports:        ['80/TCP']
		labels:       {
			'app': 'web'
		}
		created_at:   '2024-01-15T11:00:00Z'
	}

	assert service.name == 'web-lb-service'
	assert service.service_type == 'LoadBalancer'
	assert service.cluster_ip == '10.96.100.52'
	assert service.external_ip == '203.0.113.10'
	assert service.ports.len == 1
	assert service.ports[0] == '80/TCP'
}

// Test ClusterInfo struct
fn test_cluster_info_struct() ! {
	mut cluster := ClusterInfo{
		api_server:   'https://test-cluster:6443'
		version:      'v1.31.0'
		nodes:        3
		namespaces:   5
		running_pods: 12
	}

	assert cluster.api_server == 'https://test-cluster:6443'
	assert cluster.version == 'v1.31.0'
	assert cluster.nodes == 3
	assert cluster.namespaces == 5
	assert cluster.running_pods == 12
}

// Test Pod with multiple containers
fn test_pod_with_multiple_containers() ! {
	mut pod := Pod{
		name:       'multi-container-pod'
		namespace:  'default'
		containers: ['app', 'sidecar', 'init']
	}

	assert pod.containers.len == 3
	assert 'app' in pod.containers
	assert 'sidecar' in pod.containers
	assert 'init' in pod.containers
}

// Test Deployment with partial ready state
fn test_deployment_partial_ready() ! {
	mut deployment := Deployment{
		name:               'redis-deployment'
		namespace:          'default'
		replicas:           3
		ready_replicas:     2
		available_replicas: 2
		updated_replicas:   3
	}

	assert deployment.replicas == 3
	assert deployment.ready_replicas == 2
	assert deployment.available_replicas == 2
	// Not all replicas are ready
	assert deployment.ready_replicas < deployment.replicas
}

// Test Service with multiple ports
fn test_service_with_multiple_ports() ! {
	mut service := Service{
		name:  'multi-port-service'
		ports: ['80/TCP', '443/TCP', '8080/TCP']
	}

	assert service.ports.len == 3
	assert '80/TCP' in service.ports
	assert '443/TCP' in service.ports
	assert '8080/TCP' in service.ports
}

// Test Pod with default/empty values
fn test_pod_default_values() ! {
	mut pod := Pod{}

	assert pod.name == ''
	assert pod.namespace == ''
	assert pod.status == ''
	assert pod.node == ''
	assert pod.ip == ''
	assert pod.containers.len == 0
	assert pod.labels.len == 0
	assert pod.created_at == ''
}

// Test Deployment with default values
fn test_deployment_default_values() ! {
	mut deployment := Deployment{}

	assert deployment.name == ''
	assert deployment.namespace == ''
	assert deployment.replicas == 0
	assert deployment.ready_replicas == 0
	assert deployment.available_replicas == 0
	assert deployment.updated_replicas == 0
	assert deployment.labels.len == 0
	assert deployment.created_at == ''
}

// Test Service with default values
fn test_service_default_values() ! {
	mut service := Service{}

	assert service.name == ''
	assert service.namespace == ''
	assert service.service_type == ''
	assert service.cluster_ip == ''
	assert service.external_ip == ''
	assert service.ports.len == 0
	assert service.labels.len == 0
	assert service.created_at == ''
}

// Test KubectlResult struct for successful command
fn test_kubectl_result_struct() ! {
	mut result := KubectlResult{
		exit_code: 0
		stdout:    '{"items": []}'
		stderr:    ''
	}

	assert result.exit_code == 0
	assert result.stdout.contains('items')
	assert result.stderr == ''
}

// Test KubectlResult struct for error
fn test_kubectl_result_error() ! {
	mut result := KubectlResult{
		exit_code: 1
		stdout:    ''
		stderr:    'Error: connection refused'
	}

	assert result.exit_code == 1
	assert result.stderr.contains('Error')
}
