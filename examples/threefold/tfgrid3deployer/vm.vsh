#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import os
import incubaid.herolib.mycelium.grid3.gridproxy
import incubaid.herolib.mycelium.grid3.deployer
import incubaid.herolib.installers.threefold.griddriver
import incubaid.herolib.ui.console

const deployment_name = 'vmtestdeployment'

fn deploy_vm() ! {
	// Install griddriver binary if not present
	// mut griddriver_installer := griddriver.get()!
	// griddriver_installer.install()!

	deployer.get(create: true)!
	mut deployment := deployer.new_deployment(deployment_name)!
	deployment.add_machine(
		name:       'vm1'
		cpu:        1
		memory:     2
		planetary:  false
		public_ip4: true
		// nodes: [] means the system will automatically find an available node
	)
	deployment.deploy()!
	println(deployment)
}

fn delete_vm() ! {
	// Install griddriver binary if not present
	// mut griddriver_installer := griddriver.get()!
	// griddriver_installer.install()!

	deployer.get(create: true)!
	deployer.delete_deployment(name: deployment_name)!
}

fn main() {
	if os.args.len < 2 {
		println('Please provide a command: "deploy" or "delete"')
		return
	}
	match os.args[1] {
		'deploy' { deploy_vm()! }
		'delete' { delete_vm()! }
		else { println('Invalid command. Use "deploy" or "delete"') }
	}
}
