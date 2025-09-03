module herorun

import os
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.tmux

// HetznerBackend implements NodeBackend for Hetzner cloud servers
pub struct HetznerBackend {
pub mut:
	node Node
}

// Create new Hetzner backend
pub fn new_hetzner_backend(args NewNodeArgs) !HetznerBackend {
	console.print_header('🖥️ Creating Hetzner Backend')
	console.print_stdout('IP: ${args.node_ip}')

	node := Node{
		settings: NodeSettings{
			node_ip: args.node_ip
			user:    args.user
		}
	}

	return HetznerBackend{
		node: node
	}
}

// Implement NodeBackend interface
pub fn (mut h HetznerBackend) connect(args NodeConnectArgs) ! {
	console.print_header('🔌 Connecting to Hetzner node')
	console.print_item('Node IP: ${h.node.settings.node_ip}')
	console.print_item('User: ${h.node.settings.user}')

	// Basic SSH connection test
	cmd := 'ssh ${h.node.settings.user}@${h.node.settings.node_ip} -o StrictHostKeyChecking=no exit'
	stream_command(cmd)!
	console.print_green('Connection successful')

	// Ensure required packages are installed
	console.print_header('📦 Ensuring required packages')
	install_cmd := 'ssh ${h.node.settings.user}@${h.node.settings.node_ip} "apt-get update && apt-get install -y runc tmux curl xz-utils"'
	stream_command(install_cmd)!
	console.print_green('Dependencies installed')
}

pub fn (h HetznerBackend) send_command(args SendCommandArgs) ! {
	console.print_header('💻 Running remote command on Hetzner')
	console.print_item('Command: ${args.cmd}')
	remote_cmd := 'ssh ${h.node.settings.user}@${h.node.settings.node_ip} "${args.cmd}"'
	stream_command(remote_cmd)!
}

pub fn (mut h HetznerBackend) get_or_create_container(args NewContainerArgs) !Container {
	console.print_header('📦 Get or create container: ${args.name}')

	// Check if container exists
	check_cmd := 'ssh ${h.node.settings.user}@${h.node.settings.node_ip} "runc list | grep ${args.name}"'
	code := os.system(check_cmd)

	if code != 0 {
		console.print_stdout('Container not found, creating...')
		h.create_container(args.name)!
	} else {
		console.print_stdout('Container already exists.')
	}

	// Create tmux session wrapper
	mut t := tmux.new(sessionid: args.name)!

	return Container{
		name: args.name
		node: h.node
		tmux: t
	}
}

pub fn (h HetznerBackend) get_info() !NodeInfo {
	return NodeInfo{
		ip:       h.node.settings.node_ip
		user:     h.node.settings.user
		provider: 'hetzner'
		status:   'connected'
	}
}

// Internal helper to create container
fn (h HetznerBackend) create_container(name string) ! {
	ver := '3.20.3'
	file := 'alpine-minirootfs-${ver}-x86_64.tar.gz'
	url := 'https://dl-cdn.alpinelinux.org/alpine/v${ver[..4]}/releases/x86_64/${file}'

	setup_cmd := '
		mkdir -p /containers/${name}/rootfs &&
		cd /containers/${name}/rootfs &&
		echo "📥 Downloading Alpine rootfs: ${url}" &&
		curl -fSL ${url} | tar -xzf - &&
		cd /containers/${name} &&
		rm -f config.json &&
		runc spec
	'

	remote_cmd := 'ssh ${h.node.settings.user}@${h.node.settings.node_ip} "${setup_cmd}"'
	stream_command(remote_cmd)!

	console.print_green('Container ${name} rootfs prepared')
}

// Helper function for streaming commands
fn stream_command(cmd string) ! {
	console.print_debug_title('Executing', cmd)
	code := os.system(cmd)
	if code != 0 {
		console.print_stderr('Command failed: ${cmd} (exit ${code})')
		return error('command failed: ${cmd} (exit ${code})')
	}
}
