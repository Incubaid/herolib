#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.virt.hetznermanager
import incubaid.herolib.ui.console
import incubaid.herolib.core.base
import incubaid.herolib.builder
import time
import os
import incubaid.herolib.core.playcmds

// Server-specific configuration
const server_name = 'kristof3'
const server_whitelist = '2573047'

// Load credentials from environment variables
// Source hetzner_env.sh before running: source examples/virt/hetzner/hetzner_env.sh
hetzner_user := os.environ()['HETZNER_USER'] or {
	println('HETZNER_USER not set')
	exit(1)
}

hetzner_passwd := os.environ()['HETZNER_PASSWORD'] or {
	println('HETZNER_PASSWORD not set')
	exit(1)
}

hetzner_sshkey_name := os.environ()['HETZNER_SSHKEY_NAME'] or {
	println('HETZNER_SSHKEY_NAME not set')
	exit(1)
}

hs := '
!!hetznermanager.configure
	user:"${hetzner_user}"
	whitelist:"${server_whitelist}"
	password:"${hetzner_passwd}"
	sshkey:"${hetzner_sshkey_name}"
'

println(hs)

playcmds.run(heroscript: hs)!

console.print_header('Hetzner Test.')

mut cl := hetznermanager.get()!
// println(cl)

// for i in 0 .. 5 {
// 	println('test cache, first time slow then fast')
// }

println(cl.servers_list()!)

mut serverinfo := cl.server_info_get(name: server_name)!

println(serverinfo)

// cl.server_reset(name: 'kristof2', wait: true)!

// cl.server_rescue(name: name, wait: true, hero_install: true)!

// mut ks := cl.keys_get()!
// println(ks)

// console.print_header('SSH login')

cl.ubuntu_install(name: server_name, wait: true, hero_install: true)!
// cl.ubuntu_install(name: 'kristof20', wait: true, hero_install: true)!
// cl.ubuntu_install(id:2550378, name: 'kristof21', wait: true, hero_install: true)!
// cl.ubuntu_install(id:2550508, name: 'kristof22', wait: true, hero_install: true)!
// cl.ubuntu_install(id: 2550253, name: 'kristof23', wait: true, hero_install: true)!

// this will put hero in debug mode on the system
mut b := builder.new()!
mut n := b.node_new(ipaddr: serverinfo.server_ip)!
n.hero_install(compile: true)!

n.shell('')!
