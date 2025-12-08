module k3s

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core
import incubaid.herolib.core.pathlib
import incubaid.herolib.installers.ulist
import incubaid.herolib.osal.startupmanager
import os

//////////////////// STARTUP COMMAND ////////////////////

fn (self &K3s) startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}

	// Get Mycelium IPv6 address
	ipv6 := self.get_mycelium_ipv6()!

	// Build K3s command based on node type
	mut cmd := ''
	mut extra_args := '--node-ip=${ipv6} --flannel-iface ${self.mycelium_interface}'

	// Add data directory if specified
	if self.data_dir != '' {
		extra_args += ' --data-dir ${self.data_dir} --kubelet-arg=root-dir=${self.data_dir}/kubelet'
	}

	// Add token
	if self.token != '' {
		extra_args += ' --token ${self.token}'
	}

	if self.is_master {
		// Master node configuration
		extra_args += ' --cluster-cidr=2001:cafe:42::/56 --service-cidr=2001:cafe:43::/112 --flannel-ipv6-masq'

		if self.is_first_master {
			// First master: initialize cluster
			cmd = 'k3s server --cluster-init ${extra_args}'
		} else {
			// Additional master: join existing cluster
			if self.master_url == '' {
				return error('master_url is required for joining as additional master')
			}
			cmd = 'k3s server --server ${self.master_url} ${extra_args}'
		}
	} else {
		// Worker node: join as agent
		if self.master_url == '' {
			return error('master_url is required for worker nodes')
		}
		cmd = 'k3s agent --server ${self.master_url} ${extra_args}'
	}

	res << startupmanager.ZProcessNewArgs{
		name:        'k3s_${self.name}'
		startuptype: .systemd
		cmd:         cmd
		env:         {
			'HOME': os.home_dir()
		}
	}

	return res
}

//////////////////// RUNNING CHECK ////////////////////

fn running() !bool {
	// Check if k3s process is running
	res := osal.exec(cmd: 'pgrep -f "k3s (server|agent)"', stdout: false, raise_error: false)!
	if res.exit_code == 0 {
		// K3s process is running, that's enough for basic check
		// We don't check kubectl connectivity here as it might not be ready immediately
		// and could hang if kubeconfig is not properly configured
		return true
	}
	return false
}

//////////////////// OS CHECK ////////////////////

fn check_ubuntu() ! {
	// Check if running on Ubuntu
	if !core.is_linux()! {
		return error('K3s installer requires Linux. Current OS is not supported.')
	}

	// Check /etc/os-release for Ubuntu
	content := os.read_file('/etc/os-release') or {
		return error('Could not read /etc/os-release. Is this Ubuntu?')
	}

	if !content.contains('Ubuntu') && !content.contains('ubuntu') {
		return error('This installer requires Ubuntu. Current OS is not Ubuntu.')
	}

	console.print_debug('OS check passed: Running on Ubuntu')
}

//////////////////// DEPENDENCY INSTALLATION ////////////////////

fn install_deps(k3s_version string) ! {
	console.print_header('Installing K3s dependencies...')

	// Check and install curl
	if !osal.cmd_exists('curl') {
		console.print_header('Installing curl...')
		osal.package_install('curl')!
	}

	// Check and install iproute2 (for ip command)
	if !osal.cmd_exists('ip') {
		console.print_header('Installing iproute2...')
		osal.package_install('iproute2')!
	}

	// Install K3s binary
	if !osal.cmd_exists('k3s') {
		console.print_header('Installing K3s ${k3s_version}...')
		k3s_url := 'https://github.com/k3s-io/k3s/releases/download/${k3s_version}+k3s1/k3s'

		osal.download(
			url:  k3s_url
			dest: '/tmp/k3s'
		)!

		// Make it executable and move to /usr/local/bin
		osal.exec(cmd: 'chmod +x /tmp/k3s')!
		osal.cmd_add(
			cmdname: 'k3s'
			source:  '/tmp/k3s'
		)!
	}

	console.print_header('K3s dependencies installed successfully')
}

//////////////////// INSTALLATION ACTIONS ////////////////////

fn installed() !bool {
	return osal.cmd_exists('k3s')
}

// Install first master node
pub fn (mut self K3s) install_master() ! {
	console.print_header('Installing K3s as first master node')

	// Check OS
	check_ubuntu()!

	// Set flags
	self.is_master = true
	self.is_first_master = true

	// Install dependencies
	install_deps(self.k3s_version)!

	// Ensure data directory exists
	osal.dir_ensure(self.data_dir)!

	// Save configuration
	set(self)!

	console.print_header('K3s first master installation completed')
	console.print_header('Token: ${self.token}')
	console.print_header('To start K3s, run: k3s.start')

	// Generate join script
	join_script := self.generate_join_script()!
	console.print_header('Join script generated. Save this for other nodes:\n${join_script}')
}

// Join as additional master
pub fn (mut self K3s) join_master() ! {
	console.print_header('Joining K3s cluster as additional master')

	// Check OS
	check_ubuntu()!

	// Validate required fields
	if self.token == '' {
		return error('token is required to join cluster')
	}
	if self.master_url == '' {
		return error('master_url is required to join cluster')
	}

	// Set flags
	self.is_master = true
	self.is_first_master = false

	// Install dependencies
	install_deps(self.k3s_version)!

	// Ensure data directory exists
	osal.dir_ensure(self.data_dir)!

	// Save configuration
	set(self)!

	console.print_header('K3s additional master installation completed')
	console.print_header('To start K3s, run: k3s.start')
}

// Install worker node
pub fn (mut self K3s) install_worker() ! {
	console.print_header('Installing K3s as worker node')

	// Check OS
	check_ubuntu()!

	// Validate required fields
	if self.token == '' {
		return error('token is required to join cluster')
	}
	if self.master_url == '' {
		return error('master_url is required to join cluster')
	}

	// Set flags
	self.is_master = false
	self.is_first_master = false

	// Install dependencies
	install_deps(self.k3s_version)!

	// Ensure data directory exists
	osal.dir_ensure(self.data_dir)!

	// Save configuration
	set(self)!

	console.print_header('K3s worker installation completed')
	console.print_header('To start K3s, run: k3s.start')
}

//////////////////// UTILITY FUNCTIONS ////////////////////

// Get kubeconfig content
pub fn (self &K3s) get_kubeconfig() !string {
	kubeconfig_path := self.kubeconfig_path()

	mut kubeconfig_file := pathlib.get_file(path: kubeconfig_path) or {
		return error('Kubeconfig not found at ${kubeconfig_path}. Is K3s running?')
	}

	if !kubeconfig_file.exists() {
		return error('Kubeconfig not found at ${kubeconfig_path}. Is K3s running?')
	}

	return kubeconfig_file.read()!
}

// Generate join script for other nodes
pub fn (self &K3s) generate_join_script() !string {
	if !self.is_first_master {
		return error('Can only generate join script from first master node')
	}

	// Get Mycelium IPv6 of this master
	master_ipv6 := self.get_mycelium_ipv6()!
	master_url := 'https://[${master_ipv6}]:6443'

	mut script := '#!/usr/bin/env hero

// ============================================================================
// K3s Cluster Join Script
// Generated from master node: ${self.node_name}
// ============================================================================

// Section 1: Join as Additional Master (HA)
// Uncomment to join as additional master node
/*
!!k3s.configure
    name:\'k3s_master_2\'
    k3s_version:\'${self.k3s_version}\'
    data_dir:\'${self.data_dir}\'
    node_name:\'master-2\'
    mycelium_interface:\'${self.mycelium_interface}\'
    token:\'${self.token}\'
    master_url:\'${master_url}\'

!!k3s.join_master name:\'k3s_master_2\'
!!k3s.start name:\'k3s_master_2\'
*/

// Section 2: Join as Worker Node
// Uncomment to join as worker node
/*
!!k3s.configure
    name:\'k3s_worker_1\'
    k3s_version:\'${self.k3s_version}\'
    data_dir:\'${self.data_dir}\'
    node_name:\'worker-1\'
    mycelium_interface:\'${self.mycelium_interface}\'
    token:\'${self.token}\'
    master_url:\'${master_url}\'

!!k3s.install_worker name:\'k3s_worker_1\'
!!k3s.start name:\'k3s_worker_1\'
*/
'

	return script
}

//////////////////// CLEANUP ////////////////////

fn destroy() ! {
	console.print_header('Destroying K3s installation')

	// Get configuration to find data directory
	// Try to get from current configuration, otherwise use common paths
	mut data_dirs := []string{}

	if cfg := get() {
		data_dirs << cfg.data_dir
		console.print_debug('Found configured data directory: ${cfg.data_dir}')
	} else {
		console.print_debug('No configuration found, will clean up common K3s paths')
	}

	// Always add common K3s directories to ensure complete cleanup
	data_dirs << '/var/lib/rancher/k3s'
	data_dirs << '/root/hero/var/k3s'

	// CRITICAL: Complete systemd service deletion FIRST before any other cleanup
	// This prevents the service from auto-restarting during cleanup

	// Step 1: Stop and delete ALL k3s systemd services using startupmanager
	console.print_header('Stopping and removing systemd services...')

	// Get systemd startup manager
	mut sm := startupmanager_get(.systemd) or {
		console.print_debug('Failed to get systemd manager: ${err}')
		return error('Could not get systemd manager: ${err}')
	}

	// List all k3s services
	all_services := sm.list() or {
		console.print_debug('Failed to list services: ${err}')
		[]string{}
	}

	// Filter and delete k3s services
	for service_name in all_services {
		if service_name.starts_with('k3s_') {
			console.print_debug('Deleting systemd service: ${service_name}')
			// Use startupmanager.delete() which properly stops, disables, and removes the service
			sm.delete(service_name) or {
				console.print_debug('Failed to delete service ${service_name}: ${err}')
			}
		}
	}

	console.print_header('✓ Systemd services removed')

	// Step 2: Kill any remaining K3s processes
	console.print_header('Killing any remaining K3s processes...')
	osal.exec(cmd: 'killall -9 k3s 2>/dev/null || true', stdout: false, raise_error: false) or {
		console.print_debug('No k3s processes to kill or killall failed')
	}

	// Wait for processes to fully terminate
	osal.exec(cmd: 'sleep 2', stdout: false) or {}

	// Step 3: Unmount kubelet mounts (before network cleanup)
	cleanup_mounts()!

	// Step 4: Clean up network interfaces (after processes are stopped)
	cleanup_network()!

	// Step 5: Remove data directories
	console.print_header('Removing data directories...')

	// Remove all K3s data directories (deduplicated)
	mut cleaned_dirs := map[string]bool{}
	for data_dir in data_dirs {
		if data_dir != '' && data_dir !in cleaned_dirs {
			cleaned_dirs[data_dir] = true
			console.print_debug('Removing data directory: ${data_dir}')
			osal.exec(cmd: 'rm -rf ${data_dir}', stdout: false, raise_error: false) or {
				console.print_debug('Failed to remove ${data_dir}: ${err}')
			}
		}
	}

	// Also remove /etc/rancher which K3s creates
	console.print_debug('Removing /etc/rancher')
	osal.exec(cmd: 'rm -rf /etc/rancher', stdout: false, raise_error: false) or {}

	// Step 6: Clean up CNI
	console.print_header('Cleaning up CNI directories...')
	osal.exec(cmd: 'rm -rf /var/lib/cni/', stdout: false, raise_error: false) or {}

	// Step 7: Clean up iptables rules
	console.print_header('Cleaning up iptables rules')
	osal.exec(
		cmd:         'iptables-save | grep -v KUBE- | grep -v CNI- | grep -iv flannel | iptables-restore'
		stdout:      false
		raise_error: false
	) or {}
	osal.exec(
		cmd:         'ip6tables-save | grep -v KUBE- | grep -v CNI- | grep -iv flannel | ip6tables-restore'
		stdout:      false
		raise_error: false
	) or {}

	console.print_header('K3s destruction completed')
}

fn cleanup_network() ! {
	console.print_header('Cleaning up network interfaces')

	// Remove interfaces that are slaves of cni0
	// Get the list first, then delete one by one
	if veth_result := osal.exec(
		cmd:         'ip link show | grep "master cni0" | awk -F: \'{print $2}\' | xargs'
		stdout:      false
		raise_error: false
	)
	{
		if veth_result.output.trim_space() != '' {
			veth_interfaces := veth_result.output.trim_space().split(' ')
			for veth in veth_interfaces {
				veth_trimmed := veth.trim_space()
				if veth_trimmed != '' {
					console.print_debug('Deleting veth interface: ${veth_trimmed}')
					osal.exec(
						cmd:         'ip link delete ${veth_trimmed}'
						stdout:      false
						raise_error: false
					) or { console.print_debug('Failed to delete ${veth_trimmed}, continuing...') }
				}
			}
		}
	} else {
		console.print_debug('No veth interfaces found or error getting list')
	}

	// Remove CNI-related interfaces
	interfaces := ['cni0', 'flannel.1', 'flannel-v6.1', 'kube-ipvs0', 'flannel-wg', 'flannel-wg-v6']
	for iface in interfaces {
		console.print_debug('Deleting interface: ${iface}')
		// Use timeout to prevent hanging, and redirect stderr to avoid blocking
		osal.exec(
			cmd:         'timeout 5 ip link delete ${iface} 2>/dev/null || true'
			stdout:      false
			raise_error: false
		) or { console.print_debug('Interface ${iface} not found or already deleted') }
	}

	// Remove CNI namespaces
	if ns_result := osal.exec(
		cmd:         'ip netns show | grep cni- | xargs'
		stdout:      false
		raise_error: false
	)
	{
		if ns_result.output.trim_space() != '' {
			namespaces := ns_result.output.trim_space().split(' ')
			for ns in namespaces {
				ns_trimmed := ns.trim_space()
				if ns_trimmed != '' {
					console.print_debug('Deleting namespace: ${ns_trimmed}')
					osal.exec(
						cmd:         'ip netns delete ${ns_trimmed}'
						stdout:      false
						raise_error: false
					) or { console.print_debug('Failed to delete namespace ${ns_trimmed}') }
				}
			}
		}
	} else {
		console.print_debug('No CNI namespaces found')
	}
}

fn cleanup_mounts() ! {
	console.print_header('Cleaning up mounts')

	// Unmount and remove kubelet directories
	paths := ['/run/k3s', '/var/lib/kubelet/pods', '/var/lib/kubelet/plugins', '/run/netns/cni-']

	for path in paths {
		// Find all mounts under this path and unmount them
		if mount_result := osal.exec(
			cmd:         'mount | grep "${path}" | awk \'{print $3}\' | sort -r'
			stdout:      false
			raise_error: false
		)
		{
			if mount_result.output.trim_space() != '' {
				mount_points := mount_result.output.split_into_lines()
				for mount_point in mount_points {
					mp_trimmed := mount_point.trim_space()
					if mp_trimmed != '' {
						console.print_debug('Unmounting: ${mp_trimmed}')
						osal.exec(cmd: 'umount -f ${mp_trimmed}', stdout: false, raise_error: false) or {
							console.print_debug('Failed to unmount ${mp_trimmed}')
						}
					}
				}
			}
		} else {
			console.print_debug('No mounts found for ${path}')
		}

		// Remove the directory
		console.print_debug('Removing directory: ${path}')
		osal.exec(cmd: 'rm -rf ${path}', stdout: false, raise_error: false) or {}
	}
}

//////////////////// GENERIC INSTALLER FUNCTIONS ////////////////////

fn ulist_get() !ulist.UList {
	return ulist.UList{}
}

fn upload() ! {
	// Not applicable for K3s
}

fn install() ! {
	return error('Use install_master, join_master, or install_worker instead of generic install')
}
