#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import os
import incubaid.herolib.mycelium.grid3.deployer
import incubaid.herolib.osal.core as osal

const node_id = u32(8)
const deployment_name = 'georunner_deployment'
const vm_name = 'georunner_vm'
const ubuntu_flist = 'https://hub.threefold.me/tf-official-vms/ubuntu-22.04-lts.flist'
const ssh_pubkey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHvfosOnVY+teTHeT3rr657r6Rx/cL6XOyyVMzyiN7iC'

// Gitea action runner configuration
const gitea_instance = 'https://git.ourworld.tf/'
const gitea_token = 'W2KyeBH1ZyICO3GW6T2IaUxzp9tsoOfU3yY514QV'
const hero_binary_url = 'https://github.com/Incubaid/herolib/releases/download/v1.0.40/hero-x86_64-linux-musl'

fn deploy_vm() ! {
	// Initialize deployer (reads from env vars: TFGRID_MNEMONIC, SSH_KEY, TFGRID_NETWORK)
	deployer.get(create: true)!
	
	mut deployment := deployer.new_deployment(deployment_name)!
	
	deployment.configure_network(user_access_endpoints: 1)!
	
	deployment.add_machine(
		name:       vm_name
		cpu:        2
		memory:     4
		size:       50  // 50 GB disk
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
	
	// Wait for VM to be ready with retries
	wait_for_vm_ready(mycelium_ip)!
	
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
apt update && apt install -y redis-server curl sudo
/etc/init.d/redis-server start
cd /root
curl -L -o /usr/local/bin/hero "${hero_binary_url}" && chmod +x /usr/local/bin/hero

# Create heroscript
cat > act_runner.heroscript <<HEROSCRIPT_EOF
${heroscript}
HEROSCRIPT_EOF

# Run heroscript
echo "Running heroscript to install and configure action runner..."
hero run act_runner.heroscript

echo "Gitea Action Runner setup complete!"
'
	
	// Write setup script to temp file
	tmp_script := '/tmp/setup_runner.sh'
	osal.file_write(tmp_script, setup_script)!
	
	println('Copying setup script to VM...')
	scp_cmd := 'scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${tmp_script} root@[${mycelium_ip}]:/root/setup_runner.sh'
	osal.execute_silent(scp_cmd) or {
		return error('Failed to copy setup script: ${err}')
	}
	
	println('Running setup script on VM...')
	ssh_cmd := 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${mycelium_ip} "chmod +x /root/setup_runner.sh && /root/setup_runner.sh"'
	osal.execute_stdout(ssh_cmd) or {
		println('Warning: Setup script execution had issues: ${err}')
		println('You may need to manually run: ssh root@${mycelium_ip} "/root/setup_runner.sh"')
		return
	}
	println('✓ Gitea Action Runner installed and started successfully!')
	
	// Cleanup
	osal.rm(tmp_script) or {}
}

fn wait_for_vm_ready(mycelium_ip string) ! {
	max_retries := 3
	wait_time := 5 // seconds
	ssh_timeout := 10 // seconds for SSH command timeout
	
	for attempt in 1 .. max_retries + 1 {
		println('Waiting for VM to be fully ready (attempt ${attempt}/${max_retries}, ${wait_time} seconds)...')
		osal.sleep(wait_time)
		
		// Test SSH connectivity with timeout command wrapper
		println('Testing SSH connectivity (${ssh_timeout}s timeout)...')
		// Use timeout command to enforce hard limit
		test_cmd := 'timeout ${ssh_timeout} ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o ServerAliveInterval=2 -o ServerAliveCountMax=2 root@${mycelium_ip} "echo ready" 2>&1'
		
		// Use execute_silent which should respect the timeout command
		output := osal.execute_silent(test_cmd) or {
			if attempt < max_retries {
				println('⚠ SSH connection failed on attempt ${attempt}, retrying...')
				continue
			}
			return error('Failed to connect to VM after ${max_retries} attempts')
		}
		
		// Check if we got the expected output
		if output.contains('ready') {
			println('✓ VM is ready and SSH is accessible')
			return
		}
		
		if attempt < max_retries {
			println('⚠ VM not ready yet on attempt ${attempt}, retrying...')
		} else {
			return error('VM did not become ready after ${max_retries} attempts')
		}
	}
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
