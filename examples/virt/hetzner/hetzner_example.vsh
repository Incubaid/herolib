#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.virt.hetznermanager
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.base
import freeflowuniverse.herolib.builder
import time
import os

import freeflowuniverse.herolib.core.playcmds


user:=os.environ()['HETZNER_USER'] or { 
	println('HETZNER_USER not set') 
	exit(1)
}
passwd:=os.environ()['HETZNER_PASSWORD'] or { 
	println('HETZNER_PASSWORD not set') 
	exit(1)
}

playcmds.run(
	heroscript: '
	!!hetznermanager.configure
		name:"main"
		user:"${user}"
		whitelist:"2111181, 2392178"
		password:"${passwd}"
	'
)!

console.print_header('Hetzner Test.')

mut cl := hetznermanager.get(name:'main')!

// for i in 0 .. 5 {
// 	println('test cache, first time slow then fast')
// }

// println(cl.servers_list()!)

mut serverinfo := cl.server_info_get(name: 'kristof2')!

println(serverinfo)

// cl.server_reset(name:"kristof2",wait:true)!

//don't forget to specify the keyname needed
// cl.server_rescue(name:"kristof2",wait:true, hero_install:true,sshkey_name:"kristof")!

// mut ks:=cl.keys_get()!
// println(ks)

// console.print_header('SSH login')
// mut b := builder.new()!
// mut n := b.node_new(ipaddr: serverinfo.server_ip)!

//this will put hero in debug mode on the system
// n.hero_install(compile:true)!

// n.shell("")!

cl.ubuntu_install(name:"kristof2",wait:true, hero_install:true,sshkey_name:"kristof")!

