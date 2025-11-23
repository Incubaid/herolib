#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.horus.coordinator
import incubaid.herolib.installers.horus.supervisor
import incubaid.herolib.installers.horus.herorunner
import incubaid.herolib.installers.horus.osirisrunner
import incubaid.herolib.installers.horus.salrunner
import time

// Start All Horus Services
// This script starts all Horus components in the correct order

println('🚀 Starting All Horus Services')

// Step 1: Start Coordinator
println('\n▶️  Step 1/5: Starting Coordinator...')
mut coordinator_installer := coordinator.get(name: 'ayman', create: true)!
coordinator_installer.start()!
if coordinator_installer.running()! {
	println('✅ Coordinator is running on HTTP:${coordinator_installer.http_port} WS:${coordinator_installer.ws_port}')
} else {
	println('❌ Coordinator failed to start')
}

// Step 2: Start Supervisor
println('\n▶️  Step 2/5: Starting Supervisor...')
mut supervisor_inst := supervisor.get(create: true)!
supervisor_inst.start()!
if supervisor_inst.running()! {
	println('✅ Supervisor is running on HTTP:${supervisor_inst.http_port} WS:${supervisor_inst.ws_port}')
} else {
	println('❌ Supervisor failed to start')
}

// Step 3: Start Hero Runner
println('\n▶️  Step 3/5: Starting Hero Runner...')
mut hero_runner := herorunner.get(create: true)!
hero_runner.start()!
if hero_runner.running()! {
	println('✅ Hero Runner is running')
} else {
	println('❌ Hero Runner failed to start')
}

// Step 4: Start Osiris Runner
println('\n▶️  Step 4/5: Starting Osiris Runner...')
mut osiris_runner := osirisrunner.get(create: true)!
osiris_runner.start()!
if osiris_runner.running()! {
	println('✅ Osiris Runner is running')
} else {
	println('❌ Osiris Runner failed to start')
}

// Step 5: Start SAL Runner
println('\n▶️  Step 5/5: Starting SAL Runner...')
mut sal_runner := salrunner.get(create: true)!
sal_runner.start()!
if sal_runner.running()! {
	println('✅ SAL Runner is running')
} else {
	println('❌ SAL Runner failed to start')
}

println('🎉 All Horus services started!')

println('\n📊 Service Status:')
coordinator_status := if coordinator_installer.running()! { '✅ Running' } else { '❌ Stopped' }
println('  • Coordinator: ${coordinator_status} (http://127.0.0.1:${coordinator_installer.http_port})')

supervisor_status := if supervisor_inst.running()! { '✅ Running' } else { '❌ Stopped' }
println('  • Supervisor:  ${supervisor_status} (http://127.0.0.1:${supervisor_inst.http_port})')

hero_runner_status := if hero_runner.running()! { '✅ Running' } else { '❌ Stopped' }
println('  • Hero Runner: ${hero_runner_status}')

osiris_runner_status := if osiris_runner.running()! { '✅ Running' } else { '❌ Stopped' }
println('  • Osiris Runner: ${osiris_runner_status}')

sal_runner_status := if sal_runner.running()! { '✅ Running' } else { '❌ Stopped' }
println('  • SAL Runner: ${sal_runner_status}')

println('\n💡 Next Steps:')
println('  To stop services, run: ./horus_stop_all.vsh')
println('  To check status, run: ./horus_status.vsh')
