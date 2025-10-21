module kubernetes

import incubaid.herolib.core.httpconnection
import net.http
import json
import encoding.base64

@[heap]
pub struct KubernetesClient {
pub mut:
	config     KubernetesConfig
	http_conn  ?&httpconnection.HTTPConnection
	api_groups map[string]APIGroupVersion
}

pub struct APIGroupVersion {
pub:
	group_version string
	resources     []APIResource
}

pub struct APIResource {
pub:
	name       string
	singularname string
	namespaced bool
	kind       string
	verbs      []string // get, list, create, update, delete, patch, watch, etc.
}

pub struct APIResponse {
pub:
	kind       string
	api_version string
	metadata   map[string]interface{}
	items      []json.Any
}

// Create new Kubernetes client
pub fn new(config KubernetesConfig) !&KubernetesClient {
	mut cfg := config
	cfg.validate()!
	
	mut client := KubernetesClient{
		config: cfg
	}
	client.http_conn = http_connection_create(cfg)!
	
	return &client
}

// Create HTTP connection with proper auth
fn http_connection_create(cfg KubernetesConfig) !&httpconnection.HTTPConnection {
	mut conn := httpconnection.new(
		name:  'kubernetes-${cfg.name}'
		url:   cfg.server
		retry: 3
		cache: false
	)!
	
	// Setup authentication
	if cfg.token.len > 0 {
		mut header := http.new_header()
		header.add(.authorization, 'Bearer ${cfg.token}')
		conn.default_header = header
	} else if cfg.username.len > 0 && cfg.password.len > 0 {
		conn.basic_auth(cfg.username, cfg.password)
	}
	
	// TLS configuration
	if cfg.insecure_skip_verify {
		// Skip verification (development only)
	} else if cfg.certificate_authority.len > 0 {
		// Load CA certificate
		// TODO: Configure TLS with CA cert
	}
	
	return conn
}

// Get HTTP connection
pub fn (mut c KubernetesClient) connection() !&httpconnection.HTTPConnection {
	if c.http_conn == none {
		c.http_conn = http_connection_create(c.config)!
	}
	return c.http_conn!
}

// ==================== DISCOVERY API ====================

// Get available API groups
pub fn (mut c KubernetesClient) get_api_groups() ![]APIGroupVersion {
	conn := c.connection()!
	response := conn.get_json_generic[map[string]interface{}](
		prefix: '/apis'
	)!
	// Parse and return API groups
	return []APIGroupVersion{}
}

// ==================== CORE API METHODS ====================

// Generic GET for any resource
pub fn (mut c KubernetesClient) get[T](
	resource_type string
	name string
	namespace string = ''
) !T {
	mut prefix := build_api_path(resource_type, name, namespace)
	conn := c.connection()!
	return conn.get_json_generic[T](prefix: prefix)!
}

// Generic LIST for any resource
pub fn (mut c KubernetesClient) list[T](
	resource_type string
	namespace string = ''
	label_selector string = ''
) ![]T {
	mut prefix := build_api_list_path(resource_type, namespace)
	if label_selector.len > 0 {
		prefix += '?labelSelector=${label_selector}'
	}
	conn := c.connection()!
	response := conn.get_json_generic[map[string]interface{}](prefix: prefix)!
	// Parse items array
	return []T{}
}

// Generic CREATE for any resource
pub fn (mut c KubernetesClient) create[T](resource T) !T {
	resource_type := get_resource_type[T]()
	namespace := get_namespace[T](resource)
	mut prefix := build_api_path_create(resource_type, namespace)
	
	conn := c.connection()!
	return conn.post_json_generic[T](
		prefix: prefix
		params: json.decode_object(json.encode(resource))!
	)!
}

// Generic UPDATE (PUT) for any resource
pub fn (mut c KubernetesClient) update[T](resource T) !T {
	resource_type := get_resource_type[T]()
	name := get_resource_name[T](resource)
	namespace := get_namespace[T](resource)
	mut prefix := build_api_path(resource_type, name, namespace)
	
	conn := c.connection()!
	return conn.put_json_generic[T](
		prefix: prefix
		params: json.decode_object(json.encode(resource))!
	)!
}

// Generic PATCH for any resource
pub fn (mut c KubernetesClient) patch[T](
	resource_type string
	name string
	namespace string
	patch_data map[string]interface{}
) !T {
	mut prefix := build_api_path(resource_type, name, namespace)
	
	conn := c.connection()!
	mut header := http.new_header()
	header.add(.content_type, 'application/merge-patch+json')
	
	return conn.patch_json_generic[T](
		prefix: prefix
		params: patch_data
		header: header
	)!
}

// Generic DELETE for any resource
pub fn (mut c KubernetesClient) delete(
	resource_type string
	name string
	namespace string = ''
) ! {
	mut prefix := build_api_path(resource_type, name, namespace)
	conn := c.connection()!
	conn.delete(prefix: prefix)!
}

// Helper functions for building API paths
fn build_api_path(resource_type string, name string, namespace string) string {
	if namespace.len > 0 {
		return '/api/v1/namespaces/${namespace}/${resource_type}/${name}'
	} else {
		return '/api/v1/${resource_type}/${name}'
	}
}

fn build_api_list_path(resource_type string, namespace string) string {
	if namespace.len > 0 {
		return '/api/v1/namespaces/${namespace}/${resource_type}'
	} else {
		return '/api/v1/${resource_type}'
	}
}

fn build_api_path_create(resource_type string, namespace string) string {
	return build_api_list_path(resource_type, namespace)
}

// Helper functions to extract metadata from generic types
fn get_resource_type[T]() string {
	// TODO: Use compile-time reflection to get Kind from T
	return 'pods'
}

fn get_resource_name[T](resource T) string {
	// TODO: Extract metadata.name from resource
	return ''
}

fn get_namespace[T](resource T) string {
	// TODO: Extract metadata.namespace from resource
	return 'default'
}