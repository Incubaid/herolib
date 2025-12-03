module cryptpad

import incubaid.herolib.ui.console
import incubaid.herolib.data.encoderhero

import incubaid.herolib.k8_apps.core
import incubaid.herolib.core.pathlib
import strings

pub const version = '0.0.0'
const singleton = false
const default = false

//TODO: this should. not be needed
struct ConfigValues {
pub mut:
	hostname  string // The CryptPad hostname
	backends  string // The backends for the TFGW
	namespace string // The namespace for the CryptPad deployment
	config_js string // Generated config.js content
}

@[heap]
pub struct CryptpadServer {
pub mut:
	name               string = 'cryptpad'
	cryptpad_path      string = '/tmp/cryptpad/cryptpad.yaml'
	tfgw_cryptpad_path string = '/tmp/cryptpad/tfgw-cryptpad.yaml'
	config_js_path     string = '/tmp/cryptpad/config.js'
	k8app        	   ?core.K8App @[skip]
}

// your checking & initialization code if needed
fn obj_init(mycfg_ CryptpadServer) !CryptpadServer {
	mut mycfg := mycfg_
	mycfg.k8app = core.k8app(
		app_name: 'cryptpad'
		app_instance: mycfg.name
		namespace: 
	)!
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

	// Create config_values for template generation
	mut config_values := ConfigValues{
		hostname:  installer.hostname
		backends:  backends_str_builder.str()
		namespace: installer.namespace
		config_js: ''
	}

	// Generate config.js
	config_js_raw := $tmpl('./templates/config.js')

	// Indent the configs for proper YAML formatting (4 spaces for ConfigMap data)
	config_js_lines := config_js_raw.split('\n')
	mut config_js_indented := strings.new_builder(config_js_raw.len + 100)
	for line in config_js_lines {
		if line.len > 0 {
			config_js_indented.writeln('    ${line}')
		}
	}

	// Update config_values with the generated and indented configs
	config_values.config_js = config_js_indented.str()

	// Ensure the output directory exists
	_ := pathlib.get_dir(path: '/tmp/cryptpad', create: true)!

	console.print_info('Generating YAML files from templates...')
	tfgw_yaml := $tmpl('./templates/tfgw-cryptpad.yaml')
	mut tfgw_path := pathlib.get_file(path: installer.tfgw_cryptpad_path, create: true)!
	tfgw_path.write(tfgw_yaml)!

	cryptpad_yaml := $tmpl('./templates/cryptpad.yaml')
	mut cryptpad_path := pathlib.get_file(path: installer.cryptpad_path, create: true)!
	cryptpad_path.write(cryptpad_yaml)!

	console.print_info('YAML files generated successfully.')
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

pub fn heroscript_loads(heroscript string) !CryptpadServer {
	mut obj := encoderhero.decode[CryptpadServer](heroscript)!
	return obj
}
