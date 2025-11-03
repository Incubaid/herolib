module element_chat

import incubaid.herolib.ui.console
import incubaid.herolib.data.encoderhero
import incubaid.herolib.virt.kubernetes
import incubaid.herolib.core.pathlib
import strings

pub const version = '0.0.0'
const singleton = false
const default = false

struct ConfigValues {
pub mut:
	matrix_hostname    string // The Matrix homeserver hostname
	element_hostname   string // The Element web hostname
	backends           string // The backends for the TFGW
	namespace          string // The namespace for the Element Chat deployment
	conduit_port       int    // Conduit server port
	database_backend   string // Database backend (rocksdb, sqlite)
	database_path      string // Database path
	allow_registration bool   // Allow user registration
	allow_federation   bool   // Allow federation with other Matrix servers
	log_level          string // Log level (info, debug, warn, error)
	element_brand      string // Element branding name
	conduit_toml       string // Generated conduit.toml content
	element_json       string // Generated element-config.json content
}

@[heap]
pub struct ElementChat {
pub mut:
	name             string = 'elementchat'
	matrix_hostname  string
	element_hostname string
	namespace        string
	// Conduit configuration
	conduit_port       int    = 6167
	database_backend   string = 'rocksdb'
	database_path      string = '/var/lib/matrix-conduit'
	allow_registration bool   = true
	allow_federation   bool   = true
	log_level          string = 'info'
	// Element configuration
	element_brand string = 'Element'
	// Internal paths
	chat_app_path    string = '/tmp/element_chat/chat-app.yaml'
	tfgw_path        string = '/tmp/element_chat/tfgw-element.yaml'
	conduit_cfg_path string = '/tmp/element_chat/conduit.toml'
	element_cfg_path string = '/tmp/element_chat/element-config.json'
	kube_client      kubernetes.KubeClient @[skip]
}

// your checking & initialization code if needed
fn obj_init(mycfg_ ElementChat) !ElementChat {
	mut mycfg := mycfg_

	if mycfg.name == '' {
		mycfg.name = 'elementchat'
	}

	// Replace the dashes, dots, and underscores with nothing
	mycfg.name = mycfg.name.replace('_', '')
	mycfg.name = mycfg.name.replace('-', '')
	mycfg.name = mycfg.name.replace('.', '')

	if mycfg.namespace == '' {
		mycfg.namespace = '${mycfg.name}-element-chat-namespace'
	}

	if mycfg.namespace.contains('_') || mycfg.namespace.contains('.') {
		console.print_stderr('namespace cannot contain _, was: ${mycfg.namespace}, use dashes instead.')
		return error('namespace cannot contain _, was: ${mycfg.namespace}')
	}

	if mycfg.matrix_hostname == '' {
		mycfg.matrix_hostname = '${mycfg.name}matrix'
	}

	if mycfg.element_hostname == '' {
		mycfg.element_hostname = '${mycfg.name}element'
	}

	mycfg.kube_client = kubernetes.get(create: true)!
	mycfg.kube_client.config.namespace = mycfg.namespace
	return mycfg
}

// called before start if done
fn configure() ! {
	mut installer := get()!

	master_ips := get_master_node_ips()!
	console.print_info('Master node IPs: ${master_ips}')

	mut backends_str_builder := strings.new_builder(100)
	for ip in master_ips {
		backends_str_builder.writeln('    - "http://[${ip}]:80"')
	}

	console.print_info('Generating configuration files from templates...')

	// Create config_values for template generation
	mut config_values := ConfigValues{
		matrix_hostname:    installer.matrix_hostname
		element_hostname:   installer.element_hostname
		backends:           backends_str_builder.str()
		namespace:          installer.namespace
		conduit_port:       installer.conduit_port
		database_backend:   installer.database_backend
		database_path:      installer.database_path
		allow_registration: installer.allow_registration
		allow_federation:   installer.allow_federation
		log_level:          installer.log_level
		element_brand:      installer.element_brand
		conduit_toml:       ''
		element_json:       ''
	}

	// Generate conduit.toml and element-config.json
	conduit_toml_raw := $tmpl('./templates/conduit.toml.temp')
	element_json_raw := $tmpl('./templates/element-config.json')

	// Indent the configs for proper YAML formatting (4 spaces for ConfigMap data)
	conduit_toml_lines := conduit_toml_raw.split('\n')
	mut conduit_toml_indented := strings.new_builder(conduit_toml_raw.len + 100)
	for line in conduit_toml_lines {
		if line.len > 0 {
			conduit_toml_indented.writeln('    ${line}')
		}
	}

	element_json_lines := element_json_raw.split('\n')
	mut element_json_indented := strings.new_builder(element_json_raw.len + 100)
	for line in element_json_lines {
		if line.len > 0 {
			element_json_indented.writeln('    ${line}')
		}
	}

	// Update config_values with the generated and indented configs
	config_values.conduit_toml = conduit_toml_indented.str()
	config_values.element_json = element_json_indented.str()

	// Ensure the output directory exists
	_ := pathlib.get_dir(path: '/tmp/element_chat', create: true)!

	// Generate TFGW YAML
	tfgw_yaml := $tmpl('./templates/tfgw.yaml')
	mut tfgw_path := pathlib.get_file(
		path:   installer.tfgw_path
		create: true
		check:  true
	)!
	tfgw_path.write(tfgw_yaml)!

	// Generate chat-app YAML
	chat_app_yaml := $tmpl('./templates/chat-app.yaml')
	mut chat_app_path := pathlib.get_file(path: installer.chat_app_path, create: true)!
	chat_app_path.write(chat_app_yaml)!

	console.print_info('Configuration files generated successfully.')
}

// Get Kubernetes master node IPs
fn get_master_node_ips() ![]string {
	mut master_ips := []string{}
	installer := get()!

	// Get all nodes using the kubernetes client
	mut k8s := installer.kube_client
	nodes := k8s.get_nodes()!

	// Extract IPv6 internal IPs from all nodes (dual-stack support)
	for node in nodes {
		// Check all internal IPs (not just the first one) for IPv6 addresses
		for ip in node.internal_ips {
			if ip.len > 0 && ip.contains(':') {
				master_ips << ip
			}
		}
	}
	return master_ips
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !ElementChat {
	mut obj := encoderhero.decode[ElementChat](heroscript)!
	return obj
}
