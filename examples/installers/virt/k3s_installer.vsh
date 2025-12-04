#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.virt.k3s_installer
import incubaid.herolib.ui.console

console.print_header('=== K3s Installer Example ===')

// Create a K3s installer instance
mut k3s := k3s_installer.get(name: 'k3s_master', create: true)!

console.print_debug('K3s installer configuration:')
console.print_debug('  Name: ${k3s.name}')
console.print_debug('  Version: ${k3s.k3s_version}')
console.print_debug('  Data dir: ${k3s.data_dir}')
console.print_debug('  Node name: ${k3s.node_name}')

// Check if k3s is already installed
if k3s.installed()! {
	console.print_header('K3s is already installed')
} else {
	console.print_header('K3s is not installed')
}

// Uncomment one of the following sections based on your needs:

// ============================================================================
// SECTION 1: Install as First Master Node
// ============================================================================
// This initializes a new K3s cluster with this node as the first master
k3s.install_master()!
k3s.start()!

// ============================================================================
// SECTION 2: Join as Additional Master (HA)
// ============================================================================
// First configure with token and master_url:
// mut k3s_ha := k3s_installer.get(name: 'k3s_master_2', create: true)!
// k3s_ha.token = 'TOKEN_FROM_FIRST_MASTER'
// k3s_ha.master_url = 'https://[MASTER_IPV6]:6443'
// k3s_installer.set(k3s_ha)!
// k3s_ha.join_master()!
// k3s_ha.start()!

// ============================================================================
// SECTION 3: Join as Worker Node
// ============================================================================
// First configure with token and master_url:
// mut k3s_worker := k3s_installer.get(name: 'k3s_worker_1', create: true)!
// k3s_worker.token = 'TOKEN_FROM_MASTER'
// k3s_worker.master_url = 'https://[MASTER_IPV6]:6443'
// k3s_installer.set(k3s_worker)!
// k3s_worker.install_worker()!
// k3s_worker.start()!

// ============================================================================
// SECTION 4: Destroy K3s Installation
// ============================================================================
// k3s.destroy()!

console.print_header('=== Example Complete ===')

