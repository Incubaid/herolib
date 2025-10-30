module kubernetes

import json

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

// ============================================================================
// Unit Tests for Node Struct and get_nodes() Method
// ============================================================================

// Test Node struct creation with all fields
fn test_node_struct_creation() ! {
	mut node := Node{
		name:              'worker-node-1'
		internal_ip:       '192.168.1.10'
		external_ip:       '203.0.113.10'
		hostname:          'worker-node-1.example.com'
		status:            'Ready'
		roles:             ['worker']
		kubelet_version:   'v1.31.0'
		os_image:          'Ubuntu 22.04.3 LTS'
		kernel_version:    '5.15.0-91-generic'
		container_runtime: 'containerd://1.7.2'
		labels:            {
			'kubernetes.io/hostname':         'worker-node-1'
			'node-role.kubernetes.io/worker': ''
		}
		created_at:        '2024-01-15T08:00:00Z'
	}

	assert node.name == 'worker-node-1'
	assert node.internal_ip == '192.168.1.10'
	assert node.external_ip == '203.0.113.10'
	assert node.hostname == 'worker-node-1.example.com'
	assert node.status == 'Ready'
	assert node.roles.len == 1
	assert node.roles[0] == 'worker'
	assert node.kubelet_version == 'v1.31.0'
	assert node.os_image == 'Ubuntu 22.04.3 LTS'
	assert node.kernel_version == '5.15.0-91-generic'
	assert node.container_runtime == 'containerd://1.7.2'
	assert node.labels['kubernetes.io/hostname'] == 'worker-node-1'
	assert node.created_at == '2024-01-15T08:00:00Z'
}

// Test Node struct with master role
fn test_node_struct_master_role() ! {
	mut node := Node{
		name:   'master-node-1'
		status: 'Ready'
		roles:  ['control-plane', 'master']
	}

	assert node.name == 'master-node-1'
	assert node.status == 'Ready'
	assert node.roles.len == 2
	assert 'control-plane' in node.roles
	assert 'master' in node.roles
}

// Test Node struct with NotReady status
fn test_node_struct_not_ready() ! {
	mut node := Node{
		name:   'worker-node-2'
		status: 'NotReady'
	}

	assert node.name == 'worker-node-2'
	assert node.status == 'NotReady'
}

// Test Node struct with IPv6 internal IP
fn test_node_struct_ipv6() ! {
	mut node := Node{
		name:        'worker-node-3'
		internal_ip: '2001:db8::1'
		status:      'Ready'
	}

	assert node.name == 'worker-node-3'
	assert node.internal_ip == '2001:db8::1'
	assert node.internal_ip.contains(':')
	assert node.status == 'Ready'
}

// Test Node struct with default values
fn test_node_default_values() ! {
	mut node := Node{}

	assert node.name == ''
	assert node.internal_ip == ''
	assert node.external_ip == ''
	assert node.hostname == ''
	assert node.status == ''
	assert node.roles.len == 0
	assert node.kubelet_version == ''
	assert node.os_image == ''
	assert node.kernel_version == ''
	assert node.container_runtime == ''
	assert node.labels.len == 0
	assert node.created_at == ''
}

// Test Node struct with multiple roles
fn test_node_multiple_roles() ! {
	mut node := Node{
		name:  'control-plane-1'
		roles: ['control-plane', 'master', 'etcd']
	}

	assert node.roles.len == 3
	assert 'control-plane' in node.roles
	assert 'master' in node.roles
	assert 'etcd' in node.roles
}

// ============================================================================
// Unit Tests for DescribeResourceArgs Struct
// ============================================================================

// Test DescribeResourceArgs struct for namespaced resource
fn test_describe_resource_args_namespaced() ! {
	mut args := DescribeResourceArgs{
		resource:      'pod'
		resource_name: 'nginx-pod'
		namespace:     'default'
	}

	assert args.resource == 'pod'
	assert args.resource_name == 'nginx-pod'
	assert args.namespace == 'default'
}

// Test DescribeResourceArgs struct for cluster-scoped resource
fn test_describe_resource_args_cluster_scoped() ! {
	mut args := DescribeResourceArgs{
		resource:      'node'
		resource_name: 'worker-node-1'
		namespace:     ''
	}

	assert args.resource == 'node'
	assert args.resource_name == 'worker-node-1'
	assert args.namespace == ''
}

// Test DescribeResourceArgs struct for custom resource (TFGW)
fn test_describe_resource_args_custom_resource() ! {
	mut args := DescribeResourceArgs{
		resource:      'tfgw'
		resource_name: 'cryptpad-main'
		namespace:     'cryptpad'
	}

	assert args.resource == 'tfgw'
	assert args.resource_name == 'cryptpad-main'
	assert args.namespace == 'cryptpad'
}

// ============================================================================
// JSON Parsing Tests for Kubectl Responses
// ============================================================================

// Test parsing kubectl node list JSON response
fn test_parse_kubectl_node_list_json() ! {
	// Sample kubectl get nodes -o json response
	json_response := '{
  "items": [
    {
      "metadata": {
        "name": "k3s-master",
        "labels": {
          "kubernetes.io/hostname": "k3s-master",
          "node-role.kubernetes.io/control-plane": "",
          "node-role.kubernetes.io/master": ""
        },
        "creationTimestamp": "2024-01-15T08:00:00Z"
      },
      "spec": {
        "podCIDR": "10.42.0.0/24"
      },
      "status": {
        "addresses": [
          {
            "type": "InternalIP",
            "address": "192.168.1.100"
          },
          {
            "type": "Hostname",
            "address": "k3s-master"
          }
        ],
        "conditions": [
          {
            "type": "Ready",
            "status": "True"
          }
        ],
        "nodeInfo": {
          "architecture": "arm64",
          "kernelVersion": "5.15.0-91-generic",
          "osImage": "Ubuntu 22.04.3 LTS",
          "operatingSystem": "linux",
          "kubeletVersion": "v1.31.0+k3s1",
          "containerRuntimeVersion": "containerd://1.7.11-k3s2"
        }
      }
    }
  ]
}'

	// Parse the JSON
	node_list := json.decode(KubectlNodeListResponse, json_response)!

	// Verify parsing
	assert node_list.items.len == 1
	assert node_list.items[0].metadata.name == 'k3s-master'
	assert node_list.items[0].metadata.labels['kubernetes.io/hostname'] == 'k3s-master'
	assert node_list.items[0].metadata.labels['node-role.kubernetes.io/control-plane'] == ''
	assert node_list.items[0].spec.pod_cidr == '10.42.0.0/24'
	assert node_list.items[0].status.addresses.len == 2
	assert node_list.items[0].status.addresses[0].address_type == 'InternalIP'
	assert node_list.items[0].status.addresses[0].address == '192.168.1.100'
	assert node_list.items[0].status.addresses[1].address_type == 'Hostname'
	assert node_list.items[0].status.addresses[1].address == 'k3s-master'
	assert node_list.items[0].status.conditions.len == 1
	assert node_list.items[0].status.conditions[0].condition_type == 'Ready'
	assert node_list.items[0].status.conditions[0].status == 'True'
	assert node_list.items[0].status.node_info.kubelet_version == 'v1.31.0+k3s1'
	assert node_list.items[0].status.node_info.os_image == 'Ubuntu 22.04.3 LTS'
}

// Test parsing kubectl node list with IPv6 addresses
fn test_parse_kubectl_node_list_ipv6() ! {
	json_response := '{
  "items": [
    {
      "metadata": {
        "name": "worker-node-1",
        "labels": {
          "node-role.kubernetes.io/worker": ""
        },
        "creationTimestamp": "2024-01-15T09:00:00Z"
      },
      "spec": {
        "podCIDR": "10.42.1.0/24"
      },
      "status": {
        "addresses": [
          {
            "type": "InternalIP",
            "address": "2001:db8::1"
          },
          {
            "type": "ExternalIP",
            "address": "2001:db8:1::1"
          },
          {
            "type": "Hostname",
            "address": "worker-node-1"
          }
        ],
        "conditions": [
          {
            "type": "Ready",
            "status": "True"
          }
        ],
        "nodeInfo": {
          "architecture": "amd64",
          "kernelVersion": "6.5.0-14-generic",
          "osImage": "Ubuntu 23.10",
          "operatingSystem": "linux",
          "kubeletVersion": "v1.31.0",
          "containerRuntimeVersion": "containerd://1.7.2"
        }
      }
    }
  ]
}'

	node_list := json.decode(KubectlNodeListResponse, json_response)!

	assert node_list.items.len == 1
	assert node_list.items[0].metadata.name == 'worker-node-1'
	assert node_list.items[0].status.addresses.len == 3

	// Verify IPv6 addresses
	mut internal_ip := ''
	mut external_ip := ''
	for addr in node_list.items[0].status.addresses {
		if addr.address_type == 'InternalIP' {
			internal_ip = addr.address
		}
		if addr.address_type == 'ExternalIP' {
			external_ip = addr.address
		}
	}

	assert internal_ip == '2001:db8::1'
	assert internal_ip.contains(':')
	assert external_ip == '2001:db8:1::1'
	assert external_ip.contains(':')
}

// Test parsing node with NotReady status
fn test_parse_kubectl_node_not_ready() ! {
	json_response := '{
  "items": [
    {
      "metadata": {
        "name": "worker-node-2",
        "labels": {},
        "creationTimestamp": "2024-01-15T10:00:00Z"
      },
      "spec": {
        "podCIDR": ""
      },
      "status": {
        "addresses": [
          {
            "type": "InternalIP",
            "address": "192.168.1.102"
          }
        ],
        "conditions": [
          {
            "type": "Ready",
            "status": "False"
          }
        ],
        "nodeInfo": {
          "architecture": "amd64",
          "kernelVersion": "5.15.0-91-generic",
          "osImage": "Ubuntu 22.04.3 LTS",
          "operatingSystem": "linux",
          "kubeletVersion": "v1.31.0",
          "containerRuntimeVersion": "containerd://1.7.2"
        }
      }
    }
  ]
}'

	node_list := json.decode(KubectlNodeListResponse, json_response)!

	assert node_list.items.len == 1
	assert node_list.items[0].metadata.name == 'worker-node-2'
	assert node_list.items[0].status.conditions[0].condition_type == 'Ready'
	assert node_list.items[0].status.conditions[0].status == 'False'
}

// Test role extraction from node labels
fn test_node_role_extraction() ! {
	json_response := '{
  "items": [
    {
      "metadata": {
        "name": "control-plane-1",
        "labels": {
          "node-role.kubernetes.io/control-plane": "",
          "node-role.kubernetes.io/master": "",
          "node-role.kubernetes.io/etcd": "",
          "kubernetes.io/hostname": "control-plane-1"
        },
        "creationTimestamp": "2024-01-15T08:00:00Z"
      },
      "spec": {
        "podCIDR": "10.42.0.0/24"
      },
      "status": {
        "addresses": [
          {
            "type": "InternalIP",
            "address": "192.168.1.100"
          }
        ],
        "conditions": [
          {
            "type": "Ready",
            "status": "True"
          }
        ],
        "nodeInfo": {
          "architecture": "arm64",
          "kernelVersion": "5.15.0-91-generic",
          "osImage": "Ubuntu 22.04.3 LTS",
          "operatingSystem": "linux",
          "kubeletVersion": "v1.31.0",
          "containerRuntimeVersion": "containerd://1.7.2"
        }
      }
    }
  ]
}'

	node_list := json.decode(KubectlNodeListResponse, json_response)!

	assert node_list.items.len == 1

	// Extract roles from labels
	mut roles := []string{}
	for label_key, _ in node_list.items[0].metadata.labels {
		if label_key.starts_with('node-role.kubernetes.io/') {
			role := label_key.all_after('node-role.kubernetes.io/')
			if role.len > 0 {
				roles << role
			}
		}
	}

	// Verify roles were extracted
	assert roles.len == 3
	assert 'control-plane' in roles
	assert 'master' in roles
	assert 'etcd' in roles
}

// Test empty node list
fn test_parse_empty_node_list() ! {
	json_response := '{
  "items": []
}'

	node_list := json.decode(KubectlNodeListResponse, json_response)!
	assert node_list.items.len == 0
}

// Test dual-stack node (multiple InternalIP addresses)
fn test_parse_dual_stack_node() ! {
	json_response := '{
  "items": [
    {
      "metadata": {
        "name": "dual-stack-node",
        "labels": {
          "node-role.kubernetes.io/control-plane": "true"
        },
        "creationTimestamp": "2025-10-29T12:40:47Z"
      },
      "spec": {
        "podCIDR": "10.42.0.0/24"
      },
      "status": {
        "addresses": [
          {
            "type": "InternalIP",
            "address": "10.20.3.2"
          },
          {
            "type": "InternalIP",
            "address": "477:a3a5:7595:d3da:ff0f:ece1:204e:6691"
          },
          {
            "type": "Hostname",
            "address": "dual-stack-node"
          }
        ],
        "conditions": [
          {
            "type": "Ready",
            "status": "True"
          }
        ],
        "nodeInfo": {
          "architecture": "amd64",
          "kernelVersion": "5.15.0-91-generic",
          "osImage": "Ubuntu 22.04.3 LTS",
          "operatingSystem": "linux",
          "kubeletVersion": "v1.31.0+k3s1",
          "containerRuntimeVersion": "containerd://1.7.11-k3s2"
        }
      }
    }
  ]
}'

	node_list := json.decode(KubectlNodeListResponse, json_response)!

	assert node_list.items.len == 1
	assert node_list.items[0].metadata.name == 'dual-stack-node'

	// Verify we have 2 InternalIP addresses
	assert node_list.items[0].status.addresses.len == 3

	mut internal_ip_count := 0
	for addr in node_list.items[0].status.addresses {
		if addr.address_type == 'InternalIP' {
			internal_ip_count++
		}
	}
	assert internal_ip_count == 2
}
