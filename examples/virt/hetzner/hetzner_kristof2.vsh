#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.virt.hetznermanager
import incubaid.herolib.ui.console
import incubaid.herolib.core.base
import incubaid.herolib.builder
import time
import os
import incubaid.herolib.core.playcmds

// Server-specific configuration
const server_name = 'kristof2'
const server_whitelist = '2555487'

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

hero_script := '
!!hetznermanager.configure
	user:"${hetzner_user}"
	whitelist:"${server_whitelist}"
	password:"${hetzner_passwd}"
	sshkey:"${hetzner_sshkey_name}"
'

playcmds.run(heroscript: hero_script)!
mut hetznermanager_ := hetznermanager.get()!

mut serverinfo := hetznermanager_.server_info_get(name: server_name)!

println('${server_name} ${serverinfo.server_ip}')

hetznermanager_.server_rescue(name: server_name, wait: true, hero_install: true)!
mut keys := hetznermanager_.keys_get()!

mut b := builder.new()!
mut n := b.node_new(ipaddr: serverinfo.server_ip)!

hetznermanager_.ubuntu_install(name: server_name, wait: true, hero_install: true)!
n.shell('')!
