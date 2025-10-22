# Kubernetes Client

A comprehensive Kubernetes client for HeroLib that wraps `kubectl` with additional safety and validation features.

## Features

- ✅ **Connection Testing**: Validate cluster connectivity before operations
- ✅ **YAML Validation**: Validate K8s YAML before applying
- ✅ **Resource Management**: Create, read, update, delete K8s resources
- ✅ **Cluster Info**: Get cluster status and metrics
- ✅ **Pod Management**: Logs, exec, port-forwarding
- ✅ **Model-Based**: Type-safe resource specifications
- ✅ **HeroScript Integration**: Full playbook support

## Installation

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Setup kubeconfig
mkdir -p ~/.kube
cp /path/to/kubeconfig ~/.kube/config
chmod 600 ~/.kube/config
```

## Usage

### Basic Connection

```v
import incubaid.herolib.virt.kubernetes

mut k8s := kubernetes.new(name: 'production')!
k8s.start()!
info := k8s.cluster_info()!
println(info)
```

### Apply YAML

```v
mut k8s := kubernetes.get(name: 'production')!
k8s.apply_yaml('deployment.yaml')!
```

### Validate YAML

```v
result := kubernetes.yaml_validate('my-deployment.yaml')!
if result.valid {
    println('YAML is valid: ${result.kind}/${result.metadata.name}')
} else {
    println('Validation errors: ${result.errors}')
}
```

### Get Resources

```v
mut k8s := kubernetes.get(name: 'production')!
pods := k8s.get_pods('default')!
for pod in pods {
    println(pod)
}
```

### HeroScript

```heroscript
!!kubernetes.configure
 name: 'production'
 kubeconfig_path: '~/.kube/config'

!!kubernetes.apply
 name: 'production'
 yaml_path: '/path/to/deployment.yaml'

!!kubernetes.info
 name: 'production'

!!kubernetes.delete
 name: 'production'
 kind: 'deployment'
 resource_name: 'my-app'
 namespace: 'default'
```

## API Reference

### Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | string | 'default' | Client instance name |
| `kubeconfig_path` | string | ~/.kube/config | Path to kubeconfig |
| `context` | string | '' | K8s context to use |
| `namespace` | string | 'default' | Default namespace |
| `kubectl_path` | string | 'kubectl' | Path to kubectl binary |

### Main Methods

- `test_connection() !bool` - Test cluster connectivity
- `cluster_info() !ClusterInfo` - Get cluster status
- `apply_yaml(path: string) !KubectlResult` - Apply YAML file
- `delete_resource(kind, name, namespace) !KubectlResult` - Delete resource
- `get_pods(namespace) ![]map` - List pods
- `get_deployments(namespace) ![]map` - List deployments
- `logs(pod, namespace) !string` - Get pod logs
- `exec_pod(pod, namespace, cmd) !string` - Execute in pod

## Best Practices

1. **Always validate YAML** before applying
2. **Test connection** before operations
3. **Use namespaces** to isolate workloads
4. **Check rollout status** for deployments
5. **Monitor logs** for troubleshooting

## Example: Complete Workflow

```v
#!/usr/bin/env -S v -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.virt.kubernetes as k8s_mod
import incubaid.herolib.ui.console

// Create and connect
mut k8s := k8s_mod.new(
    name: 'my-cluster'
    kubeconfig_path: '~/.kube/config'
)!

k8s.start()!

// Validate YAML
result := k8s_mod.yaml_validate('my-deployment.yaml')!
if !result.valid {
    console.print_stderr('Invalid YAML: ${result.errors.join(", ")}')
    exit(1)
}

// Apply
k8s.apply_yaml('my-deployment.yaml')!

// Monitor rollout
if k8s.watch_deployment('my-app', 'default', 300)! {
    console.print_green('Deployment successful!')
} else {
    console.print_stderr('Deployment failed!')
}

// Check status
info := k8s.cluster_info()!
console.print_debug('Cluster: ${info.nodes} nodes, ${info.running_pods} pods')

k8s.stop()!
```

## Troubleshooting

### kubectl not found
```bash
which kubectl
# If not found, install kubectl or add to PATH
export PATH=$PATH:/usr/local/bin
```

### Kubeconfig not found
```bash
export KUBECONFIG=~/.kube/config
# Or specify in code: kubeconfig_path: '/path/to/config'
```

### Connection refused
```bash
# Check cluster is running
kubectl cluster-info
# Check credentials in kubeconfig
kubectl config view
```

### YAML validation errors
```bash
# Validate with kubectl
kubectl apply -f myfile.yaml --dry-run=client
