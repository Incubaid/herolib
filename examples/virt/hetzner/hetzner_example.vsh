#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.virt.hetznermanager
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.builder
import time
import os

import freeflowuniverse.herolib.core.playcmds


passwd:=os.environ()['HETZNER_PASSWORD'] or { 
	println('HETZNER_PASSWORD not set') 
	exit(1)
}

playcmds.run(
	heroscript: '
	!!hetznermanager.configure
		name:"main"
		user:"operations@threefold.io"
		whitelist:"2111181, 2392178"
		password:"${passwd}"
	'
)!

console.print_header('Hetzner Test.')

mut cl := hetznermanager.get(name:'main')!

for i in 0 .. 5 {
	println('test cache, first time slow then fast')
	cl.servers_list()!
}

// println(cl.servers_list()!)

// mut serverinfo := cl.server_info_get(name: 'kristof2')!

// println(serverinfo)

// // cl.server_reset(name:"kristof2",wait:true)!

// // cl.server_rescue(name:"kristof2",wait:true)!

// console.print_header('SSH login')
// mut b := builder.new()!
// mut n := b.node_new(ipaddr: serverinfo.server_ip)!

// // n.hero_install()!
// // n.hero_compile_debug()!

// // mut ks:=cl.keys_get()!
// // println(ks)
