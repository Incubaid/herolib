#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.horus.coordinator
import incubaid.herolib.installers.horus.supervisor
import incubaid.herolib.installers.horus.herorunner
import incubaid.herolib.installers.horus.osirisrunner
import incubaid.herolib.installers.horus.salrunner

// Stop All Horus Services
// This script stops all running Horus components

println('🛑 Stopping All Horus Services')
println('=' * 60)

// Stop in reverse order
println('\n⏹️  Stopping SAL Runner...')
mut sal_runner := salrunner.get()!
sal_runner.stop()!
println('✅ SAL Runner stopped')

println('\n⏹️  Stopping Osiris Runner...')
mut osiris_runner := osirisrunner.get()!
osiris_runner.stop()!
println('✅ Osiris Runner stopped')

println('\n⏹️  Stopping Hero Runner...')
mut hero_runner := herorunner.get()!
hero_runner.stop()!
println('✅ Hero Runner stopped')

println('\n⏹️  Stopping Supervisor...')
mut supervisor_inst := supervisor.get()!
supervisor_inst.stop()!
println('✅ Supervisor stopped')

println('\n⏹️  Stopping Coordinator...')
mut coordinator := herocoordinator.get()!
coordinator.stop()!
println('✅ Coordinator stopped')

println('\n' + '=' * 60)
println('✅ All Horus services stopped!')
println('=' * 60)
