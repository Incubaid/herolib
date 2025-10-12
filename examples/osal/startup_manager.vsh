#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.infra.zinit as zinitinstaller
import incubaid.herolib.sysadmin.startupmanager

mut z := zinitinstaller.get()!
z.destroy()!
z.install()!

println('zinit installed')

cmd := '/usr/local/bin/zinit init'
name := 'zinit'

mut sm := startupmanager.get()!
println(sm.list()!)
sm.new(
	name:  name
	cmd:   cmd
	start: false
)!

println(sm.list()!)
assert sm.exists(name)!

sm.delete(name)!
