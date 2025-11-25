#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.virt.kubernetes
import incubaid.herolib.ui.console

println('╔════════════════════════════════════════════════════════════════╗')
println('║         Kubernetes Client Example - HeroLib                    ║')
println('║  Demonstrates JSON parsing and cluster interaction             ║')
println('╚════════════════════════════════════════════════════════════════╝')
println('')

// Create a Kubernetes client instance using the factory pattern
println('[INFO] Creating Kubernetes client instance...')
mut client := kubernetes.new() or {
	console.print_header('Error: Failed to create Kubernetes client')
	eprintln('${err}')
	eprintln('')
	eprintln('Make sure kubectl is installed and configured properly.')
	eprintln('You can install kubectl ')
	exit(1)
}

println('[SUCCESS] Kubernetes client created successfully')
println('')

// ============================================================================
// 1. Get Cluster Information
// ============================================================================
console.print_header('1. Cluster Information')
println('[INFO] Retrieving cluster information...')
println('')

cluster := client.cluster_info() or {
	console.print_header('Error: Failed to get cluster information')
	eprintln('${err}')
	eprintln('')
	eprintln('This usually means:')
	eprintln('  - kubectl is not installed')
	eprintln('  - No Kubernetes cluster is configured (check ~/.kube/config)')
	eprintln('  - The cluster is not accessible')
	eprintln('')
	eprintln('To set up a local cluster, you can use:')
	eprintln('  - Minikube: https://minikube.sigs.k8s.io/docs/start/')
	eprintln('  - Kind: https://kind.sigs.k8s.io/docs/user/quick-start/')
	eprintln('  - Docker Desktop (includes Kubernetes)')
	exit(1)
}

println('┌─────────────────────────────────────────────────────────────┐')
println('│ Cluster Overview                                            │')
println('├─────────────────────────────────────────────────────────────┤')
println('│ API Server:      ${cluster.api_server:-50}│')
println('│ Version:         ${cluster.version:-50}│')
println('│ Nodes:           ${cluster.nodes.str():-50}│')
println('│ Namespaces:      ${cluster.namespaces.str():-50}│')
println('│ Running Pods:    ${cluster.running_pods.str():-50}│')
println('└─────────────────────────────────────────────────────────────┘')
println('')

// ============================================================================
// 2. Get Pods in the 'default' namespace
// ============================================================================
console.print_header('2. Pods in "default" Namespace')
println('[INFO] Retrieving pods from the default namespace...')
println('')

pods := client.get_pods('default') or {
	console.print_header('Warning: Failed to get pods')
	eprintln('${err}')
	eprintln('')
	[]kubernetes.Pod{}
}

if pods.len == 0 {
	println('No pods found in the default namespace.')
	println('')
	println('To create a test pod, run:')
	println('  kubectl run nginx --image=nginx')
	println('')
} else {
	println('Found ${pods.len} pod(s) in the default namespace:')
	println('')

	for i, pod in pods {
		println('┌─────────────────────────────────────────────────────────────┐')
		println('│ Pod #${i + 1:-56}│')
		println('├─────────────────────────────────────────────────────────────┤')
		println('│ Name:        ${pod.name:-50}│')
		println('│ Namespace:   ${pod.namespace:-50}│')
		println('│ Status:      ${pod.status:-50}│')
		println('│ Node:        ${pod.node:-50}│')
		println('│ IP:          ${pod.ip:-50}│')
		println('│ Containers:  ${pod.containers.join(', '):-50}│')
		println('│ Created:     ${pod.created_at:-50}│')

		if pod.labels.len > 0 {
			println('│ Labels:                                                     │')
			for key, value in pod.labels {
				label_str := '  ${key}=${value}'
				println('│   ${label_str:-58}│')
			}
		}

		println('└─────────────────────────────────────────────────────────────┘')
		println('')
	}
}

// ============================================================================
// 3. Get Deployments in the 'default' namespace
// ============================================================================
console.print_header('3. Deployments in "default" Namespace')
println('[INFO] Retrieving deployments from the default namespace...')
println('')

deployments := client.get_deployments('default') or {
	console.print_header('Warning: Failed to get deployments')
	eprintln('${err}')
	eprintln('')
	[]kubernetes.Deployment{}
}

if deployments.len == 0 {
	println('No deployments found in the default namespace.')
	println('')
	println('To create a test deployment, run:')
	println('  kubectl create deployment nginx --image=nginx --replicas=3')
	println('')
} else {
	println('Found ${deployments.len} deployment(s) in the default namespace:')
	println('')

	for i, deploy in deployments {
		ready_status := if deploy.ready_replicas == deploy.replicas { '✓' } else { '⚠' }

		println('┌─────────────────────────────────────────────────────────────┐')
		println('│ Deployment #${i + 1:-53}│')
		println('├─────────────────────────────────────────────────────────────┤')
		println('│ Name:              ${deploy.name:-44}│')
		println('│ Namespace:         ${deploy.namespace:-44}│')
		println('│ Replicas:          ${deploy.replicas.str():-44}│')
		println('│ Ready Replicas:    ${deploy.ready_replicas.str():-44}│')
		println('│ Available:         ${deploy.available_replicas.str():-44}│')
		println('│ Updated:           ${deploy.updated_replicas.str():-44}│')
		println('│ Status:            ${ready_status:-44}│')
		println('│ Created:           ${deploy.created_at:-44}│')

		if deploy.labels.len > 0 {
			println('│ Labels:                                                     │')
			for key, value in deploy.labels {
				label_str := '  ${key}=${value}'
				println('│   ${label_str:-58}│')
			}
		}

		println('└─────────────────────────────────────────────────────────────┘')
		println('')
	}
}

// ============================================================================
// 4. Get Services in the 'default' namespace
// ============================================================================
console.print_header('4. Services in "default" Namespace')
println('[INFO] Retrieving services from the default namespace...')
println('')

services := client.get_services('default') or {
	console.print_header('Warning: Failed to get services')
	eprintln('${err}')
	eprintln('')
	[]kubernetes.Service{}
}

if services.len == 0 {
	println('No services found in the default namespace.')
	println('')
	println('To create a test service, run:')
	println('  kubectl expose deployment nginx --port=80 --type=ClusterIP')
	println('')
} else {
	println('Found ${services.len} service(s) in the default namespace:')
	println('')

	for i, svc in services {
		println('┌─────────────────────────────────────────────────────────────┐')
		println('│ Service #${i + 1:-54}│')
		println('├─────────────────────────────────────────────────────────────┤')
		println('│ Name:          ${svc.name:-48}│')
		println('│ Namespace:     ${svc.namespace:-48}│')
		println('│ Type:          ${svc.service_type:-48}│')
		println('│ Cluster IP:    ${svc.cluster_ip:-48}│')

		if svc.external_ip.len > 0 {
			println('│ External IP:   ${svc.external_ip:-48}│')
		}

		if svc.ports.len > 0 {
			println('│ Ports:         ${svc.ports.join(', '):-48}│')
		}

		println('│ Created:       ${svc.created_at:-48}│')

		if svc.labels.len > 0 {
			println('│ Labels:                                                     │')
			for key, value in svc.labels {
				label_str := '  ${key}=${value}'
				println('│   ${label_str:-58}│')
			}
		}

		println('└─────────────────────────────────────────────────────────────┘')
		println('')
	}
}

// ============================================================================
// Summary
// ============================================================================
console.print_header('Summary')
println('✓ Successfully demonstrated Kubernetes client functionality')
println('✓ Cluster information retrieved and parsed')
println('✓ Pods: ${pods.len} found')
println('✓ Deployments: ${deployments.len} found')
println('✓ Services: ${services.len} found')
println('')
println('All JSON parsing operations completed successfully!')
println('')
println('╔════════════════════════════════════════════════════════════════╗')
println('║                    Example Complete                            ║')
println('╚════════════════════════════════════════════════════════════════╝')
