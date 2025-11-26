module kubernetes_installer

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core
import incubaid.herolib.core.pathlib
import incubaid.herolib.installers.ulist
import incubaid.herolib.osal.startupmanager
import os

//////////////////// STARTUP COMMAND ////////////////////

fn (self &KubernetesInstaller) startupcmd() ![]startupmanager.ZProcessNewArgs {
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
		name: 'k3s_${self.name}'
		cmd:  cmd
		env:  {
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
		// Also check if kubectl can connect
		kubectl_res := osal.exec(
			cmd:         'kubectl get nodes'
			stdout:      false
			raise_error: false
		)!
		return kubectl_res.exit_code == 0
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
	mut os_release := pathlib.get_file(path: '/etc/os-release') or {
		return error('Could not read /etc/os-release. Is this Ubuntu?')
	}

	content := os_release.read()!
	if !content.contains('Ubuntu') && !content.contains('ubuntu') {
		return error('This installer requires Ubuntu. Current OS is not Ubuntu.')
	}

	console.print_debug('OS check passed: Running on Ubuntu')
}

//////////////////// DEPENDENCY INSTALLATION ////////////////////

fn install_deps(k3s_version string) ! {
	console.print_header('Installing dependencies...')

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

	// Install kubectl
	if !osal.cmd_exists('kubectl') {
		console.print_header('Installing kubectl...')
		// Extract version number from k3s_version (e.g., v1.33.1)
		kubectl_version := k3s_version
		kubectl_url := 'https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl'

		osal.download(
			url:  kubectl_url
			dest: '/tmp/kubectl'
		)!

		osal.exec(cmd: 'chmod +x /tmp/kubectl')!
		osal.cmd_add(
			cmdname: 'kubectl'
			source:  '/tmp/kubectl'
		)!
	}

	console.print_header('All dependencies installed successfully')
}

//////////////////// INSTALLATION ACTIONS ////////////////////

fn installed() !bool {
	return osal.cmd_exists('k3s') && osal.cmd_exists('kubectl')
}

// Install first master node
pub fn (mut self KubernetesInstaller) install_master() ! {
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
	console.print_header('To start K3s, run: kubernetes_installer.start')

	// Generate join script
	join_script := self.generate_join_script()!
	console.print_header('Join script generated. Save this for other nodes:\n${join_script}')
}

// Join as additional master
pub fn (mut self KubernetesInstaller) join_master() ! {
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
	console.print_header('To start K3s, run: kubernetes_installer.start')
}

// Install worker node
pub fn (mut self KubernetesInstaller) install_worker() ! {
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
	console.print_header('To start K3s, run: kubernetes_installer.start')
}

//////////////////// UTILITY FUNCTIONS ////////////////////

// Get kubeconfig content
pub fn (self &KubernetesInstaller) get_kubeconfig() !string {
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
pub fn (self &KubernetesInstaller) generate_join_script() !string {
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
!!kubernetes_installer.configure
    name:\'k3s_master_2\'
    k3s_version:\'${self.k3s_version}\'
    data_dir:\'${self.data_dir}\'
    node_name:\'master-2\'
    mycelium_interface:\'${self.mycelium_interface}\'
    token:\'${self.token}\'
    master_url:\'${master_url}\'

!!kubernetes_installer.join_master name:\'k3s_master_2\'
!!kubernetes_installer.start name:\'k3s_master_2\'
*/

// Section 2: Join as Worker Node
// Uncomment to join as worker node
/*
!!kubernetes_installer.configure
    name:\'k3s_worker_1\'
    k3s_version:\'${self.k3s_version}\'
    data_dir:\'${self.data_dir}\'
    node_name:\'worker-1\'
    mycelium_interface:\'${self.mycelium_interface}\'
    token:\'${self.token}\'
    master_url:\'${master_url}\'

!!kubernetes_installer.install_worker name:\'k3s_worker_1\'
!!kubernetes_installer.start name:\'k3s_worker_1\'
*/
'

	return script
}

//////////////////// CLEANUP ////////////////////

fn destroy() ! {
	console.print_header('Destroying K3s installation')

	// Stop K3s if running
	osal.process_kill_recursive(name: 'k3s')!

	// Get configuration to find data directory
	mut cfg := get() or {
		console.print_debug('No configuration found, using default paths')
		KubernetesInstaller{}
	}

	data_dir := if cfg.data_dir != '' { cfg.data_dir } else { '/var/lib/rancher/k3s' }

	// Clean up network interfaces
	cleanup_network()!

	// Unmount kubelet mounts
	cleanup_mounts()!

	// Remove data directory
	if data_dir != '' {
		console.print_header('Removing data directory: ${data_dir}')
		osal.rm(data_dir)!
	}

	// Clean up CNI
	osal.exec(cmd: 'rm -rf /var/lib/cni/', stdout: false) or {}

	// Clean up iptables rules
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
	osal.exec(
		cmd:         'ip link show | grep "master cni0" | awk -F: \'{print $2}\' | xargs -r -n1 ip link delete'
		stdout:      false
		raise_error: false
	) or {}

	// Remove CNI-related interfaces
	interfaces := ['cni0', 'flannel.1', 'flannel-v6.1', 'kube-ipvs0', 'flannel-wg', 'flannel-wg-v6']
	for iface in interfaces {
		osal.exec(cmd: 'ip link delete ${iface}', stdout: false, raise_error: false) or {}
	}

	// Remove CNI namespaces
	osal.exec(
		cmd:         'ip netns show | grep cni- | xargs -r -n1 ip netns delete'
		stdout:      false
		raise_error: false
	) or {}
}

fn cleanup_mounts() ! {
	console.print_header('Cleaning up mounts')

	// Unmount and remove kubelet directories
	paths := ['/run/k3s', '/var/lib/kubelet/pods', '/var/lib/kubelet/plugins', '/run/netns/cni-']

	for path in paths {
		// Find all mounts under this path and unmount them
		osal.exec(
			cmd:         'mount | grep "${path}" | awk \'{print $3}\' | sort -r | xargs -r -n1 umount -f'
			stdout:      false
			raise_error: false
		) or {}

		// Remove the directory
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
