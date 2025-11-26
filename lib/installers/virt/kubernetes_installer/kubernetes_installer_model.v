module kubernetes_installer

import incubaid.herolib.data.encoderhero
import incubaid.herolib.osal.core as osal
import os
import rand

pub const version = 'v1.33.1'
const singleton = true
const default = true

// K3s installer - handles K3s cluster installation with Mycelium IPv6 networking
@[heap]
pub struct KubernetesInstaller {
pub mut:
	name               string = 'default'
	// K3s version to install
	k3s_version        string = version
	// Data directory for K3s (default: ~/hero/var/k3s)
	data_dir           string
	// Unique node name/identifier
	node_name          string
	// Mycelium interface name (default: mycelium0)
	mycelium_interface string = 'mycelium0'
	// Cluster token for authentication (auto-generated if empty)
	token              string
	// Master URL for joining cluster (e.g., 'https://[ipv6]:6443')
	master_url         string
	// Node IPv6 address (auto-detected from Mycelium if empty)
	node_ip            string
	// Is this a master/control-plane node?
	is_master          bool
	// Is this the first master (uses --cluster-init)?
	is_first_master    bool
}

// your checking & initialization code if needed
fn obj_init(mycfg_ KubernetesInstaller) !KubernetesInstaller {
	mut mycfg := mycfg_

	// Set default data directory if not provided
	if mycfg.data_dir == '' {
		mycfg.data_dir = os.join_path(os.home_dir(), 'hero/var/k3s')
	}

	// Expand home directory in data_dir if it contains ~
	if mycfg.data_dir.starts_with('~') {
		mycfg.data_dir = mycfg.data_dir.replace_once('~', os.home_dir())
	}

	// Set default node name if not provided
	if mycfg.node_name == '' {
		hostname := os.execute('hostname').output.trim_space()
		mycfg.node_name = if hostname != '' { hostname } else { 'k3s-node-${rand.hex(4)}' }
	}

	// Generate token if not provided and this is the first master
	if mycfg.token == '' && mycfg.is_first_master {
		// Generate a secure random token
		mycfg.token = rand.hex(32)
	}

	// Validate: join operations require token and master_url
	if !mycfg.is_first_master && (mycfg.token == '' || mycfg.master_url == '') {
		return error('Joining a cluster requires both token and master_url to be set')
	}

	return mycfg
}

// Get path to kubeconfig file
pub fn (self &KubernetesInstaller) kubeconfig_path() string {
	return '${self.data_dir}/server/cred/admin.kubeconfig'
}

// Get Mycelium IPv6 address from interface
pub fn (self &KubernetesInstaller) get_mycelium_ipv6() !string {
	// If node_ip is already set, use it
	if self.node_ip != '' {
		return self.node_ip
	}

	// Otherwise, detect from Mycelium interface
	return get_mycelium_ipv6_from_interface(self.mycelium_interface)!
}

// Helper function to detect Mycelium IPv6 from interface
fn get_mycelium_ipv6_from_interface(iface string) !string {
	// Step 1: Find the 400::/7 route via the interface
	route_result := osal.exec(
		cmd:    'ip -6 route | grep "^400::/7.*dev ${iface}"'
		stdout: false
	) or { return error('No 400::/7 route found via interface ${iface}') }

	route_line := route_result.output.trim_space()
	if route_line == '' {
		return error('No 400::/7 route found via interface ${iface}')
	}

	// Step 2: Extract next-hop IPv6 and get prefix (first 4 segments)
	// Parse: "400::/7 via <nexthop> dev <iface> ..."
	parts := route_line.split(' ')
	mut nexthop := ''
	for i, part in parts {
		if part == 'via' && i + 1 < parts.len {
			nexthop = parts[i + 1]
			break
		}
	}

	if nexthop == '' {
		return error('Could not extract next-hop from route: ${route_line}')
	}

	// Get first 4 segments of IPv6 address (prefix)
	prefix_parts := nexthop.split(':')
	if prefix_parts.len < 4 {
		return error('Invalid IPv6 next-hop format: ${nexthop}')
	}
	prefix := prefix_parts[0..4].join(':')

	// Step 3: Get all global IPv6 addresses on the interface
	addr_result := osal.exec(
		cmd:    'ip -6 addr show dev ${iface} scope global | grep inet6 | awk \'{print $2}\' | cut -d/ -f1'
		stdout: false
	)!

	ipv6_list := addr_result.output.split_into_lines()

	// Step 4: Match the one with the same prefix
	for ip in ipv6_list {
		ip_trimmed := ip.trim_space()
		if ip_trimmed == '' {
			continue
		}

		ip_parts := ip_trimmed.split(':')
		if ip_parts.len >= 4 {
			ip_prefix := ip_parts[0..4].join(':')
			if ip_prefix == prefix {
				return ip_trimmed
			}
		}
	}

	return error('No global IPv6 address found on ${iface} matching prefix ${prefix}')
}

// called before start if done
fn configure() ! {
	mut cfg := get()!

	// Ensure data directory exists
	osal.dir_ensure(cfg.data_dir)!

	// Create manifests directory for auto-apply
	manifests_dir := '${cfg.data_dir}/server/manifests'
	osal.dir_ensure(manifests_dir)!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj KubernetesInstaller) !string {
	return encoderhero.encode[KubernetesInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !KubernetesInstaller {
	mut obj := encoderhero.decode[KubernetesInstaller](heroscript)!
	return obj
}
