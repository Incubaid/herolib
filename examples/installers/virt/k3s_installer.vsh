#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.virt.k3s_installer
import incubaid.herolib.ui.console

console.print_header('=== K3s Installer Test with Custom Configuration ===')

// Create a K3s installer instance with CUSTOM values (not defaults)
mut k3s := k3s_installer.get(name: 'test_k3s_cluster', create: true)!

// Set custom values
k3s.node_name = 'prod-master-node-01'
k3s.data_dir = '/opt/test_k3s_data'
k3s.k3s_version = 'v1.33.1'

// Save configuration
k3s_installer.set(k3s)!

console.print_header('\n📋 Custom Configuration:')
console.print_debug('  Name: ${k3s.name}')
console.print_debug('  Node name: ${k3s.node_name}')
console.print_debug('  Data dir: ${k3s.data_dir}')
console.print_debug('  K3s version: ${k3s.k3s_version}')
console.print_debug('  Mycelium interface: ${k3s.mycelium_interface}')

// Check if k3s is already installed
if k3s.installed()! {
	console.print_header('\n⚠️  K3s is already installed, destroying first...')
	k3s.destroy()!
	console.print_header('✅ Previous installation destroyed')
}

// ============================================================================
// SECTION 1: Install as First Master Node
// ============================================================================
console.print_header('\n🚀 Installing K3s as first master node...')
k3s.install_master()!
console.print_header('✅ Installation completed')

console.print_header('\n🔄 Starting K3s service...')
k3s.start()!
console.print_header('✅ K3s service started')

console.print_header('\n📌 Token: ${k3s.token}')

console.print_header('\n=== Installation Complete ===')

