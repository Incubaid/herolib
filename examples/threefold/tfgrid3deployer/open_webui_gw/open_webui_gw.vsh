#!/usr/bin/env -S v -gc none -no-retry-compilation -d use_openssl -enable-globals -cg run

//#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals -cg run
import incubaid.herolib.threefold.grid3.gridproxy
import incubaid.herolib.threefold.grid3.deployer
import incubaid.herolib.installers.threefold.griddriver
import os
import time

griddriver.install()!

v := tfgrid3deployer.get()!
println('cred: ${v}')

deployment_name := 'openwebui_example'
mut deployment := tfgrid3deployer.new_deployment(deployment_name)!

deployment.add_machine(
	name:      'vm1'
	cpu:       1
	memory:    16
	planetary: true
	size:      100 // 10 gig
	flist:     'https://hub.grid.tf/mariobassem1.3bot/docker.io-threefolddev-open_webui-latest.flist'
)
deployment.deploy()!

vm1 := deployment.vm_get('vm1')!
println('vm1 info: ${vm1}')

deployment.add_webname(
	name:                  'openwebui'
	backend:               'http://${vm1.wireguard_ip}:8080'
	use_wireguard_network: true
)
deployment.deploy()!

gw1 := deployment.webname_get('openwebui')!
println('gw info: ${gw1}')

// tfgrid3deployer.delete_deployment(deployment_name)!
