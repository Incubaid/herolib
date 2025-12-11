module stalwart

import incubaid.herolib.ui.console
import incubaid.herolib.data.encoderhero
import incubaid.herolib.core.pathlib
import incubaid.herolib.k8_apps.core
import strings

pub const version = '0.0.0'
const singleton = false
const default = false

struct ConfigValues {
pub mut:
	hostname       string // The Stalwart hostname for TFGW
	backends       string // The backends for the TFGW
	namespace      string // The namespace for the Stalwart deployment
	http_port      int    // HTTP port for web UI/JMAP/DAV
	data_path      string // Data path inside container
	log_level      string // Log level (info, debug, warn, error)
	admin_user     string // Admin username
	admin_password string // Admin password
	storage_size   string // PVC storage size
	config_toml    string // Generated config.toml content
}

@[heap]
pub struct Stalwart {
pub mut:
	name      string = 'stalwart'
	hostname  string
	namespace string
	// Stalwart configuration
	http_port      int    = 8080
	data_path      string = '/opt/stalwart'
	log_level      string = 'info'
	admin_user     string = 'admin'
	admin_password string = 'changeme123' @[secret]
	storage_size   string = '20Gi'
	// Internal paths
	stalwart_app_path string = '/tmp/stalwart/stalwart-app.yaml'
	tfgw_path         string = '/tmp/stalwart/tfgw-stalwart.yaml'
	// K8App instance for kubernetes operations
	k8app ?core.K8App @[skip]
}

// your checking & initialization code if needed
fn obj_init(mycfg_ Stalwart) !Stalwart {
	mut mycfg := mycfg_

	if mycfg.name == '' {
		mycfg.name = 'stalwart'
	}

	// Use core name_fix for consistent name handling
	mycfg.name = core.name_fix(mycfg.name)

	if mycfg.namespace == '' {
		mycfg.namespace = '${mycfg.name}stalwartns'
	}

	// Apply name_fix to namespace for consistency with k8app
	mycfg.namespace = core.name_fix(mycfg.namespace)

	if mycfg.namespace.contains('.') {
		console.print_stderr('namespace cannot contain ., was: ${mycfg.namespace}')
		return error('namespace cannot contain ., was: ${mycfg.namespace}')
	}

	if mycfg.hostname == '' {
		mycfg.hostname = '${mycfg.name}mail'
	}

	// Validate hostname doesn't exceed TFGW limit
	mycfg.hostname = core.validate_hostname(mycfg.hostname)

	// Initialize K8App for kubernetes operations
	mycfg.k8app = core.k8app(
		app_name: 'stalwart'
		app_instance: mycfg.name
		namespace: mycfg.namespace
	)!
	return mycfg
}

// called before start if done
fn configure() ! {
	mut installer := get()!

	// Unwrap k8app once
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client

	master_ips := core.get_master_node_ips(mut k8s)!
	console.print_info('Master node IPs: ${master_ips}')

	mut backends_str_builder := strings.new_builder(100)
	for ip in master_ips {
		backends_str_builder.writeln('    - "http://[${ip}]:80"')
	}

	console.print_info('Generating configuration files from templates...')

	// Create config_values for template generation
	// Use k8app.namespace to ensure consistency with kubernetes client
	mut config_values := ConfigValues{
		hostname:       installer.hostname
		backends:       backends_str_builder.str()
		namespace:      k8app.namespace
		http_port:      installer.http_port
		data_path:      installer.data_path
		log_level:      installer.log_level
		admin_user:     installer.admin_user
		admin_password: installer.admin_password
		storage_size:   installer.storage_size
		config_toml:    ''
	}

	// Generate config.toml
	config_toml_raw := $tmpl('./templates/config.toml.temp')

	// Indent the config for proper YAML formatting (4 spaces for ConfigMap data)
	config_toml_lines := config_toml_raw.split('\n')
	mut config_toml_indented := strings.new_builder(config_toml_raw.len + 100)
	for line in config_toml_lines {
		if line.len > 0 {
			config_toml_indented.writeln('    ${line}')
		} else {
			config_toml_indented.writeln('')
		}
	}

	// Update config_values with the generated and indented config
	config_values.config_toml = config_toml_indented.str()

	// Ensure the output directory exists
	_ := pathlib.get_dir(path: '/tmp/stalwart', create: true)!

	// Generate TFGW YAML
	tfgw_yaml := $tmpl('./templates/tfgw.yaml')
	mut tfgw_path := pathlib.get_file(
		path:   installer.tfgw_path
		create: true
		check:  true
	)!
	tfgw_path.write(tfgw_yaml)!

	// Generate stalwart-app YAML
	stalwart_app_yaml := $tmpl('./templates/stalwart-app.yaml')
	mut stalwart_app_path := pathlib.get_file(path: installer.stalwart_app_path, create: true)!
	stalwart_app_path.write(stalwart_app_yaml)!

	console.print_info('Configuration files generated successfully.')
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !Stalwart {
	mut obj := encoderhero.decode[Stalwart](heroscript)!
	return obj
}
