#!/usr/bin/env -S v -gc none -no-retry-compilation -d use_openssl -enable-globals -cg run

import incubaid.herolib.threefold.grid3.gridproxy
import incubaid.herolib.threefold.grid3.deployer
import incubaid.herolib.installers.threefold.griddriver
import os
import time

griddriver.install()!

v := tfgrid3deployer.get()!
println('cred: ${v}')
deployment_name := 'wireguard_dep_example'
mut deployment := tfgrid3deployer.new_deployment(deployment_name)!

deployment.configure_network(user_access_endpoints: 3)!
deployment.add_machine(
	name:       'vm1'
	cpu:        1
	memory:     2
	planetary:  false
	wireguard:  true
	public_ip4: false
	size:       10 // 10 gig
)
deployment.deploy()!

vm1 := deployment.vm_get('vm1')!
println('vm1 info: ${vm1}')

user_access_configs := deployment.get_user_access_configs()
for config in user_access_configs {
	println('config:\n------\n${config.print_wg_config()}\n------\n')
}

deployment.add_webname(
	name:                  'gwoverwg'
	backend:               'http://${vm1.wireguard_ip}:8000'
	use_wireguard_network: true
)
deployment.deploy()!

gw1 := deployment.webname_get('gwoverwg')!
println('gw info: ${gw1}')

// tfgrid3deployer.delete_deployment(deployment_name)!
