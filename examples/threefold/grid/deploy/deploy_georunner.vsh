#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import encoding.base64
import incubaid.herolib.mycelium.grid3.models
import incubaid.herolib.mycelium.grid3.deployer as tfgrid
import json
import log
import rand

const (
	ssh_pubkey          = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHbPISDJ/xlRwMb+ZyASL+HJuZE8gM2wVXkwyxSGaGfFEEqUDibVZ3Bvl/rrlwcvYHGheIilzl4a9kYyxTNG93I2z1th12wf+5BM2pWfaumxyfb7b2sKT1wufNIhcNKXOOjydX74y9CNZH2p/lCS6szIC84vq9NQtDy5xzxEGsD423phvdXc3pNt1qLP9NxGK5tZEeWAKVLE+kh22Qsq9pqVcmsz43rte+eKXiXBNxqQCTWm17q1dR9C9NFq8VRp+hfSDC7BzsfYhXHtfINKmnbySrZ5Zv1mXsZW5NDPEk1YhujKZnJj4cIdMAHOxPfIDvWy1CmhyRKSgGK79I7Z+b'
	gitea_url           = 'https://git.ourworld.tf/'
	gitea_runner_token  = '08f91979684ef4a79e02ce68f5c3b325a267c444'
	runner_name         = 'georunner01'
	runner_label        = 'georunnertest01'
	act_runner_version  = '0.2.7'
	network_name        = 'georunner01net'
	vm_ip_range         = '10.42.0.0/16'
	vm_subnet           = '10.42.1.0/24'
	vm_private_ip       = '10.42.1.10'
	wireguard_peer_cidr = '10.42.2.0/24'
	wireguard_port      = 3012
)

fn main() {
	deploy_georunner() or {
		eprintln('deployment failed: ${err}')
	}
}

fn deploy_georunner() ! {
	mut logger := &log.Log{}
	logger.set_level(.debug)

	mnemonics := tfgrid.get_mnemonics()!
	mut deployer := tfgrid.new_deployer(mnemonics, tfgrid.ChainNetwork.main)!

	node_keys := deployer.client.generate_wg_priv_key()!
	user_keys := deployer.client.generate_wg_priv_key()!
	println('Save these WireGuard credentials to reach the VM:')
	println(' - Client private key: ${user_keys[0]}')
	println(' - Client public key : ${user_keys[1]}')

	mut network := models.Znet{
		ip_range:              vm_ip_range
		subnet:                vm_subnet
		wireguard_private_key: node_keys[0]
		wireguard_listen_port: wireguard_port
		peers:                 [
			models.Peer{
				subnet:               wireguard_peer_cidr
				wireguard_public_key: user_keys[1]
				allowed_ips:          [wireguard_peer_cidr, '${vm_private_ip}/32']
			},
		]
		mycelium: models.Mycelium{
			hex_key: rand.string(32).bytes().hex()
		}
	}

	mut znet_workload := network.to_workload(name: network_name, description: 'WireGuard-only network for ${runner_name}')

	disk_name := '${runner_name}disk'
	zmount := models.Zmount{
		// 20 GB disk for the VM
		size: i64(20) * 1024 * 1024 * 1024
	}
	zmount_workload := zmount.to_workload(name: disk_name)

	mount := models.Mount{
		name:       disk_name
		mountpoint: '/disk1'
	}

	user_data := build_cloud_init_config()
	mut env := map[string]string{}
	env['SSH_KEY'] = ssh_pubkey
	env['USER_DATA'] = base64.encode(user_data.bytes())

	mut zmachine := models.Zmachine{
		flist:      'https://hub.grid.tf/tf-official-vms/ubuntu-22.04.flist'
		entrypoint: '/sbin/zinit init'
		size:       u64(100) * 1024 * 1024 * 1024
		compute_capacity: models.ComputeCapacity{
			cpu:    u8(4)
			memory: i64(8) * 1024 * 1024 * 1024
		}
		network: models.ZmachineNetwork{
			interfaces: [
				models.ZNetworkInterface{
					network: network_name
					ip:      vm_private_ip
				},
			]
			planetary: false
			mycelium:  models.MyceliumIP{
				network:  network_name
				hex_seed: rand.string(6).bytes().hex()
			}
		}
		env:    env
		mounts: [mount]
	}

	mut zmachine_workload := models.Workload{
		version:     0
		name:        runner_name
		type_:       models.workload_types.zmachine
		data:        json.encode(zmachine)
		description: 'Ubuntu 22.04 VM hosting ${runner_label}'
	}

	twin_id := deployer.client.get_user_twin()!
	mut deployment := models.Deployment{
		version:     0
		twin_id:     twin_id
		description: 'Single-VM deployment for ${runner_name}'
		workloads:   [znet_workload, zmount_workload, zmachine_workload]
		signature_requirement: models.SignatureRequirement{
			weight_required: 1
			requests:        [
				models.SignatureRequest{
					twin_id: twin_id
					weight:  1
				},
			]
		}
	}

	deployment.add_metadata('vm', runner_name)
	deployment.add_metadata('myproject', 'georunner')

	node_id := u32(8)
	solution_provider := u64(0)
	contract_id := deployer.deploy(node_id, mut deployment, deployment.metadata, solution_provider)!

	logger.info('Deployment successful. Contract ID: ${contract_id}')
	logger.info('Node WireGuard public key: ${node_keys[1]} (port ${wireguard_port})')
	logger.info('Zmachine private IP: ${vm_private_ip}')
	dl := deployer.get_deployment(contract_id, node_id)!
	machine_res := get_machine_result(dl)!
	logger.info('Zmachine Mycelium IP: ${machine_res.mycelium_ip}')
	println('Configure your local WireGuard peer to reach ${vm_private_ip} via node 8 using the printed keys.')
}

fn build_cloud_init_config() string {
	return "#cloud-config\npackage_update: true\npackage_upgrade: true\npackages:\n  - curl\n  - ca-certificates\n  - git\n  - unzip\n  - tar\n  - systemd\nwrite_files:\n  - path: /opt/act_runner/bootstrap.sh\n    permissions: '0755'\n    owner: root:root\n    content: |\n      #!/bin/bash\n      set -euo pipefail\n      version=${act_runner_version}\n      install_dir=/opt/act_runner\n      mkdir -p \"/opt/act_runner\"\n      cd \"/opt/act_runner\"\n      curl -fsSL https://dl.gitea.com/runner/${act_runner_version}/act_runner-${act_runner_version}-linux-amd64.tar.gz -o act_runner.tar.gz\n      tar -xf act_runner.tar.gz\n      rm act_runner.tar.gz\n      ./act_runner generate-config > /opt/act_runner/config.yaml\n      ./act_runner register --config /opt/act_runner/config.yaml --instance ${gitea_url} --token ${gitea_runner_token} --name ${runner_name} --labels ${runner_label} --no-interactive\n      useradd --system --home-dir /opt/act_runner --shell /usr/sbin/nologin gitea-runner || true\n      chown -R gitea-runner:gitea-runner /opt/act_runner\n      cat >/etc/systemd/system/gitea-runner.service <<'SERVICE'\n      [Unit]\n      Description=Gitea Actions Runner ${runner_name}\n      After=network-online.target\n      Wants=network-online.target\n\n      [Service]\n      WorkingDirectory=/opt/act_runner\n      ExecStart=/opt/act_runner/act_runner daemon --config /opt/act_runner/config.yaml\n      Restart=always\n      RestartSec=3\n      User=gitea-runner\n      Group=gitea-runner\n      Environment=GITEA_INSTANCE_URL=${gitea_url}\n      Environment=GITEA_RUNNER_TOKEN=${gitea_runner_token}\n\n      [Install]\n      WantedBy=multi-user.target\n      SERVICE\n      systemctl daemon-reload\n      systemctl enable --now gitea-runner.service\nruncmd:\n  - ['/opt/act_runner/bootstrap.sh']\n"
}

fn get_machine_result(dl models.Deployment) !models.ZmachineResult {
	for _, w in dl.workloads {
		if w.type_ == models.workload_types.zmachine {
			res := json.decode(models.ZmachineResult, w.result.data)!
			return res
		}
	}

	return error('failed to get zmachine workload')
}
