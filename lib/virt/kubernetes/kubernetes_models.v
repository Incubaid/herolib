module kubernetes

import incubaid.herolib.data.ourtime

// ==================== METADATA ====================

@[params]
pub struct ObjectMeta {
pub mut:
	name            string
	namespace       string = 'default'
	uid             string
	resource_version string
	creation_timestamp ourtime.OurTime
	deletion_timestamp ?ourtime.OurTime
	labels          map[string]string
	annotations     map[string]string
	owner_references []OwnerReference
	finalizers      []string
}

pub struct OwnerReference {
pub:
	api_version string
	kind        string
	name        string
	uid         string
	controller  bool
}

pub struct TypeMeta {
pub:
	api_version string = 'v1'
	kind        string
}

// ==================== POD ====================

@[params]
pub struct Pod {
pub mut:
	api_version string = 'v1'
	kind        string = 'Pod'
	metadata    ObjectMeta
	spec        PodSpec
	status      ?PodStatus
}

@[params]
pub struct PodSpec {
pub mut:
	containers            []Container
	init_containers       []Container
	restart_policy        string = 'Always' // Always, OnFailure, Never
	termination_grace_period_seconds int = 30
	dns_policy            string = 'ClusterFirst'
	service_account_name  string
	node_selector         map[string]string
	tolerations           []Toleration
	affinity              ?Affinity
	volumes               []Volume
	image_pull_secrets    []LocalObjectReference
}

@[params]
pub struct Container {
pub mut:
	name            string
	image           string
	image_pull_policy string = 'IfNotPresent'
	ports           []ContainerPort
	env             []EnvVar
	resources       ?ResourceRequirements
	volume_mounts   []VolumeMount
	liveness_probe  ?Probe
	readiness_probe ?Probe
	startup_probe   ?Probe
	security_context ?SecurityContext
	stdin           bool
	tty             bool
	working_dir     string
	command         []string
	args            []string
}

pub struct ContainerPort {
pub mut:
	name          string
	container_port int
	host_port     ?int
	protocol      string = 'TCP' // TCP, UDP
}

@[params]
pub struct EnvVar {
pub:
	name  string
	value ?string
	value_from ?EnvVarSource
}

pub struct EnvVarSource {
pub:
	config_map_key_ref ?ConfigMapKeySelector
	secret_key_ref     ?SecretKeySelector
}

pub struct ConfigMapKeySelector {
pub:
	name string
	key  string
}

pub struct SecretKeySelector {
pub:
	name string
	key  string
}

pub struct VolumeMount {
pub:
	name       string
	mount_path string
	read_only  bool
	sub_path   string
}

pub struct ResourceRequirements {
pub:
	limits   map[string]string // e.g. {"cpu": "500m", "memory": "512Mi"}
	requests map[string]string
}

pub struct Probe {
pub:
	exec            ?ExecAction
	http_get        ?HTTPGetAction
	tcp_socket      ?TCPSocketAction
	initial_delay_seconds int = 0
	timeout_seconds       int = 1
	period_seconds        int = 10
	success_threshold     int = 1
	failure_threshold     int = 3
}

pub struct ExecAction {
pub:
	command []string
}

pub struct HTTPGetAction {
pub:
	path   string
	port   int
	scheme string = 'HTTP'
}

pub struct TCPSocketAction {
pub:
	port int
}

pub struct SecurityContext {
pub:
	run_as_user       ?int
	run_as_group      ?int
	fs_group          ?int
	read_only_root_fs bool
	allow_privilege_escalation bool
}

pub struct Toleration {
pub:
	key               string
	operator          string // Equal, Exists
	value             string
	effect            string // NoSchedule, NoExecute, PreferNoSchedule
	toleration_seconds ?int
}

pub struct Affinity {
pub:
	pod_affinity      ?PodAffinity
	pod_anti_affinity ?PodAntiAffinity
	node_affinity     ?NodeAffinity
}

pub struct PodAffinity {
pub:
	required_during_scheduling []PodAffinityTerm
	preferred_during_scheduling []WeightedPodAffinityTerm
}

pub struct PodAffinityTerm {
pub:
	label_selector map[string]string
	topology_key   string
}

pub struct WeightedPodAffinityTerm {
pub:
	weight            int
	pod_affinity_term PodAffinityTerm
}

pub struct PodAntiAffinity {
pub:
	required_during_scheduling []PodAffinityTerm
	preferred_during_scheduling []WeightedPodAffinityTerm
}

pub struct NodeAffinity {
pub:
	required_during_scheduling ?NodeSelector
	preferred_during_scheduling []PreferredSchedulingTerm
}

pub struct NodeSelector {
pub:
	node_selector_terms []NodeSelectorTerm
}

pub struct NodeSelectorTerm {
pub:
	match_expressions []NodeSelectorRequirement
}

pub struct NodeSelectorRequirement {
pub:
	key      string
	operator string // In, NotIn, Exists, NotExists, Gt, Lt
	values   []string
}

pub struct PreferredSchedulingTerm {
pub:
	weight     int
	preference NodeSelectorTerm
}

pub struct Volume {
pub mut:
	name string
	empty_dir    ?EmptyDirVolumeSource
	config_map   ?ConfigMapVolumeSource
	secret       ?SecretVolumeSource
	persistent_volume_claim ?PersistentVolumeClaimVolumeSource
	host_path    ?HostPathVolumeSource
}

pub struct EmptyDirVolumeSource {
pub:
	medium string
	size_limit string
}

pub struct ConfigMapVolumeSource {
pub:
	name         string
	default_mode int
	items        []KeyToPath
}

pub struct SecretVolumeSource {
pub:
	secret_name  string
	default_mode int
	items        []KeyToPath
}

pub struct KeyToPath {
pub:
	key  string
	path string
	mode int
}

pub struct PersistentVolumeClaimVolumeSource {
pub:
	claim_name string
	read_only  bool
}

pub struct HostPathVolumeSource {
pub:
	path string
	type string // Directory, File, Socket, CharDevice, BlockDevice
}

pub struct LocalObjectReference {
pub:
	name string
}

pub struct PodStatus {
pub:
	phase             string // Pending, Running, Succeeded, Failed, Unknown
	conditions        []PodCondition
	host_ip           string
	pod_ip            string
	container_statuses []ContainerStatus
}

pub struct PodCondition {
pub:
	type_   string // Initialized, Ready, ContainersReady, PodScheduled
	status  string // True, False, Unknown
	reason  string
	message string
	last_probe_time ourtime.OurTime
	last_transition_time ourtime.OurTime
}

pub struct ContainerStatus {
pub:
	name        string
	state       ContainerState
	ready       bool
	restart_count int
	image       string
	image_id    string
}

pub struct ContainerState {
pub:
	waiting    ?ContainerStateWaiting
	running    ?ContainerStateRunning
	terminated ?ContainerStateTerminated
}

pub struct ContainerStateWaiting {
pub:
	reason  string
	message string
}

pub struct ContainerStateRunning {
pub:
	started_at ourtime.OurTime
}

pub struct ContainerStateTerminated {
pub:
	exit_code    int
	signal       int
	reason       string
	message      string
	started_at   ourtime.OurTime
	finished_at  ourtime.OurTime
	container_id string
}

// ==================== DEPLOYMENT ====================

@[params]
pub struct Deployment {
pub mut:
	api_version string = 'apps/v1'
	kind        string = 'Deployment'
	metadata    ObjectMeta
	spec        DeploymentSpec
	status      ?DeploymentStatus
}

@[params]
pub struct DeploymentSpec {
pub mut:
	replicas             int = 1
	selector             ?LabelSelector
	template             PodTemplateSpec
	strategy             ?DeploymentStrategy
	min_ready_seconds    int
	revision_history_limit int
	paused               bool
	progress_deadline_seconds int
}

pub struct PodTemplateSpec {
pub:
	metadata ObjectMeta
	spec     PodSpec
}

pub struct LabelSelector {
pub:
	match_labels      map[string]string
	match_expressions []LabelSelectorRequirement
}

pub struct LabelSelectorRequirement {
pub:
	key      string
	operator string // In, NotIn, Exists, DoesNotExist
	values   []string
}

pub struct DeploymentStrategy {
pub:
	type_ string // RollingUpdate, Recreate
	rolling_update ?RollingUpdateDeploymentStrategy
}

pub struct RollingUpdateDeploymentStrategy {
pub:
	max_surge       string
	max_unavailable string
}

pub struct DeploymentStatus {
pub:
	observed_generation  int
	replicas             int
	updated_replicas     int
	ready_replicas       int
	available_replicas   int
	unavailable_replicas int
	conditions           []DeploymentCondition
}

pub struct DeploymentCondition {
pub:
	type_   string // Progressing, Available, ReplicaFailure
	status  string // True, False, Unknown
	reason  string
	message string
	last_update_time ourtime.OurTime
	last_transition_time ourtime.OurTime
}

// ==================== SERVICE ====================

@[params]
pub struct Service {
pub mut:
	api_version string = 'v1'
	kind        string = 'Service'
	metadata    ObjectMeta
	spec        ServiceSpec
	status      ?ServiceStatus
}

@[params]
pub struct ServiceSpec {
pub mut:
	service_type string = 'ClusterIP' // ClusterIP, NodePort, LoadBalancer, ExternalName
	selector    map[string]string
	ports       []ServicePort
	cluster_ip  string
	external_ips []string
	load_balancer_ip string
	external_name string
	session_affinity string // None, ClientIP
	session_affinity_timeout int
}

pub struct ServicePort {
pub:
	name       string
	protocol   string = 'TCP'
	port       int
	target_port string // can be int or string
	node_port  ?int
}

pub struct ServiceStatus {
pub:
	load_balancer ?LoadBalancerStatus
}

pub struct LoadBalancerStatus {
pub:
	ingress []LoadBalancerIngress
}

pub struct LoadBalancerIngress {
pub:
	ip       string
	hostname string
}

// ==================== CONFIGMAP ====================

@[params]
pub struct ConfigMap {
pub mut:
	api_version string = 'v1'
	kind        string = 'ConfigMap'
	metadata    ObjectMeta
	data        map[string]string
	binary_data map[string][]u8
}

// ==================== SECRET ====================

@[params]
pub struct Secret {
pub mut:
	api_version string = 'v1'
	kind        string = 'Secret'
	metadata    ObjectMeta
	type_       string = 'Opaque' // Opaque, kubernetes.io/service-account-token, etc.
	data        map[string][]u8
	string_data map[string]string
}

// ==================== NAMESPACE ====================

@[params]
pub struct Namespace {
pub mut:
	api_version string = 'v1'
	kind        string = 'Namespace'
	metadata    ObjectMeta
	spec        NamespaceSpec
	status      ?NamespaceStatus
}

pub struct NamespaceSpec {
pub:
	finalizers []string
}

pub struct NamespaceStatus {
pub:
	phase string // Active, Terminating
}

// ==================== PERSISTENT VOLUME CLAIM ====================

@[params]
pub struct PersistentVolumeClaim {
pub mut:
	api_version string = 'v1'
	kind        string = 'PersistentVolumeClaim'
	metadata    ObjectMeta
	spec        PersistentVolumeClaimSpec
	status      ?PersistentVolumeClaimStatus
}

@[params]
pub struct PersistentVolumeClaimSpec {
pub mut:
	access_modes            []string // ReadWriteOnce, ReadOnlyMany, ReadWriteMany
	resources               ResourceRequirements
	storage_class_name      string
	selector                ?LabelSelector
	volume_name             string
}

pub struct PersistentVolumeClaimStatus {
pub:
	phase       string // Pending, Bound, Lost
	access_modes []string
	capacity    map[string]string
}

// ==================== INGRESS ====================

@[params]
pub struct Ingress {
pub mut:
	api_version string = 'networking.k8s.io/v1'
	kind        string = 'Ingress'
	metadata    ObjectMeta
	spec        IngressSpec
	status      ?IngressStatus
}

@[params]
pub struct IngressSpec {
pub mut:
	ingress_class_name string
	rules              []IngressRule
	tls                []IngressTLS
	default_backend    ?IngressBackend
}

pub struct IngressRule {
pub:
	host string
	http ?HTTPIngressRuleValue
}

pub struct HTTPIngressRuleValue {
pub:
	paths []HTTPIngressPath
}

pub struct HTTPIngressPath {
pub:
	path     string
	path_type string // Exact, Prefix
	backend  IngressBackend
}

pub struct IngressBackend {
pub:
	service ?IngressServiceBackend
}

pub struct IngressServiceBackend {
pub:
	name string
	port IngressServiceBackendPort
}

pub struct IngressServiceBackendPort {
pub:
	number int
	name   string
}

pub struct IngressTLS {
pub:
	hosts []string
	secret_name string
}

pub struct IngressStatus {
pub:
	load_balancer LoadBalancerStatus
}