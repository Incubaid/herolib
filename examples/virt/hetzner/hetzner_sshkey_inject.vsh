#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.virt.hetznermanager
import incubaid.herolib.ui.console
import incubaid.herolib.core.playcmds
import os

// Get credentials
user := os.environ()['HETZNER_USER'] or {
	println('ERROR: HETZNER_USER not set')
	exit(1)
}

passwd := os.environ()['HETZNER_PASSWORD'] or {
	println('ERROR: HETZNER_PASSWORD not set')
	exit(1)
}

// Configure Hetzner Manager
hs := '
!!hetznermanager.configure
	user:"${user}"
	password:"${passwd}"
	whitelist:"2568389"
	sshkey:"*"
'

playcmds.run(heroscript: hs)!
mut cl := hetznermanager.get()!

console.print_header('Testing SSH Key Injection on petertest3')

// This will NOT reinstall, just inject SSH keys
cl.ubuntu_install(
	name:      'petertest3'
	wait:      true
	reinstall: false  // Important: don't reinstall, just inject keys
)!

println('✓ SSH keys injected into petertest3')
