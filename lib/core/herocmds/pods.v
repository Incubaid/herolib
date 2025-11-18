module herocmds

import cli { Command, Flag }
import incubaid.herolib.virt.heropods
import incubaid.herolib.ui.console

pub fn cmd_pods(mut cmdroot Command) {
	mut cmd_pods := Command{
		name:          'pods'
		description:   'Manage lightweight OCI containers with HeroPods'
		usage:         '
HeroPods Container Management

USAGE:
  hero pods <subcommand> [options]

EXAMPLES:
  hero pods ps                           # List all containers
  hero pods images ls                    # List available images
  hero pods create alpine_3_20           # Create container from image
  hero pods start mycontainer            # Start a container
  hero pods stop mycontainer             # Stop a container
  hero pods rm mycontainer               # Remove a container
  hero pods exec mycontainer ls -la      # Execute command in container
  hero pods inspect mycontainer          # Show container details
'
		execute:       cmd_pods_execute
		sort_commands: true
	}

	// ps - list containers
	mut cmd_ps := Command{
		name:        'ps'
		description: 'List all containers (running and stopped)'
		execute:     cmd_pods_execute
	}

	// images - image management
	mut cmd_images := Command{
		name:        'images'
		description: 'Manage container images'
		execute:     cmd_pods_execute
	}

	mut cmd_images_ls := Command{
		name:        'ls'
		description: 'List all available images'
		execute:     cmd_pods_execute
	}

	cmd_images.add_command(cmd_images_ls)

	// create - create container
	mut cmd_create := Command{
		name:        'create'
		description: 'Create a new container from an image'
		execute:     cmd_pods_execute
	}

	cmd_create.add_flag(Flag{
		flag:        .string
		name:        'name'
		abbrev:      'n'
		description: 'Container name (required)'
	})

	cmd_create.add_flag(Flag{
		flag:        .string
		name:        'docker-url'
		abbrev:      'd'
		description: 'Docker image URL (e.g., docker.io/library/alpine:3.20)'
	})

	// start - start container
	mut cmd_start := Command{
		name:        'start'
		description: 'Start a stopped container'
		execute:     cmd_pods_execute
	}

	// stop - stop container
	mut cmd_stop := Command{
		name:        'stop'
		description: 'Stop a running container'
		execute:     cmd_pods_execute
	}

	// rm - remove container
	mut cmd_rm := Command{
		name:        'rm'
		description: 'Remove/delete a container'
		execute:     cmd_pods_execute
	}

	cmd_rm.add_flag(Flag{
		flag:        .bool
		name:        'force'
		abbrev:      'f'
		description: 'Force remove running container'
	})

	// exec - execute command
	mut cmd_exec := Command{
		name:        'exec'
		description: 'Execute a command inside a running container'
		execute:     cmd_pods_execute
	}

	// inspect - show container details
	mut cmd_inspect := Command{
		name:        'inspect'
		description: 'Show detailed information about a container'
		execute:     cmd_pods_execute
	}

	// Add all subcommands
	cmd_pods.add_command(cmd_ps)
	cmd_pods.add_command(cmd_images)
	cmd_pods.add_command(cmd_create)
	cmd_pods.add_command(cmd_start)
	cmd_pods.add_command(cmd_stop)
	cmd_pods.add_command(cmd_rm)
	cmd_pods.add_command(cmd_exec)
	cmd_pods.add_command(cmd_inspect)

	cmdroot.add_command(cmd_pods)
}

fn cmd_pods_execute(cmd Command) ! {
	// Get or create HeroPods instance
	mut hp := heropods.get() or { heropods.new(reset: false, use_podman: true)! }

	match cmd.name {
		'ps' {
			cmd_ps_execute(mut hp)!
		}
		'ls' {
			// This is images ls
			cmd_images_ls_execute(mut hp)!
		}
		'create' {
			cmd_create_execute(mut hp, cmd)!
		}
		'start' {
			cmd_start_execute(mut hp, cmd)!
		}
		'stop' {
			cmd_stop_execute(mut hp, cmd)!
		}
		'rm' {
			cmd_rm_execute(mut hp, cmd)!
		}
		'exec' {
			cmd_exec_execute(mut hp, cmd)!
		}
		'inspect' {
			cmd_inspect_execute(mut hp, cmd)!
		}
		else {
			return error(cmd.help_message())
		}
	}
}

// List all containers
fn cmd_ps_execute(mut hp heropods.HeroPods) ! {
	containers := hp.list()!

	if containers.len == 0 {
		console.print_header('No containers found')
		return
	}

	// Print header
	println('CONTAINER NAME       STATUS      PID')
	println('─'.repeat(50))

	// Print each container
	for container in containers {
		status := container.status() or { heropods.ContainerStatus.stopped }
		pid := container.pid() or { 0 }

		status_str := match status {
			.running { 'running' }
			.stopped { 'stopped' }
			.paused { 'paused' }
			.unknown { 'unknown' }
		}

		pid_str := if pid > 0 { pid.str() } else { '-' }

		println('${container.name:-20} ${status_str:-11} ${pid_str}')
	}
}

// List all images
fn cmd_images_ls_execute(mut hp heropods.HeroPods) ! {
	images := hp.images_list()!

	if images.len == 0 {
		console.print_header('No images found')
		return
	}

	// Print header
	println('IMAGE NAME           SIZE        CREATED')
	println('─'.repeat(60))

	// Print each image
	for image in images {
		size_str := if image.size_mb > 0 {
			'${image.size_mb:.1f}MB'
		} else {
			'-'
		}

		created_str := if image.created_at != '' {
			image.created_at
		} else {
			'-'
		}

		println('${image.image_name:-20} ${size_str:-11} ${created_str}')
	}
}

// Create a new container
fn cmd_create_execute(mut hp heropods.HeroPods, cmd Command) ! {
	container_name := cmd.flags.get_string('name') or {
		if cmd.args.len > 0 {
			cmd.args[0]
		} else {
			return error('Container name is required. Use --name or provide as argument')
		}
	}

	docker_url := cmd.flags.get_string('docker-url') or { '' }
	image_name := if cmd.args.len > 1 { cmd.args[1] } else { container_name }

	console.print_header('Creating container: ${container_name}')

	hp.container_new(
		name:              container_name
		image:             .custom
		custom_image_name: image_name
		docker_url:        docker_url
	)!

	console.print_green('✓ Container ${container_name} created successfully')
}

// Start a container
fn cmd_start_execute(mut hp heropods.HeroPods, cmd Command) ! {
	if cmd.args.len == 0 {
		return error('Container name is required')
	}

	container_name := cmd.args[0]
	console.print_header('Starting container: ${container_name}')

	mut container := hp.get(name: container_name)!

	container.start()!
	console.print_green('✓ Container ${container_name} started successfully')
}

// Stop a container
fn cmd_stop_execute(mut hp heropods.HeroPods, cmd Command) ! {
	if cmd.args.len == 0 {
		return error('Container name is required')
	}

	container_name := cmd.args[0]
	console.print_header('Stopping container: ${container_name}')

	mut container := hp.get(name: container_name)!

	container.stop()!
	console.print_green('✓ Container ${container_name} stopped successfully')
}

// Remove a container
fn cmd_rm_execute(mut hp heropods.HeroPods, cmd Command) ! {
	if cmd.args.len == 0 {
		return error('Container name is required')
	}

	container_name := cmd.args[0]
	force := cmd.flags.get_bool('force') or { false }

	console.print_header('Removing container: ${container_name}')

	mut container := hp.get(name: container_name)!

	// Stop if running and force flag is set
	if force {
		status := container.status() or { heropods.ContainerStatus.stopped }
		if status == .running {
			console.print_debug('Force stopping container...')
			container.stop()!
		}
	}

	container.delete()!
	console.print_green('✓ Container ${container_name} removed successfully')
}

// Execute command in container
fn cmd_exec_execute(mut hp heropods.HeroPods, cmd Command) ! {
	if cmd.args.len < 2 {
		return error('Usage: hero pods exec <container_name> <command> [args...]')
	}

	container_name := cmd.args[0]
	command := cmd.args[1..].join(' ')

	mut container := hp.get(name: container_name)!

	result := container.exec(cmd: command, stdout: true)!
	println(result)
}

// Inspect container
fn cmd_inspect_execute(mut hp heropods.HeroPods, cmd Command) ! {
	if cmd.args.len == 0 {
		return error('Container name is required')
	}

	container_name := cmd.args[0]

	mut container := hp.get(name: container_name)!

	console.print_header('Container: ${container_name}')

	// Get status
	status := container.status() or { heropods.ContainerStatus.unknown }
	println('Status: ${status}')

	// Get PID if running
	if status == .running {
		pid := container.pid() or { 0 }
		if pid > 0 {
			println('PID: ${pid}')

			// Show network namespace info
			println('\nNetwork:')
			println('  To access container network:')
			println('    nsenter -t ${pid} -n <command>')
			println('  To get shell in container:')
			println('    nsenter -t ${pid} -n -m -p /bin/sh')
		}
	}

	// Show crun command
	println('\nManagement:')
	crun_root := '${hp.base_dir}/runtime'
	println('  Crun root: ${crun_root}')
	println('  Execute command: crun --root ${crun_root} exec ${container_name} <command>')
	println('  View state: crun --root ${crun_root} state ${container_name}')
}
