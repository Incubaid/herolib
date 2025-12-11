module k3s_installer

import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core
import incubaid.herolib.core.pathlib
import incubaid.herolib.installers.ulist
import incubaid.herolib.osal.startupmanager
import os

//////////////////// STARTUP COMMAND ////////////////////

@[params]
pub struct StartArgs {
pub mut:
	reset bool
}

fn (self &K3SInstaller) startupcmd() ![]startupmanager.ZProcessNewArgs {
	mut res := []startupmanager.ZProcessNewArgs{}

	// Get Mycelium IPv6 address
	ipv6 := self.get_mycelium_ipv6()!

	// Get k3s binary path
	k3s_path := osal.cmd_path('k3s') or { '/usr/local/bin/k3s' }

	// Build K3s command based on node type
	mut cmd := ''
	mut extra_args := '--node-ip=${ipv6} --flannel-iface ${self.mycelium_interface}'

	// Add node name
	if self.node_name != '' {
		extra_args += ' --node-name ${self.node_name}'
	}

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
			cmd = '${k3s_path} server --cluster-init ${extra_args}'
		} else {
			// Additional master: join existing cluster
			if self.master_url == '' {
				return error('master_url is required for joining as additional master')
			}
			cmd = '${k3s_path} server --server ${self.master_url} ${extra_args}'
		}
	} else {
		// Worker node: join as agent
		if self.master_url == '' {
			return error('master_url is required for worker nodes')
		}
		cmd = '${k3s_path} agent --server ${self.master_url} ${extra_args}'
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
		return true
	}
	return false
}

fn (self &K3SInstaller) running_check() !bool {
	return running()!
}

fn (self &K3SInstaller) start_pre() ! {
}

fn (self &K3SInstaller) start_post() ! {
}

fn (self &K3SInstaller) stop_pre() ! {
}

fn (self &K3SInstaller) stop_post() ! {
}

//////////////////// OS CHECK ////////////////////

fn check_ubuntu() ! {
	// Check if running on Ubuntu
	if !core.is_linux()! {
		return error('K3s installer requires Linux. Current OS is not supported.')
	}

	// Check /etc/os-release for Ubuntu
	// Use pathlib.get() which handles symlinks correctly
	mut os_release := pathlib.get('/etc/os-release')
	if !os_release.exists() {
		return error('Could not find /etc/os-release. Is this Ubuntu?')
	}
	content := os_release.read() or {
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
pub fn (mut self K3SInstaller) install_master() ! {
	console.print_header('Installing K3s as first master node')

	// Check OS
	check_ubuntu()!

	// Set flags
	self.is_master = true
	self.is_first_master = true

	// Install dependencies
	install_deps(self.k3s_version)!

	// Ensure data directory and manifests directory exist
	osal.dir_ensure(self.data_dir)!
	manifests_dir := '${self.data_dir}/server/manifests'
	osal.dir_ensure(manifests_dir)!

	// Deploy TFGW CRD and Traefik manifests (only on first master)
	deploy_manifests(&self, manifests_dir)!

	// Save configuration
	set(self)!

	console.print_header('K3s first master installation completed')
	console.print_header('Token: ${self.token}')
	console.print_header('To start K3s, run: k3s_installer.start')

	// Generate join script
	join_script := self.generate_join_script()!
	console.print_header('Join script generated. Save this for other nodes:\n${join_script}')
}

// Join as additional master
pub fn (mut self K3SInstaller) join_master() ! {
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
	console.print_header('To start K3s, run: k3s_installer.start')
}

// Install worker node
pub fn (mut self K3SInstaller) install_worker() ! {
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
	console.print_header('To start K3s, run: k3s_installer.start')
}

//////////////////// UTILITY FUNCTIONS ////////////////////

// Get kubeconfig content
pub fn (self &K3SInstaller) get_kubeconfig() !string {
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
pub fn (self &K3SInstaller) generate_join_script() !string {
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
!!k3s_installer.configure
    name:\'k3s_master_2\'
    k3s_version:\'${self.k3s_version}\'
    data_dir:\'${self.data_dir}\'
    node_name:\'master-2\'
    mycelium_interface:\'${self.mycelium_interface}\'
    token:\'${self.token}\'
    master_url:\'${master_url}\'

!!k3s_installer.join_master name:\'k3s_master_2\'
!!k3s_installer.start name:\'k3s_master_2\'
*/

// Section 2: Join as Worker Node
// Uncomment to join as worker node
/*
!!k3s_installer.configure
    name:\'k3s_worker_1\'
    k3s_version:\'${self.k3s_version}\'
    data_dir:\'${self.data_dir}\'
    node_name:\'worker-1\'
    mycelium_interface:\'${self.mycelium_interface}\'
    token:\'${self.token}\'
    master_url:\'${master_url}\'

!!k3s_installer.install_worker name:\'k3s_worker_1\'
!!k3s_installer.start name:\'k3s_worker_1\'
*/
'

	return script
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

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

fn (mut self K3SInstaller) build() ! {
	// K3s is distributed as a pre-built binary, no build needed
}

//////////////////// CLEANUP ////////////////////

// Safety check to prevent deleting dangerous paths
fn is_safe_to_delete(path string) bool {
	// Never delete empty path
	if path == '' {
		return false
	}

	// Never delete root or critical top-level paths
	if path == '/' || path == '/var' || path == '/root' || path == '/home' || path == '/usr'
		|| path == '/etc' || path == '/opt' || path == '/tmp' {
		return false
	}

	// Must be at least 2 levels deep (e.g., /opt/k3s or /var/lib)
	// This allows /opt/test_k3s_data while blocking top-level directories
	if path.count('/') < 2 {
		return false
	}

	return true
}

fn destroy() ! {
	console.print_header('Destroying K3s installation')

	// Get configuration to find data directory
	// Use k3s_installer_default which is set by switch() before destroy() is called
	mut data_dirs := []string{}

	if cfg := get(name: k3s_installer_default) {
		data_dirs << cfg.data_dir
		console.print_debug('Found configured data directory: ${cfg.data_dir}')
	} else {
		console.print_debug('No configuration found, will clean up common K3s paths')
	}

	// Always add common K3s directories to ensure complete cleanup
	data_dirs << '/var/lib/rancher/k3s'
	data_dirs << '/root/hero/var/k3s'

	// Step 1: Stop and delete ALL k3s systemd services using startupmanager
	console.print_header('Stopping and removing systemd services...')

	mut sm := startupmanager_get(.systemd) or {
		console.print_debug('Failed to get systemd manager: ${err}')
		return error('Could not get systemd manager: ${err}')
	}

	all_services := sm.list() or {
		console.print_debug('Failed to list services: ${err}')
		[]string{}
	}

	for service_name in all_services {
		if service_name.starts_with('k3s_') {
			console.print_debug('Deleting systemd service: ${service_name}')
			sm.delete(service_name) or {
				console.print_debug('Failed to delete service ${service_name}: ${err}')
			}
		}
	}

	console.print_debug('Systemd services removed')

	// Step 2: Kill any remaining K3s processes
	console.print_header('Killing any remaining K3s processes...')

	// Kill K3s processes multiple times to ensure they're really dead
	for _ in 0 .. 3 {
		osal.exec(cmd: 'killall -9 k3s 2>/dev/null || true', stdout: false, raise_error: false) or {}
		osal.exec(
			cmd:         'pkill -9 -f "k3s (server|agent)" 2>/dev/null || true'
			stdout:      false
			raise_error: false
		) or {}
		osal.exec(cmd: 'sleep 1', stdout: false) or {}
	}

	// Wait longer for processes to fully terminate and release mounts
	console.print_debug('Waiting for K3s processes to fully terminate...')
	osal.exec(cmd: 'sleep 5', stdout: false) or {}

	// Step 3: Unmount kubelet mounts (including custom data directories)
	cleanup_mounts(data_dirs)!

	// Step 4: Clean up network interfaces
	cleanup_network()!

	// Step 5: Remove data directories
	console.print_debug('Removing data directories...')

	// Give time for unmounts to fully complete
	osal.exec(cmd: 'sleep 1', stdout: false) or {}

	mut cleaned_dirs := map[string]bool{}
	for data_dir in data_dirs {
		if data_dir != '' && data_dir !in cleaned_dirs {
			cleaned_dirs[data_dir] = true

			// Safety check before deletion
			if !is_safe_to_delete(data_dir) {
				console.print_debug('Skipping unsafe path: ${data_dir}')
				continue
			}

			console.print_debug('Removing data directory: ${data_dir}')

			// Use pathlib to delete directory
			mut dir := pathlib.get_dir(path: data_dir) or {
				console.print_debug('Path does not exist or is not a directory: ${data_dir}')
				continue
			}

			if dir.exists() {
				// Try pathlib delete first
				dir.delete() or {
					console.print_debug('Pathlib delete failed for ${data_dir}: ${err}')
					// Fallback to osal.rm for stubborn directories
					osal.rm(data_dir) or {
						console.print_debug('osal.rm also failed for ${data_dir}: ${err}')
					}
				}
				console.print_debug('Removed: ${data_dir}')
			} else {
				console.print_debug('Directory does not exist: ${data_dir}')
			}
		}
	}

	// Also remove K3s runtime directories using osal.rm
	console.print_debug('Removing /run/k3s')
	osal.rm('/run/k3s') or { console.print_debug('Failed to remove /run/k3s: ${err}') }

	console.print_debug('Removing /var/lib/kubelet')
	osal.rm('/var/lib/kubelet') or {
		console.print_debug('Failed to remove /var/lib/kubelet: ${err}')
	}

	console.print_debug('Removing /run/netns')
	osal.rm('/run/netns') or { console.print_debug('Failed to remove /run/netns: ${err}') }

	console.print_debug('Removing /etc/rancher')
	osal.rm('/etc/rancher') or { console.print_debug('Failed to remove /etc/rancher: ${err}') }

	// Step 6: Clean up CNI
	console.print_debug('Removing /var/lib/cni')
	osal.rm('/var/lib/cni') or { console.print_debug('Failed to remove /var/lib/cni: ${err}') }

	// Step 7: Clean up kubepods cgroup slices created by kubelet
	console.print_debug('Cleaning up kubepods slices...')
	osal.exec(
		cmd:         'systemctl stop kubepods.slice 2>/dev/null || true'
		stdout:      false
		raise_error: false
	) or {}
	osal.exec(
		cmd:         'systemctl reset-failed kubepods.slice 2>/dev/null || true'
		stdout:      false
		raise_error: false
	) or {}
	// Also clean any child slices
	slices_result := osal.exec(
		cmd:         'systemctl list-units --type=slice --no-legend | grep kubepods | cut -d" " -f1'
		stdout:      false
		raise_error: false
	) or { osal.Job{} }
	for slice in slices_result.output.split_into_lines() {
		s := slice.trim_space()
		if s != '' {
			osal.exec(
				cmd:         'systemctl stop "${s}" 2>/dev/null || true'
				stdout:      false
				raise_error: false
			) or {}
		}
	}

	console.print_debug('K3s destruction completed')
}

fn cleanup_network() ! {
	console.print_header('Cleaning up network interfaces (interfaces only)')

	// 1) Collect veth interfaces enslaved to cni0 (robust + no stderr noise)
	mut veths := []string{}
	mut seen := map[string]bool{}

	if res := osal.exec(
		cmd:         'ip -o link show master cni0 2>/dev/null || true'
		stdout:      false
		raise_error: false
	)
	{
		for line in res.output.split_into_lines() {
			l := line.trim_space()
			if l == '' {
				continue
			}

			// Format (ip -o): "12: vethXXXX@if2: <...> ... master cni0 ..."
			if !l.contains(': ') {
				continue
			}

			mut name := l.all_after(': ').all_before(':').trim_space()

			// Strip "@ifX" so we can delete by real ifname (ip can't delete "veth@if2")
			if name.contains('@') {
				name = name.all_before('@').trim_space()
			}

			if name != '' && !seen[name] {
				seen[name] = true
				veths << name
			}
		}
	}

	// 2) Delete veths (guard every call with timeout to avoid hanging)
	for veth in veths {
		console.print_debug('Deleting veth interface: ${veth}')
		osal.exec(
			cmd:         'timeout 3 ip link set dev ${veth} down 2>/dev/null || true'
			stdout:      false
			raise_error: false
		) or {}
		osal.exec(
			cmd:         'timeout 3 ip link del ${veth} 2>/dev/null || true'
			stdout:      false
			raise_error: false
		) or { console.print_debug('Failed/timed out deleting ${veth}, continuing...') }
	}

	// 3) Delete known k3s/CNI interfaces (also timeout + silence errors)
	interfaces := ['cni0', 'flannel.1', 'flannel-v6.1', 'kube-ipvs0', 'flannel-wg', 'flannel-wg-v6']
	for iface in interfaces {
		console.print_debug('Deleting interface: ${iface}')
		osal.exec(
			cmd:         'timeout 3 ip link set dev ${iface} down 2>/dev/null || true'
			stdout:      false
			raise_error: false
		) or {}
		osal.exec(
			cmd:         'timeout 3 ip link del ${iface} 2>/dev/null || true'
			stdout:      false
			raise_error: false
		) or {}
	}
}

fn cleanup_mounts(data_dirs []string) ! {
	console.print_header('Cleaning up mounts')

	// Build list of all paths to check for mounts
	mut all_mount_paths := ['/run/k3s', '/var/lib/kubelet', '/run/netns']
	for data_dir in data_dirs {
		if data_dir != '' {
			all_mount_paths << data_dir
			// Also explicitly add kubelet subdirectory which contains most pod mounts
			all_mount_paths << '${data_dir}/kubelet'
		}
	}

	// Unmount all K3s-related mounts (try multiple times if needed)
	console.print_debug('Finding and unmounting all K3s mounts...')
	for _ in 0 .. 3 {
		mut found_mounts := false
		for mount_path in all_mount_paths {
			// Get list of mount points
			get_mounts_cmd := 'mount | grep "${mount_path}" | cut -d" " -f3 | sort -r'
			if mount_result := osal.exec(cmd: get_mounts_cmd, stdout: false, raise_error: false) {
				if mount_result.output.trim_space() != '' {
					mount_points := mount_result.output.split_into_lines()
					for mount_point in mount_points {
						mp := mount_point.trim_space()
						if mp != '' {
							found_mounts = true
							console.print_debug('Unmounting: ${mp}')
							// Try lazy unmount first
							osal.exec(
								cmd:         'umount -l "${mp}" 2>/dev/null || true'
								stdout:      false
								raise_error: false
							) or {}
							// If that didn't work, try force unmount
							osal.exec(
								cmd:         'umount -f "${mp}" 2>/dev/null || true'
								stdout:      false
								raise_error: false
							) or {}
						}
					}
				}
			}
		}
		// If no mounts were found, we're done
		if !found_mounts {
			break
		}
		// Wait a bit before retrying
		osal.exec(cmd: 'sleep 1', stdout: false) or {}
	}

	console.print_debug('Mount cleanup completed')
}
