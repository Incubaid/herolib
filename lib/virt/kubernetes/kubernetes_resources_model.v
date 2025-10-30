module kubernetes

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
	name              string
	image             string
	image_pull_policy string = 'IfNotPresent'
	ports             []ContainerPort
	env               []EnvVar
	resources         ResourceRequirements
	volume_mounts     []VolumeMount
	command           []string
	args              []string
}

@[params]
pub struct ContainerPort {
pub mut:
	name           string
	container_port int
	protocol       string = 'TCP'
	host_port      int
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
	metadata                  K8sMetadata
	replicas                  int = 1
	selector                  map[string]string
	template                  PodSpec
	strategy                  DeploymentStrategy
	progress_deadline_seconds int = 600
}

@[params]
pub struct DeploymentStrategy {
pub mut:
	strategy_type  string = 'RollingUpdate'
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
	metadata         K8sMetadata
	service_type     string = 'ClusterIP' // ClusterIP, NodePort, LoadBalancer
	selector         map[string]string
	ports            []ServicePort
	cluster_ip       string
	external_ips     []string
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
	metadata    K8sMetadata
	secret_type string = 'Opaque'
	data        map[string]string // base64 encoded
}

// Kube Client Configuration
@[params]
pub struct KubeConfig {
pub mut:
	kubeconfig_path          string
	context                  string
	namespace                string = 'default'
	api_server               string
	ca_cert_path             string
	client_cert_path         string
	client_key_path          string
	token                    string
	insecure_skip_tls_verify bool
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

// ============================================================================
// Kubectl JSON Response Structs
// These structs match the JSON structure returned by kubectl commands
// ============================================================================

// Version response from 'kubectl version -o json'
struct KubectlVersionResponse {
	server_version ServerVersionInfo @[json: serverVersion]
}

struct ServerVersionInfo {
	git_version string @[json: gitVersion]
	major       string
	minor       string
}

// Generic list response structure
struct KubectlListResponse {
	items []KubectlItemMetadata
}

struct KubectlItemMetadata {
	metadata KubectlMetadata
}

struct KubectlMetadata {
	name string
}

// Pod list response from 'kubectl get pods -o json'
struct KubectlPodListResponse {
	items []KubectlPodItem
}

struct KubectlPodItem {
	metadata KubectlPodMetadata
	spec     KubectlPodSpec
	status   KubectlPodStatus
}

struct KubectlPodMetadata {
	name               string
	namespace          string
	labels             map[string]string
	creation_timestamp string @[json: creationTimestamp]
}

struct KubectlPodSpec {
	node_name  string @[json: nodeName]
	containers []KubectlContainer
}

struct KubectlContainer {
	name  string
	image string
}

struct KubectlPodStatus {
	phase  string
	pod_ip string @[json: podIP]
}

// Deployment list response from 'kubectl get deployments -o json'
struct KubectlDeploymentListResponse {
	items []KubectlDeploymentItem
}

struct KubectlDeploymentItem {
	metadata KubectlDeploymentMetadata
	spec     KubectlDeploymentSpec
	status   KubectlDeploymentStatus
}

struct KubectlDeploymentMetadata {
	name               string
	namespace          string
	labels             map[string]string
	creation_timestamp string @[json: creationTimestamp]
}

struct KubectlDeploymentSpec {
	replicas int
}

struct KubectlDeploymentStatus {
	ready_replicas     int @[json: readyReplicas]
	available_replicas int @[json: availableReplicas]
	updated_replicas   int @[json: updatedReplicas]
}

// Service list response from 'kubectl get services -o json'
struct KubectlServiceListResponse {
	items []KubectlServiceItem
}

struct KubectlServiceItem {
	metadata KubectlServiceMetadata
	spec     KubectlServiceSpec
	status   KubectlServiceStatus
}

struct KubectlServiceMetadata {
	name               string
	namespace          string
	labels             map[string]string
	creation_timestamp string @[json: creationTimestamp]
}

struct KubectlServiceSpec {
	service_type string   @[json: type]
	cluster_ip   string   @[json: clusterIP]
	external_ips []string @[json: externalIPs]
	ports        []KubectlServicePort
}

struct KubectlServicePort {
	port     int
	protocol string
}

struct KubectlServiceStatus {
	load_balancer KubectlLoadBalancerStatus @[json: loadBalancer]
}

struct KubectlLoadBalancerStatus {
	ingress []KubectlLoadBalancerIngress
}

struct KubectlLoadBalancerIngress {
	ip string
}

// Node list response from 'kubectl get nodes -o json'
struct KubectlNodeListResponse {
	items []KubectlNodeItem
}

struct KubectlNodeItem {
	metadata KubectlNodeMetadata
	spec     KubectlNodeSpec
	status   KubectlNodeStatus
}

struct KubectlNodeMetadata {
	name               string
	labels             map[string]string
	creation_timestamp string @[json: creationTimestamp]
}

struct KubectlNodeSpec {
	pod_cidr string @[json: podCIDR]
}

struct KubectlNodeStatus {
	addresses  []KubectlNodeAddress
	conditions []KubectlNodeCondition
	node_info  KubectlNodeSystemInfo @[json: nodeInfo]
}

struct KubectlNodeAddress {
	address      string @[json: address]
	address_type string @[json: type]
}

struct KubectlNodeCondition {
	condition_type string @[json: type]
	status         string
}

struct KubectlNodeSystemInfo {
	architecture              string
	kernel_version            string @[json: kernelVersion]
	os_image                  string @[json: osImage]
	operating_system          string @[json: operatingSystem]
	kubelet_version           string @[json: kubeletVersion]
	container_runtime_version string @[json: containerRuntimeVersion]
}

// ============================================================================
// Runtime resource structs (returned from kubectl get commands)
// ============================================================================

// Pod runtime information
pub struct Pod {
pub mut:
	name       string
	namespace  string
	status     string
	node       string
	ip         string
	containers []string
	labels     map[string]string
	created_at string
}

// Deployment runtime information
pub struct Deployment {
pub mut:
	name               string
	namespace          string
	replicas           int
	ready_replicas     int
	available_replicas int
	updated_replicas   int
	labels             map[string]string
	created_at         string
}

// Service runtime information
pub struct Service {
pub mut:
	name         string
	namespace    string
	service_type string
	cluster_ip   string
	external_ip  string
	ports        []string
	labels       map[string]string
	created_at   string
}

// Node runtime information
pub struct Node {
pub mut:
	name              string
	internal_ip       string   // Primary internal IP (first in list)
	external_ip       string   // Primary external IP (first in list)
	internal_ips      []string // All internal IPs (for dual-stack support)
	external_ips      []string // All external IPs (for dual-stack support)
	hostname          string
	status            string // Ready, NotReady, Unknown
	roles             []string
	kubelet_version   string
	os_image          string
	kernel_version    string
	container_runtime string
	labels            map[string]string
	created_at        string
}

// Version information from kubectl version command
pub struct VersionInfo {
pub mut:
	major       string
	minor       string
	git_version string
	git_commit  string
	build_date  string
	platform    string
}
