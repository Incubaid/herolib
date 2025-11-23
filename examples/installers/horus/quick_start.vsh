#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.horus.coordinator
import incubaid.herolib.installers.horus.supervisor

// Quick Start Example - Install and Start Coordinator and Supervisor
// This is a minimal example to get started with Horus

println('🚀 Horus Quick Start')
println('=' * 60)
println('This will install and start Coordinator and Supervisor')
println('(Runners can be added later using the full install script)')
println('=' * 60)

// Install Coordinator
println('\n📦 Installing Coordinator...')
mut coordinator := herocoordinator.get(create: true)!
coordinator.install()!
println('✅ Coordinator installed')

// Install Supervisor
println('\n📦 Installing Supervisor...')
mut supervisor_inst := supervisor.get(create: true)!
supervisor_inst.install()!
println('✅ Supervisor installed')

// Start services
println('\n▶️  Starting Coordinator...')
coordinator.start()!
if coordinator.running()! {
	println('✅ Coordinator is running on http://127.0.0.1:${coordinator.http_port}')
}

println('\n▶️  Starting Supervisor...')
supervisor_inst.start()!
if supervisor_inst.running()! {
	println('✅ Supervisor is running on http://127.0.0.1:${supervisor_inst.http_port}')
}

println('\n' + '=' * 60)
println('🎉 Quick Start Complete!')
println('=' * 60)
println('\n📊 Services Running:')
println('  • Coordinator: http://127.0.0.1:${coordinator.http_port}')
println('  • Supervisor:  http://127.0.0.1:${supervisor_inst.http_port}')

println('\n💡 Next Steps:')
println('  • Test coordinator: curl http://127.0.0.1:${coordinator.http_port}')
println('  • Test supervisor:  curl http://127.0.0.1:${supervisor_inst.http_port}')
println('  • Install runners:  ./horus_full_install.vsh')
println('  • Check status:     ./horus_status.vsh')
println('  • Stop services:    ./horus_stop_all.vsh')
