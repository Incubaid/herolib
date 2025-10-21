module kubernetes

import incubaid.herolib.data.paramsparser
import incubaid.herolib.data.encoderhero
import incubaid.herolib.data.ourjson
import os

pub const version = '1.0.0'
const singleton = false
const default = true

// K8s API Version and Kind tracking
@[params]
pub struct K8sMetadata {
pub mut:
	name            string
	namespace       string = 'default'
	labels          map[string]string
	annotations     map[string]string
	owner_reference string
}

// Pod Specification
@[params]
pub struct ContainerSpec {
pub mut:
	name            string
	image           string
	image_pull_policy string = 'IfNotPresent'
	ports           []ContainerPort
	env             []EnvVar
	resources       ResourceRequirements
	volume_mounts   []VolumeMount
	command         []string
	args            []string
}

@[params]
pub struct ContainerPort {
pub mut:
	name          string
	container_port int
	protocol      string = 'TCP'
	host_port     int
}

@[params]
pub struct EnvVar {
pub mut:
	name  string
	value string
}

@[params]
pub struct ResourceRequirements {
pub mut:
	requests map[string]string // cpu, memory
	limits   map[string]string
}

@[params]
pub struct VolumeMount {
pub mut:
	name       string
	mount_path string
	read_only  bool
}

@[params]
pub struct PodSpec {
pub mut:
	metadata        K8sMetadata
	containers      []ContainerSpec
	restart_policy  string = 'Always'
	service_account string
	volumes         []Volume
}

@[params]
pub struct Volume {
pub mut:
	name       string
	config_map string
	secret     string
	empty_dir  bool
}

// Deployment Specification
@[params]
pub struct DeploymentSpec {
pub mut:
	metadata    K8sMetadata
	replicas    int = 1
	selector    map[string]string
	template    PodSpec
	strategy    DeploymentStrategy
	progress_deadline_seconds int = 600
}

@[params]
pub struct DeploymentStrategy {
pub mut:
	strategy_type string = 'RollingUpdate'
	rolling_update RollingUpdateStrategy
}

@[params]
pub struct RollingUpdateStrategy {
pub mut:
	max_surge       string = '25%'
	max_unavailable string = '25%'
}

// Service Specification
@[params]
pub struct ServiceSpec {
pub mut:
	metadata       K8sMetadata
	service_type   string = 'ClusterIP' // ClusterIP, NodePort, LoadBalancer
	selector       map[string]string
	ports          []ServicePort
	cluster_ip     string
	external_ips   []string
	session_affinity string
}

@[params]
pub struct ServicePort {
pub mut:
	name        string
	protocol    string = 'TCP'
	port        int
	target_port int
	node_port   int
}

// ConfigMap
@[params]
pub struct ConfigMapSpec {
pub mut:
	metadata K8sMetadata
	data     map[string]string
}

// Secret
@[params]
pub struct SecretSpec {
pub mut:
	metadata  K8sMetadata
	secret_type string = 'Opaque'
	data      map[string]string // base64 encoded
}

// Kube Client Configuration
@[params]
pub struct KubeConfig {
pub mut:
	kubeconfig_path string
	context         string = ''
	namespace       string = 'default'
	api_server      string
	ca_cert_path    string
	client_cert_path string
	client_key_path  string
	token           string
	insecure_skip_tls_verify bool
}

@[heap]
pub struct KubeClient {
pub mut:
	name              string = 'default'
	kubeconfig_path   string
	config            KubeConfig
	connected         bool
	api_version       string = 'v1'
	kubectl_path      string = 'kubectl'
	cache_enabled     bool = true
	cache_ttl_seconds int = 300
}

// Validation result for YAML files
pub struct K8sValidationResult {
pub mut:
	valid       bool
	kind        string
	api_version string
	metadata    K8sMetadata
	errors      []string
}

// Cluster info
pub struct ClusterInfo {
pub mut:
	version      string
	nodes        int
	namespaces   int
	running_pods int
	api_server   string
}

// Initialization
fn obj_init(mut cfg KubeClient) !KubeClient {
	// Resolve kubeconfig path
	if cfg.kubeconfig_path.is_empty() {
		home := os.home_dir()
		cfg.kubeconfig_path = '${home}/.kube/config'
	}

	// Ensure kubeconfig exists
	if !os.path_exists(cfg.kubeconfig_path) {
		return error('kubeconfig not found at ${cfg.kubeconfig_path}')
	}

	cfg.config.kubeconfig_path = cfg.kubeconfig_path

	return cfg
}

fn configure() ! {
	// Configure any defaults or environment-specific settings
}

pub fn heroscript_loads(heroscript string) !KubeClient {
	mut obj := encoderhero.decode[KubeClient](heroscript)!
	return obj_init(obj)!
}
