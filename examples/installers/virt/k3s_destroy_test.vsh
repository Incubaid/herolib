#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.virt.k3s_installer
import incubaid.herolib.ui.console

console.print_header('=== K3s Installer - Destroy Test ===')

// Get the existing installer instance
mut k3s := k3s_installer.get(name: 'test_k3s_cluster')!

console.print_header('\n🗑️  Destroying K3s installation...')
k3s.destroy()!

console.print_header('\n✅ Destroy completed')
console.print_header('\n=== Destroy Test Complete ===')
