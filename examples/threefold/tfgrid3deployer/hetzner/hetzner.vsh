#!/usr/bin/env -S v -gc none  -d use_openssl -enable-globals -cg run

//#!/usr/bin/env -S v -gc none  -cc tcc -d use_openssl -enable-globals -cg run
import incubaid.herolib.threefold.grid3.gridproxy
import incubaid.herolib.threefold.grid3.deployer
import incubaid.herolib.installers.threefold.griddriver
import os
import time

griddriver.install()!

v := tfgrid3deployer.get()!
println('cred: ${v}')
deployment_name := 'hetzner_dep'
mut deployment := tfgrid3deployer.new_deployment(deployment_name)!

// TODO: find a way to filter hetzner nodes
deployment.add_machine(
	name:       'hetzner_vm'
	cpu:        2
	memory:     5
	planetary:  false
	public_ip4: false
	size:       10 // 10 gig
	// mycelium:   tfgrid3deployer.Mycelium{}
)
deployment.deploy()!

vm1 := deployment.vm_get('hetzner_vm')!
println('vm1 info: ${vm1}')

vm1_public_ip4 := vm1.public_ip4.all_before('/')

deployment.add_webname(name: 'gwtohetzner', backend: 'http://${vm1_public_ip4}:80')
deployment.deploy()!
gw1 := deployment.webname_get('gwtohetzner')!
println('gw info: ${gw1}')
