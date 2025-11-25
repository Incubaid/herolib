#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.horus.coordinator
import incubaid.herolib.installers.horus.supervisor
import incubaid.herolib.installers.horus.herorunner
import incubaid.herolib.installers.horus.osirisrunner
import incubaid.herolib.installers.horus.salrunner

// Check Status of All Horus Services

println('📊 Horus Services Status')
println('=' * 60)

// Get all services
mut coordinator := herocoordinator.get()!
mut supervisor_inst := supervisor.get()!
mut hero_runner := herorunner.get()!
mut osiris_runner := osirisrunner.get()!
mut sal_runner := salrunner.get()!

// Check status
println('\n🔍 Checking service status...\n')

coord_running := coordinator.running()!
super_running := supervisor_inst.running()!
hero_running := hero_runner.running()!
osiris_running := osiris_runner.running()!
sal_running := sal_runner.running()!

println('Service                Status      Details')
println('-' * 60)
println('Coordinator            ${if coord_running { '✅ Running' } else { '❌ Stopped' }}   http://127.0.0.1:${coordinator.http_port}')
println('Supervisor             ${if super_running { '✅ Running' } else { '❌ Stopped' }}   http://127.0.0.1:${supervisor_inst.http_port}')
println('Hero Runner            ${if hero_running { '✅ Running' } else { '❌ Stopped' }}')
println('Osiris Runner          ${if osiris_running { '✅ Running' } else { '❌ Stopped' }}')
println('SAL Runner             ${if sal_running { '✅ Running' } else { '❌ Stopped' }}')

println('\n' + '=' * 60)

// Count running services
mut running_count := 0
if coord_running {
	running_count++
}
if super_running {
	running_count++
}
if hero_running {
	running_count++
}
if osiris_running {
	running_count++
}
if sal_running {
	running_count++
}

println('Summary: ${running_count}/5 services running')

if running_count == 5 {
	println('🎉 All services are running!')
} else if running_count == 0 {
	println('💤 All services are stopped')
} else {
	println('⚠️  Some services are not running')
}
