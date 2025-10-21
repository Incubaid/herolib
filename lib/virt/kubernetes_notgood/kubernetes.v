module kubernetes

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import json

__global (
	kubernetes_clients map[string]&KubernetesClient
	default_client_name string
)

@[params]
pub struct ClientGetArgs {
pub mut:
	name   string = 'default'
	config ?KubernetesConfig
	create bool = true
}

// Get or create a Kubernetes client
pub fn get_client(args ClientGetArgs) !&KubernetesClient {
	if args.name in kubernetes_clients {
		return kubernetes_clients[args.name] or {
			return error('Failed to retrieve client: ${args.name}')
		}
	}
	
	if args.config != none {
		mut cfg := args.config!
		cfg.name = args.name
		mut client := new(cfg)!
		kubernetes_clients[args.name] = client
		default_client_name = args.name
		return client
	}
	
	// Try to load from kubeconfig
	cfg := load_kubeconfig(args.name) or {
		if args.create {
			return error('No kubeconfig found and create=false')
		}
		return err
	}
	
	mut client := new(cfg)!
	kubernetes_clients[args.name] = client
	default_client_name = args.name
	return client
}

// Use a specific client as default
pub fn use_client(name string) ! {
	if name !in kubernetes_clients {
		return error('Client ${name} not found')
	}
	default_client_name = name
}

// Get default client
pub fn client() !&KubernetesClient {
	if default_client_name == '' {
		default_client_name = 'default'
	}
	
	if default_client_name !in kubernetes_clients {
		// Try to load default from kubeconfig
		return get_client(name: 'default', create: true)!
	}
	
	return kubernetes_clients[default_client_name] or {
		return error('Default client not available')
	}
}

// Register a client
pub fn register_client(name string, cfg KubernetesConfig) !&KubernetesClient {
	mut client := new(cfg)!
	kubernetes_clients[name] = client
	return client
}

// List all registered clients
pub fn list_clients() []string {
	mut result := []string{}
	for name, _ in kubernetes_clients {
		result << name
	}
	return result
}

// Play HeroScript for Kubernetes
pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'kubernetes.') {
		return
	}
	
	// Handle configuration actions
	configure_actions := plbook.find(filter: 'kubernetes.configure')!
	for mut action in configure_actions {
		mut p := action.params
		name := p.get_default('name', 'default')!
		server := p.get('server')!
		token := p.get_default('token', '')!
		
		cfg := KubernetesConfig{
			name: name
			server: server
			token: token
		}
		
		register_client(name, cfg)!
		action.done = true
	}
	
	// Handle resource actions (create, delete, scale, etc.)
	resource_actions := plbook.find(filter: 'kubernetes.')!
	for mut action in resource_actions {
		mut p := action.params
		client_name := p.get_default('client', 'default')!
		mut client := get_client(name: client_name)!
		
		match action.name {
			'deploy' {
				// Handle deployment
				// yaml_content := p.get('yaml')!
				// deployment := from_yaml[Deployment](yaml_content)!
				// client.deploy(deployment: deployment)!
			}
			'delete' {
				resource_type := p.get('resource_type')!
				resource_name := p.get('name')!
				namespace := p.get_default('namespace', 'default')!
				client.delete_resource(
					resource_type: resource_type
					name: resource_name
					namespace: namespace
				)!
			}
			'scale' {
				deployment_name := p.get('deployment')!
				replicas := p.get_int('replicas')!
				client.scale_deployment(
					deployment_name: deployment_name
					replicas: replicas
				)!
			}
			else {}
		}
		action.done = true
	}
}