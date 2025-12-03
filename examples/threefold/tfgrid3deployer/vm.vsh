#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import os
import incubaid.herolib.threefold.grid3.gridproxy
import incubaid.herolib.threefold.grid3.deployer
import incubaid.herolib.ui.console

const node_id = u32(2009)
const deployment_name = 'vmtestdeployment'

fn deploy_vm() ! {
	mut deployment := deployer.new_deployment(deployment_name)!
	deployment.add_machine(
		name:       'vm1'
		cpu:        1
		memory:     2
		planetary:  false
		public_ip4: true
		nodes:      [node_id]
	)
	deployment.deploy()!
	println(deployment)
}

fn delete_vm() ! {
	deployer.delete_deployment(deployment_name)!
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
