# Kubernetes Client Example

This example demonstrates the Kubernetes client functionality in HeroLib, including JSON parsing and cluster interaction.

## Prerequisites

1. **kubectl installed**: The Kubernetes command-line tool must be installed on your system.
   - macOS: `brew install kubectl`
   - Linux: See [official installation guide](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
   - Windows: See [official installation guide](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)

2. **Kubernetes cluster**: You need access to a Kubernetes cluster. For local development, you can use:
   - **Minikube**: `brew install minikube && minikube start`
   - **Kind**: `brew install kind && kind create cluster`
   - **Docker Desktop**: Enable Kubernetes in Docker Desktop settings
   - **k3s**: Lightweight Kubernetes distribution

## Running the Example

### Method 1: Direct Execution (Recommended)

```bash
# Make the script executable
chmod +x examples/virt/kubernetes/kubernetes_example.vsh

# Run the script
./examples/virt/kubernetes/kubernetes_example.vsh
```

### Method 2: Using V Command

```bash
v -enable-globals run examples/virt/kubernetes/kubernetes_example.vsh
```

## What the Example Demonstrates

The example script demonstrates the following functionality:

### 1. **Cluster Information**

- Retrieves Kubernetes cluster version
- Counts total nodes in the cluster
- Counts total namespaces
- Counts running pods across all namespaces

### 2. **Pod Management**

- Lists all pods in the `default` namespace
- Displays pod details:
  - Name, namespace, status
  - Node assignment and IP address
  - Container names
  - Labels and creation timestamp

### 3. **Deployment Management**

- Lists all deployments in the `default` namespace
- Shows deployment information:
  - Name and namespace
  - Replica counts (desired, ready, available, updated)
  - Labels and creation timestamp

### 4. **Service Management**

- Lists all services in the `default` namespace
- Displays service details:
  - Name, namespace, and type (ClusterIP, NodePort, LoadBalancer)
  - Cluster IP and external IP (if applicable)
  - Exposed ports and protocols
  - Labels and creation timestamp

## Expected Output

### With a Running Cluster

When connected to a Kubernetes cluster with resources, you'll see formatted output like:

```
╔════════════════════════════════════════════════════════════════╗
║         Kubernetes Client Example - HeroLib                   ║
║  Demonstrates JSON parsing and cluster interaction            ║
╚════════════════════════════════════════════════════════════════╝

[INFO] Creating Kubernetes client instance...
[SUCCESS] Kubernetes client created successfully

 - 1. Cluster Information
[INFO] Retrieving cluster information...

┌─────────────────────────────────────────────────────────────┐
│ Cluster Overview                                            │
├─────────────────────────────────────────────────────────────┤
│ API Server:      https://127.0.0.1:6443                     │
│ Version:         v1.31.0                                    │
│ Nodes:           3                                          │
│ Namespaces:      5                                          │
│ Running Pods:    12                                         │
└─────────────────────────────────────────────────────────────┘
```

### Without a Cluster

If kubectl is not installed or no cluster is configured, you'll see helpful error messages:

```
Error: Failed to get cluster information
...
This usually means:
  - kubectl is not installed
  - No Kubernetes cluster is configured (check ~/.kube/config)
  - The cluster is not accessible

To set up a local cluster, you can use:
  - Minikube: https://minikube.sigs.k8s.io/docs/start/
  - Kind: https://kind.sigs.k8s.io/docs/user/quick-start/
  - Docker Desktop (includes Kubernetes)
```

## Creating Test Resources

If your cluster is empty, you can create test resources to see the example in action:

```bash
# Create a test pod
kubectl run nginx --image=nginx

# Create a test deployment
kubectl create deployment nginx-deployment --image=nginx --replicas=3

# Expose the deployment as a service
kubectl expose deployment nginx-deployment --port=80 --type=ClusterIP
```

## Code Structure

The example demonstrates proper usage of the HeroLib Kubernetes client:

1. **Factory Pattern**: Uses `kubernetes.new()` to create a client instance
2. **Error Handling**: Proper use of V's `!` error propagation and `or {}` blocks
3. **JSON Parsing**: All kubectl JSON output is parsed into structured V types
4. **Console Output**: Clear, formatted output using the `console` module

## Implementation Details

The Kubernetes client module uses:

- **Struct-based JSON decoding**: V's `json.decode(Type, data)` for type-safe parsing
- **Kubernetes API response structs**: Matching kubectl's JSON output format
- **Runtime resource structs**: Clean data structures for application use (`Pod`, `Deployment`, `Service`)

## Troubleshooting

### "kubectl: command not found"

Install kubectl using your package manager (see Prerequisites above).

### "The connection to the server was refused"

Start a local Kubernetes cluster:

```bash
minikube start
# or
kind create cluster
```

### "No resources found in default namespace"

Create test resources using the commands in the "Creating Test Resources" section above.

## Related Files

- **Implementation**: `lib/virt/kubernetes/kubernetes_client.v`
- **Data Models**: `lib/virt/kubernetes/kubernetes_resources_model.v`
- **Unit Tests**: `lib/virt/kubernetes/kubernetes_test.v`
- **Factory**: `lib/virt/kubernetes/kubernetes_factory_.v`
