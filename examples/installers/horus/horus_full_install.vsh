#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.horus.coordinator
import incubaid.herolib.installers.horus.supervisor
import incubaid.herolib.installers.horus.herorunner
import incubaid.herolib.installers.horus.osirisrunner
import incubaid.herolib.installers.horus.salrunner

// Full Horus Installation Example
// This script installs and configures all Horus components:
// - Coordinator (port 8081)
// - Supervisor (port 8082)
// - Hero Runner
// - Osiris Runner
// - SAL Runner

println('🚀 Starting Full Horus Installation')

// Step 1: Install Coordinator
println('\n📦 Step 1/5: Installing Coordinator...')
mut coordinator_installer := coordinator.get(create: true)!
coordinator_installer.install()!
println('✅ Coordinator installed at ${coordinator_installer.binary_path}')

// Step 2: Install Supervisor
println('\n📦 Step 2/5: Installing Supervisor...')
mut supervisor_inst := supervisor.get(create: true)!
supervisor_inst.install()!
println('✅ Supervisor installed at ${supervisor_inst.binary_path}')

// Step 3: Install Hero Runner
println('\n📦 Step 3/5: Installing Hero Runner...')
mut hero_runner := herorunner.get(create: true)!
hero_runner.install()!
println('✅ Hero Runner installed at ${hero_runner.binary_path}')

// Step 4: Install Osiris Runner
println('\n📦 Step 4/5: Installing Osiris Runner...')
mut osiris_runner := osirisrunner.get(create: true)!
osiris_runner.install()!
println('✅ Osiris Runner installed at ${osiris_runner.binary_path}')

// Step 5: Install SAL Runner
println('\n📦 Step 5/5: Installing SAL Runner...')
mut sal_runner := salrunner.get(create: true)!
sal_runner.install()!
println('✅ SAL Runner installed at ${sal_runner.binary_path}')

println('🎉 All Horus components installed successfully!')

println('\n📋 Installation Summary:')
println('  • Coordinator: ${coordinator_installer.binary_path} (HTTP: ${coordinator_installer.http_port}, WS: ${coordinator_installer.ws_port})')
println('  • Supervisor:  ${supervisor_inst.binary_path} (HTTP: ${supervisor_inst.http_port}, WS: ${supervisor_inst.ws_port})')
println('  • Hero Runner: ${hero_runner.binary_path}')
println('  • Osiris Runner: ${osiris_runner.binary_path}')
println('  • SAL Runner: ${sal_runner.binary_path}')

println('\n💡 Next Steps:')
println('  To start services, run: ./horus_start_all.vsh')
println('  To test individual components, see the other example scripts')
