#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import os
import incubaid.herolib.mycelium.grid3.deployer

const node_id = u32(8)
const deployment_name = 'georunner_deployment'
const vm_name = 'georunner_vm'
const ubuntu_flist = 'https://hub.threefold.me/tf-official-vms/ubuntu-22.04-lts.flist'
const ssh_pubkey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHvfosOnVY+teTHeT3rr657r6Rx/cL6XOyyVMzyiN7iC'

// Gitea action runner configuration
const gitea_instance = 'https://git.ourworld.tf/'
const gitea_token = 'a8KJ256bWNZy2YXFU3qvmzpIuhZzRpDpFzKb8ots'
const hero_binary_url = 'https://github.com/Incubaid/herolib/releases/download/v1.0.38/hero-x86_64-linux-musl'

fn deploy_vm() ! {
	// Initialize deployer (reads from env vars: TFGRID_MNEMONIC, SSH_KEY, TFGRID_NETWORK)
	deployer.get(create: true)!
	
	mut deployment := deployer.new_deployment(deployment_name)!
	
	deployment.configure_network(user_access_endpoints: 1)!
	
	deployment.add_machine(
		name:       vm_name
		cpu:        2
		memory:     4
		planetary:  false
		public_ip4: true
		public_ip6: false
		mycelium:   deployer.Mycelium{}
		nodes:      [node_id]
	)
	
	deployment.deploy()!
	
	vm := deployment.vm_get(vm_name)!
	println('Deployment successful!')
	println('VM: ${vm.requirements.name}')
	println('Node: ${vm.node_id}')
	println('Mycelium IP: ${vm.mycelium_ip}')
	println('WireGuard IP: ${vm.wireguard_ip}')
	println('\nConnect: ssh root@${vm.mycelium_ip}')
	
	user_configs := deployment.get_user_access_configs()
	if user_configs.len > 0 {
		println('\nWireGuard Config:')
		println(user_configs[0].print_wg_config())
	}
	
	// Install action runner
	println('\n=== Installing Gitea Action Runner ===')
	install_action_runner(vm.mycelium_ip)!
}

fn install_action_runner(mycelium_ip string) ! {
	if mycelium_ip == '' {
		return error('Mycelium IP is empty, cannot install action runner')
	}
	
	println('Waiting for VM to be fully ready (30 seconds)...')
	os.execute('sleep 30')
	
	// Create the heroscript
	heroscript := '// Install actrunner
!!actrunner.install reset:true

// Register actrunner with Gitea instance
!!actrunner.register instance:\'${gitea_instance}\' token:\'${gitea_token}\'

// Start the actrunner daemon
!!actrunner.start reset:true
'
	
	// Create the setup script
	setup_script := '#!/bin/bash
set -e

echo "Setting up Gitea Action Runner..."

# Download hero binary
echo "Downloading hero binary..."
apt update && apt install -y redis-server curl
cd /root
curl -L -o hero "${hero_binary_url}"
chmod +x hero

# Create heroscript
cat > act_runner.heroscript <<HEROSCRIPT_EOF
${heroscript}
HEROSCRIPT_EOF

# Run heroscript
echo "Running heroscript to install and configure action runner..."
./hero run act_runner.heroscript

echo "Gitea Action Runner setup complete!"
'
	
	// Write setup script to temp file
	tmp_script := '/tmp/setup_runner.sh'
	os.write_file(tmp_script, setup_script)!
	
	println('Copying setup script to VM...')
	scp_cmd := 'scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${tmp_script} root@[${mycelium_ip}]:/root/setup_runner.sh'
	result := os.execute(scp_cmd)
	if result.exit_code != 0 {
		return error('Failed to copy setup script: ${result.output}')
	}
	
	println('Running setup script on VM...')
	ssh_cmd := 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${mycelium_ip} "chmod +x /root/setup_runner.sh && /root/setup_runner.sh"'
	result2 := os.execute(ssh_cmd)
	if result2.exit_code != 0 {
		println('Warning: Setup script execution had issues: ${result2.output}')
		println('You may need to manually run: ssh root@${mycelium_ip} "/root/setup_runner.sh"')
	} else {
		println('✓ Gitea Action Runner installed and started successfully!')
	}
	
	// Cleanup
	os.rm(tmp_script) or {}
}

fn delete_vm() ! {
	deployer.delete_deployment(deployment_name)!
	println('Deployment deleted')
}

fn show_info() ! {
	mut deployment := deployer.get_deployment(deployment_name)!
	vm := deployment.vm_get(vm_name)!
	
	println('VM: ${vm.requirements.name}')
	println('Node: ${vm.node_id}')
	println('Mycelium IP: ${vm.mycelium_ip}')
	println('WireGuard IP: ${vm.wireguard_ip}')
	println('\nConnect: ssh root@${vm.mycelium_ip}')
}

fn main() {
	if os.args.len < 2 {
		println('Usage: ${os.args[0]} <deploy|delete|info>')
		return
	}
	
	match os.args[1] {
		'deploy' { deploy_vm()! }
		'delete' { delete_vm()! }
		'info' { show_info()! }
		else { println('Invalid command. Use "deploy", "delete", or "info"') }
	}
}
