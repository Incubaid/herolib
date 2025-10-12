#!/usr/bin/env -S v -gc none  -cc tcc -d use_openssl -enable-globals -cg run

import incubaid.herolib.threefold.grid3.gridproxy
import incubaid.herolib.threefold.grid3.deployer
import incubaid.herolib.installers.threefold.griddriver
import os
import time

// res2 := deployer.filter_nodes()!
// println(res2)
// exit(0)

const vm_node = u32(2009)
const gw_node = u32(1)

v := deployer.get()!
println('cred: ${v}')
deployment_name := 'vm_caddy1'
mut deployment := deployer.new_deployment(deployment_name)!
deployment.add_machine(
	name:       'vm_caddy1'
	cpu:        1
	memory:     2
	planetary:  false
	public_ip4: false
	size:       10 // 10 gig
	mycelium:   deployer.Mycelium{}
	nodes:      [vm_node]
)
deployment.deploy()!

vm1 := deployment.vm_get('vm_caddy1')!
println('vm1 info: ${vm1}')

vm1_ip := vm1.mycelium_ip

deployment.add_webname(node_id: gw_node, name: 'gwnamecaddy', backend: 'http://[${vm1_ip}]:80')
deployment.deploy()!
gw1 := deployment.webname_get('gwnamecaddy')!
println('gw info: ${gw1}')

// Retry logic to wait for the SSH server to be up
max_retries := 10
mut retries := 0
mut is_ssh_up := false

for {
	if retries < max_retries {
		// Try to SSH into the machine
		ssh_check_cmd := 'ssh -o "StrictHostKeyChecking no" root@${vm1_ip} -o ConnectTimeout=10 echo "SSH server is up"'
		ssh_check_res := os.execute(ssh_check_cmd)

		if ssh_check_res.exit_code == 0 {
			is_ssh_up = true
			break
		}
		retries++
		println('SSH server not up, retrying in 5 seconds... (Attempt ${retries}/${max_retries})')
		time.sleep(time.second * 5)
	}
}

if !is_ssh_up {
	panic('Failed to connect to the SSH server after ${max_retries} attempts.')
}

cp_cmd := 'scp -o "StrictHostKeyChecking no" ${os.dir(@FILE)}/install_caddy.sh ${os.dir(@FILE)}/Caddyfile root@[${vm1_ip}]:~'
res1 := os.execute(cp_cmd)
if res1.exit_code != 0 {
	panic('failed to copy files: ${res1.output}')
}

cmd := 'ssh root@${vm1_ip} -o "StrictHostKeyChecking no" -t "chmod +x ~/install_caddy.sh && ~/install_caddy.sh"'
res := os.execute(cmd)
if res.exit_code != 0 {
	panic('failed to install and run caddy: ${res.output}')
}

println('To access the machine, run the following command:')
println('ssh root@${vm1_ip}')
