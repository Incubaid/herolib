module k3s_installer

import incubaid.herolib.data.encoderhero
import incubaid.herolib.osal.core as osal
import incubaid.herolib.core.pathlib
import rand

pub const version = 'v1.33.1'
const singleton = true
const default = true

// K3s installer - handles K3s cluster installation with Mycelium IPv6 networking
@[heap]
pub struct K3SInstaller {
pub mut:
	name               string = 'default'
	// K3s version to install
	k3s_version        string = version
	// Data directory for K3s (default: ~/hero/var/k3s)
	data_dir           string
	// Unique node name/identifier
	node_name          string
	// Mycelium interface name (auto-detected if not specified)
	mycelium_interface string
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
	// TFGW CRD config (only deployed on first master)
	tfgw_mnemonic      string  // Wallet mnemonic for TFGW controller
	tfgw_network       string  // Network: main, dev, test, qa
}

// Template values for TFGW CRD manifest rendering
struct TfgwTemplateValues {
pub:
	mnemonic string
	network  string
	token    string  // Empty for unencrypted mnemonic
}

// your checking & initialization code if needed
fn obj_init(mycfg_ K3SInstaller) !K3SInstaller {
	mut mycfg := mycfg_

	// Set default data directory if not provided
	if mycfg.data_dir == '' {
		// pathlib.get() handles ~ expansion automatically
		mycfg.data_dir = pathlib.get('~/hero/var/k3s').absolute()
	}

	// Expand home directory in data_dir if it contains ~
	// pathlib.get() already handles ~ expansion, so just normalize
	mycfg.data_dir = pathlib.get(mycfg.data_dir).absolute()

	// Set default node name if not provided
	if mycfg.node_name == '' {
		hostname_result := osal.exec(cmd: 'hostname', stdout: false, raise_error: false) or {
			osal.Job{}
		}
		hostname := hostname_result.output.trim_space()
		mycfg.node_name = if hostname != '' { hostname } else { 'k3s-node-${rand.hex(4)}' }
	}

	// Auto-detect Mycelium interface if not provided
	if mycfg.mycelium_interface == '' {
		mycfg.mycelium_interface = detect_mycelium_interface()!
	}

	// Generate token if not provided and this is the first master
	if mycfg.token == '' && mycfg.is_first_master {
		// Generate a secure random token
		mycfg.token = rand.hex(32)
	}

	// Note: Validation of token/master_url is done in the specific action functions
	// (join_master, install_worker) where the context is clear

	return mycfg
}

// Get path to kubeconfig file
pub fn (self &K3SInstaller) kubeconfig_path() string {
	return '${self.data_dir}/server/cred/admin.kubeconfig'
}

// Get Mycelium IPv6 address from interface
pub fn (self &K3SInstaller) get_mycelium_ipv6() !string {
	// If node_ip is already set, use it
	if self.node_ip != '' {
		return self.node_ip
	}

	// Otherwise, detect from Mycelium interface
	return get_mycelium_ipv6_from_interface(self.mycelium_interface)!
}

// Auto-detect Mycelium interface by finding 400::/7 route
fn detect_mycelium_interface() !string {
	// Check if we're on macOS or Linux
	$if macos {
		// On macOS, use netstat to find the route
		route_result := osal.exec(
			cmd:         'netstat -rn -f inet6 | grep -E "^4[0-9a-f]{2,3}:" | head -1'
			stdout:      false
			raise_error: false
		)!

		if route_result.exit_code != 0 || route_result.output.trim_space() == '' {
			return error('No Mycelium interface found on macOS. Please ensure Mycelium is installed and running.')
		}

		// Parse interface name from netstat output (last column)
		route_line := route_result.output.trim_space()
		parts := route_line.split_any(' \t').filter(it.len > 0)
		if parts.len > 0 {
			iface := parts[parts.len - 1]
			return iface
		}
		return error('Could not parse Mycelium interface from netstat output: ${route_line}')
	} $else {
		// Find all 400::/7 routes on Linux
		route_result := osal.exec(
			cmd:         'ip -6 route | grep "^400::/7"'
			stdout:      false
			raise_error: false
		)!

		if route_result.exit_code != 0 || route_result.output.trim_space() == '' {
			return error('No Mycelium interface found (no 400::/7 route detected). Please ensure Mycelium is installed and running.')
		}

		// Parse interface name from route (format: "400::/7 dev <interface> ...")
		route_line := route_result.output.trim_space()
		parts := route_line.split(' ')

		for i, part in parts {
			if part == 'dev' && i + 1 < parts.len {
				iface := parts[i + 1]
				return iface
			}
		}

		return error('Could not parse Mycelium interface from route output: ${route_line}')
	}
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

	// Step 2: Get all global IPv6 addresses on the interface
	addr_result := osal.exec(
		cmd:    'ip -6 addr show dev ${iface} scope global | grep inet6 | awk \'{print $2}\' | cut -d/ -f1'
		stdout: false
	)!

	ipv6_list := addr_result.output.split_into_lines()

	// Check if route has a next-hop (via keyword)
	parts := route_line.split(' ')
	mut nexthop := ''
	for i, part in parts {
		if part == 'via' && i + 1 < parts.len {
			nexthop = parts[i + 1]
			break
		}
	}

	if nexthop != '' {
		// Route has a next-hop: match by prefix (first 4 segments)
		prefix_parts := nexthop.split(':')
		if prefix_parts.len < 4 {
			return error('Invalid IPv6 next-hop format: ${nexthop}')
		}
		prefix := prefix_parts[0..4].join(':')

		// Step 3: Match the one with the same prefix
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
	} else {
		// Direct route (no via): return the first IPv6 address in 400::/7 range
		for ip in ipv6_list {
			ip_trimmed := ip.trim_space()
			if ip_trimmed == '' {
				continue
			}

			// Check if IP is in 400::/7 range (starts with 4 or 5)
			if ip_trimmed.starts_with('4') || ip_trimmed.starts_with('5') {
				return ip_trimmed
			}
		}

		return error('No global IPv6 address found on ${iface} in 400::/7 range')
	}
}

// called before start if done
fn configure() ! {
	mut cfg := get()!

	// Ensure data directory exists
	osal.dir_ensure(cfg.data_dir)!

	// Create manifests directory for auto-apply (only for server nodes)
	manifests_dir := '${cfg.data_dir}/server/manifests'
	osal.dir_ensure(manifests_dir)!

	// Deploy TFGW CRD and Traefik config only on first master
	if cfg.is_first_master {
		deploy_manifests(cfg, manifests_dir)!
	}
}

// Deploy TFGW CRD and Traefik config manifests to K3s manifests directory
fn deploy_manifests(cfg &K3SInstaller, manifests_dir string) ! {
	// Create template values for TFGW CRD
	tfgw_values := TfgwTemplateValues{
		mnemonic: cfg.tfgw_mnemonic
		network:  cfg.tfgw_network
		token:    ''  // Empty for unencrypted mnemonic
	}

	// Render and write TFGW CRD template
	tfgw_yaml := $tmpl('./templates/tfgw-crd.yaml')
	mut tfgw_path := pathlib.get_file(path: '${manifests_dir}/tfgw-crd.yaml', create: true)!
	tfgw_path.write(tfgw_yaml)!

	// Copy Traefik config - use $embed_file since it has no template variables
	// and contains @ symbols in emails that would conflict with $tmpl
	traefik_yaml := $embed_file('./templates/traefik-config.yaml')
	mut traefik_path := pathlib.get_file(path: '${manifests_dir}/traefik-config.yaml', create: true)!
	traefik_path.write(traefik_yaml.to_string())!
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj K3SInstaller) !string {
	return encoderhero.encode[K3SInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !K3SInstaller {
	mut obj := encoderhero.decode[K3SInstaller](heroscript)!
	return obj
}
