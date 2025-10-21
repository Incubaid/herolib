module kubernetes

import incubaid.herolib.core.pathlib
import os

@[params]
pub struct KubernetesConfig {
pub mut:
	name              string = 'default'
	server            string       // API server URL (e.g., https://localhost:6443)
	certificate_authority string   // Path to CA cert
	client_certificate string      // Path to client cert
	client_key        string       // Path to client key
	username          string
	password          string       @[secret]
	token             string       @[secret]
	insecure_skip_verify bool      // Skip TLS verification (not recommended)
	namespace         string = 'default'
	timeout_seconds   int = 30
	context_name      string = 'default'
	cluster_name      string = 'default'
}

pub struct KubernetesContext {
pub mut:
	config   KubernetesConfig
	client   &KubernetesClient
}

// Load kubeconfig from standard location (~/.kube/config)
pub fn load_kubeconfig(name string) !KubernetesConfig {
	mut config_path := pathlib.get('~/.kube/config')!
	if !config_path.exists() {
		return error('kubeconfig not found at ${config_path.path}')
	}
	
	// Parse YAML kubeconfig file
	content := config_path.read()!
	// TODO: Parse YAML and extract config for specified context
	
	return KubernetesConfig{name: name}
}

// Load from in-memory config
pub fn load_config(cfg KubernetesConfig) !KubernetesConfig {
	if cfg.server == '' {
		return error('server URL must be provided')
	}
	return cfg
}

// Validate configuration
pub fn (cfg KubernetesConfig) validate() ! {
	if cfg.server == '' {
		return error('server URL is required')
	}
	if !cfg.insecure_skip_verify {
		if cfg.certificate_authority == '' {
			return error('certificate_authority is required when insecure_skip_verify is false')
		}
	}
	if cfg.token == '' && (cfg.username == '' || cfg.password == '') {
		return error('either token or username/password must be provided')
	}
}