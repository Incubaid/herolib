module herorun2

import incubaid.herolib.osal.tmux
import incubaid.herolib.osal.sshagent
import incubaid.herolib.osal.core as osal
import time
import os

// Executor - Optimized for AI agent usage with proper module integration
pub struct Executor {
pub mut:
	node         Node
	container_id string
	image_script string
	base_image   BaseImage
	tmux         tmux.Tmux
	session_name string
	window_name  string
	agent        sshagent.SSHAgent
}

@[params]
pub struct ExecutorArgs {
pub:
	node_ip      string @[required]
	user         string @[required]
	container_id string @[required]
	keyname      string @[required]
	image_script string // Optional entry point script
	base_image   BaseImage = .alpine // Base image type (default: alpine)
}

// Create new executor with proper module integration
pub fn new_executor(args ExecutorArgs) !Executor {
	node := Node{
		settings: NodeSettings{
			node_ip: args.node_ip
			user:    args.user
		}
	}

	// Initialize SSH agent properly
	mut agent := sshagent.new_single()!
	if !agent.is_agent_responsive() {
		return error('SSH agent is not responsive')
	}
	agent.init()!

	// Initialize tmux properly
	mut t := tmux.new(sessionid: args.container_id)!

	// Initialize Hetzner manager properly
	mut hetzner := hetznermanager.get() or { hetznermanager.new()! }

	return Executor{
		node:         node
		container_id: args.container_id
		image_script: args.image_script
		base_image:   args.base_image
		tmux:         t
		session_name: args.container_id
		window_name:  'main'
		agent:        agent
		hetzner:      hetzner
	}
}

// Setup - Create container and tmux infrastructure using proper modules
pub fn (mut e Executor) setup() ! {
	e.install_requirements()!
	e.ensure_container()!
	e.ensure_tmux_infrastructure()!
}

// Execute - Fast command execution using osal module
pub fn (mut e Executor) execute(cmd string) !string {
	// Handle runc commands specially - they need to be run from container directory
	mut final_cmd := cmd
	if cmd.starts_with('runc ') {
		// Extract container name from runc command
		parts := cmd.split(' ')
		if parts.len >= 3 {
			container_name := parts[2]
			final_cmd = 'cd /containers/${container_name} && ${cmd}'
		}
	}

	// Execute via SSH using osal module for clean output
	ssh_cmd := 'ssh ${e.node.settings.user}@${e.node.settings.node_ip} "${final_cmd}"'
	result := osal.exec(cmd: ssh_cmd, stdout: false, name: 'executor_command')!
	return result.output
}

// Execute with tmux - for interactive sessions
pub fn (mut e Executor) execute_tmux(cmd string, context_id string) !string {
	// Ensure we have the latest state
	if !e.tmux.session_exist(e.session_name) {
		return error('Session ${e.session_name} does not exist. Run setup first.')
	}

	// Get the session and window using tmux module
	mut session := e.tmux.session_get(e.session_name)!
	mut window := session.window_get(name: e.window_name)!

	// Only scan if we have no panes
	if window.panes.len == 0 {
		window.scan()!
	}

	if window.panes.len == 0 {
		return error('No panes available in window ${e.window_name}')
	}

	// Get the active pane using tmux module
	mut active_pane := window.pane_active() or { window.panes[0] }

	// Execute command using tmux pane
	active_pane.send_command(cmd)!

	// Wait briefly for command to execute
	time.sleep(200 * time.millisecond)

	// Get output using tmux module
	output := active_pane.logs_all() or { '' }

	return output
}

// Get or create container with optional image script
pub fn (mut e Executor) get_or_create_container(args NewContainerArgs) !Container {
	// Update container_id, image_script, and base_image from args
	e.container_id = args.name
	e.image_script = args.image_script
	e.base_image = args.base_image
	e.session_name = args.name

	// Ensure container exists
	e.ensure_container()!

	// Return container instance
	return Container{
		name: args.name
		node: e.node
		tmux: e.tmux
	}
}

// Cleanup - Remove everything using proper modules
pub fn (mut e Executor) cleanup() ! {
	// Kill tmux session using tmux module
	if e.tmux.session_exist(e.session_name) {
		e.tmux.session_delete(e.session_name)!
	}

	// Remove container using osal module
	e.remove_container()!
}

// Internal helper methods using proper modules
fn (mut e Executor) install_requirements() ! {
	// Install all required packages using the installer module
	install_all_requirements(e.node.settings.node_ip, e.node.settings.user)!
}

fn (mut e Executor) ensure_container() ! {
	// Check if container exists using osal module
	check_cmd := 'ssh ${e.node.settings.user}@${e.node.settings.node_ip} "runc list | grep ${e.container_id}"'
	result := osal.execute_silent(check_cmd) or { '' }

	if result == '' {
		e.create_container()!
	}
}

fn (mut e Executor) create_container() ! {
	// Determine base image and setup command
	mut setup_cmd := ''

	match e.base_image {
		.alpine_python {
			// Use Docker to create a Python-enabled Alpine container
			setup_cmd = '
				mkdir -p /containers/${e.container_id}/rootfs &&
				cd /containers/${e.container_id} &&
				# Create a simple Dockerfile for Alpine with Python
				cat > Dockerfile << EOF
				FROM alpine:3.20
				RUN apk add --no-cache python3 py3-pip
				WORKDIR /
				CMD ["/bin/sh"]
				EOF
				# Build and export the container filesystem
				docker build -t ${e.container_id}-base . &&
				docker create --name ${e.container_id}-temp ${e.container_id}-base &&
				docker export ${e.container_id}-temp | tar -xf - -C rootfs &&
				docker rm ${e.container_id}-temp &&
				docker rmi ${e.container_id}-base &&
				rm Dockerfile &&
				runc spec
			'
		}
		.alpine {
			// Default: Use standard Alpine minirootfs
			ver := '3.20.3'
			file := 'alpine-minirootfs-${ver}-x86_64.tar.gz'
			url := 'https://dl-cdn.alpinelinux.org/alpine/v${ver[..4]}/releases/x86_64/${file}'

			setup_cmd = '
				mkdir -p /containers/${e.container_id}/rootfs &&
				cd /containers/${e.container_id}/rootfs &&
				curl -fSL ${url} | tar -xzf - &&
				cd /containers/${e.container_id} &&
				rm -f config.json &&
				runc spec
			'
		}
	}

	setup_cmd = texttools.dedent(setup_cmd)

	remote_cmd := 'ssh ${e.node.settings.user}@${e.node.settings.node_ip} "${setup_cmd}"'
	osal.exec(cmd: remote_cmd, stdout: false, name: 'container_create')!

	// Configure container for non-interactive execution and writable filesystem
	config_cmd := "ssh ${e.node.settings.user}@${e.node.settings.node_ip} \"cd /containers/${e.container_id} && if ! command -v jq >/dev/null 2>&1; then if command -v apt-get >/dev/null 2>&1; then apt-get update && apt-get install -y jq; elif command -v apk >/dev/null 2>&1; then apk add --no-cache jq; fi; fi && jq '.process.terminal = false | .root.readonly = false' config.json > config.json.tmp && mv config.json.tmp config.json\""
	osal.exec(cmd: config_cmd, stdout: false, name: 'configure_container')!

	// If image_script is provided, copy it and configure as entry point
	if e.image_script != '' {
		e.setup_image_script()!
	}
}

fn (mut e Executor) setup_image_script() ! {
	// Resolve the script path - handle relative paths
	mut script_path := e.image_script
	if script_path.starts_with('./') {
		// Convert relative path to absolute path
		current_dir := os.getwd()
		script_path = '${current_dir}/${script_path[2..]}'
	}

	// Check if file exists
	if !os.exists(script_path) {
		return error('Image script file not found: ${script_path}')
	}

	// Read the script content from the resolved path
	script_content := osal.file_read(script_path)!

	// Create the script on the remote container rootfs
	create_script_cmd := 'ssh ${e.node.settings.user}@${e.node.settings.node_ip} "mkdir -p /containers/${e.container_id}/rootfs"'
	osal.exec(cmd: create_script_cmd, stdout: false, name: 'create_dir')!

	// Write script content to a temporary file and copy it
	script_file := '/tmp/entrypoint_${e.container_id}.sh'
	osal.file_write(script_file, script_content)!

	// Copy script to remote container
	copy_cmd := 'scp ${script_file} ${e.node.settings.user}@${e.node.settings.node_ip}:/containers/${e.container_id}/rootfs/entrypoint.sh'
	osal.exec(cmd: copy_cmd, stdout: false, name: 'copy_script')!

	// Make script executable
	chmod_cmd := 'ssh ${e.node.settings.user}@${e.node.settings.node_ip} "chmod +x /containers/${e.container_id}/rootfs/entrypoint.sh"'
	osal.exec(cmd: chmod_cmd, stdout: false, name: 'chmod_script')!

	// Clean up temporary file
	osal.rm(script_file)!

	// Install jq if needed and modify config.json to use the script as entry point, disable terminal, and enable writable filesystem
	config_update_cmd := "ssh ${e.node.settings.user}@${e.node.settings.node_ip} \"cd /containers/${e.container_id} && if ! command -v jq >/dev/null 2>&1; then if command -v apt-get >/dev/null 2>&1; then apt-get update && apt-get install -y jq; elif command -v apk >/dev/null 2>&1; then apk add --no-cache jq; fi; fi && jq \\\".process.args = [\\\\\\\"/entrypoint.sh\\\\\\\"] | .process.terminal = false | .root.readonly = false\\\" config.json > config.json.tmp && mv config.json.tmp config.json\""
	osal.exec(cmd: config_update_cmd, stdout: false, name: 'update_config')!
}

fn (mut e Executor) ensure_tmux_infrastructure() ! {
	// Create session and window using tmux module properly
	if !e.tmux.session_exist(e.session_name) {
		// Create session with window using tmux module
		shell_cmd := 'ssh ${e.node.settings.user}@${e.node.settings.node_ip}'
		e.tmux.window_new(
			session_name: e.session_name
			name:         e.window_name
			cmd:          shell_cmd
			reset:        true
		)!

		// Wait for setup
		time.sleep(300 * time.millisecond)
	}
}

fn (mut e Executor) remove_container() ! {
	// Use osal module for cleanup
	remove_cmd := 'ssh ${e.node.settings.user}@${e.node.settings.node_ip} "runc delete ${e.container_id} --force || true && rm -rf /containers/${e.container_id}"'
	osal.exec(cmd: remove_cmd, stdout: false, name: 'container_cleanup') or {
		// Ignore cleanup errors
	}
}
