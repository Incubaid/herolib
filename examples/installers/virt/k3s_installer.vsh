#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

// =============================================================================
// K3s Installer Lifecycle Example
// =============================================================================
// This script demonstrates the full K3s lifecycle:
//   1. Install as first master (active)
//   2. Destroy/cleanup (active after install)
//
// To test additional node types, uncomment the relevant sections.
// =============================================================================

import incubaid.herolib.installers.virt.k3s_installer
import incubaid.herolib.ui.console

// Use unique identifiers so we don't collide with other test state
const cluster_name = 'k3s_lifecycle_test'
const custom_data_dir = '/opt/k3s_lifecycle_test'

// =============================================================================
// SECTION 1: Install as First Master
// =============================================================================

console.print_header('K3s Lifecycle Test - Install First Master')

// Get or create installer instance with custom config
mut k3s := k3s_installer.get(name: cluster_name, create: true)!
k3s.node_name = 'master-lifecycle-test'
k3s.data_dir = custom_data_dir
// TFGW CRD config (only deployed on first master)
k3s.tfgw_mnemonic = 'habit acoustic keen dose differ pact small unveil sail kind bright cage'
k3s.tfgw_network = 'main'
k3s_installer.set(k3s)!

console.print_debug('Config: name=${k3s.name}, data_dir=${k3s.data_dir}')

// Check if already installed, destroy first
if k3s.installed()! {
	console.print_debug('K3s already installed, destroying first...')
	k3s.destroy()!
}

// Install as first master
k3s.install_master()!

// Reload to get generated token
k3s = k3s_installer.get(name: cluster_name)!

// Start K3s service
k3s.start()!

console.print_header('Install completed. Token: ${k3s.token}')

// =============================================================================
// SECTION 2: Join as Additional Master (HA Setup)
// =============================================================================
// Uncomment to test joining as additional master on another node.
// Requires: token and master_url from first master.

/*
mut k3s_master2 := k3s_installer.get(name: 'k3s_master_2', create: true)!
k3s_master2.node_name = 'master-2'
k3s_master2.data_dir = '/opt/k3s_master_2'
k3s_master2.token = '<TOKEN_FROM_FIRST_MASTER>'
k3s_master2.master_url = 'https://[<FIRST_MASTER_IPV6>]:6443'
k3s_installer.set(k3s_master2)!

k3s_master2.join_master()!
k3s_master2.start()!
*/

// =============================================================================
// SECTION 3: Join as Worker Node
// =============================================================================
// Uncomment to test joining as worker node on another machine.
// Requires: token and master_url from first master.

/*
mut k3s_worker := k3s_installer.get(name: 'k3s_worker_1', create: true)!
k3s_worker.node_name = 'worker-1'
k3s_worker.data_dir = '/opt/k3s_worker_1'
k3s_worker.token = '<TOKEN_FROM_FIRST_MASTER>'
k3s_worker.master_url = 'https://[<FIRST_MASTER_IPV6>]:6443'
k3s_installer.set(k3s_worker)!

k3s_worker.install_worker()!
k3s_worker.start()!
*/

// =============================================================================
// SECTION 4: Destroy/Uninstall
// =============================================================================
// Uncomment to run destroy after install for full lifecycle test.
// This will stop K3s, unmount volumes, remove data_dir, clean up kubepods slices.

/*
console.print_header('Destroying K3s installation...')
k3s.destroy()!
console.print_header('Destroy completed')
*/

console.print_header('Lifecycle test completed')
