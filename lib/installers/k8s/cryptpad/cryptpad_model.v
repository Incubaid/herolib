module cryptpad

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
	hostname  string // The CryptPad hostname
	backends  string // The backends for the TFGW
	namespace string // The namespace for the CryptPad deployment
}

@[heap]
pub struct CryptpadServer {
pub mut:
	name               string = 'cryptpad'
	hostname           string
	namespace          string
	cryptpad_path      string = '/tmp/cryptpad.yaml'
	tfgw_cryptpad_path string = '/tmp/tfgw-cryptpad.yaml'
	kube_client        kubernetes.KubeClient @[skip]
}

// your checking & initialization code if needed
fn obj_init(mycfg_ CryptpadServer) !CryptpadServer {
	mut mycfg := mycfg_

	if mycfg.namespace == '' {
		mycfg.namespace = mycfg.name
	}

	if mycfg.hostname == '' {
		mycfg.hostname = mycfg.name
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

	config_values := ConfigValues{
		hostname:  installer.hostname
		backends:  backends_str_builder.str()
		namespace: installer.namespace
	}

	console.print_info('Generating YAML files from templates...')
	temp := $tmpl('./templates/tfgw-cryptpad.yaml')
	mut temp_path := pathlib.get_file(path: installer.tfgw_cryptpad_path, create: true)!
	temp_path.write(temp)!

	temp2 := $tmpl('./templates/cryptpad.yaml')
	mut temp_path2 := pathlib.get_file(path: installer.cryptpad_path, create: true)!
	temp_path2.write(temp2)!

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
