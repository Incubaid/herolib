module herorun2

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.tmux
import time

// Container struct and related functionality
pub struct Container {
pub:
	name string
	node Node
pub mut:
	tmux tmux.Tmux
}

// Implement ContainerBackend interface for Container
pub fn (mut c Container) attach() ! {
	console.print_header('🔗 Attaching to container: ${c.name}')

	// Create or get the session for this container
	if !c.tmux.session_exist(c.name) {
		console.print_stdout('Starting new tmux session for container ${c.name}')

		// Use the tmux convenience method to create session and window in one go
		shell_cmd := 'ssh ${c.node.settings.user}@${c.node.settings.node_ip}'
		c.tmux.window_new(
			session_name: c.name
			name:         'main'
			cmd:          shell_cmd
			reset:        true
		)!

		// Wait for the session and window to be properly created
		time.sleep(500 * time.millisecond)

		// Rescan to make sure everything is properly registered
		c.tmux.scan()!
	}

	console.print_green('Attached to container session ${c.name}')
}

pub fn (mut c Container) send_command(args ContainerCommandArgs) ! {
	console.print_header('📝 Exec in container ${c.name}')

	// Ensure session exists
	if !c.tmux.session_exist(c.name) {
		return error('Container session ${c.name} does not exist. Call attach() first.')
	}

	// Debug: print session info
	mut session := c.tmux.session_get(c.name)!
	console.print_debug('Session ${c.name} has ${session.windows.len} windows')
	for window in session.windows {
		console.print_debug('  Window: ${window.name} (ID: ${window.id})')
	}

	// Try to get the main window
	mut window := session.window_get(name: 'main') or {
		// If main window doesn't exist, try to get the first window
		if session.windows.len > 0 {
			session.windows[0]
		} else {
			return error('No windows available in session ${c.name}')
		}
	}

	// Refresh window state to get current panes
	window.scan()!

	// Get the first pane and send the command
	if window.panes.len > 0 {
		mut pane := window.panes[0]

		// Send command to enter the container first, then the actual command
		container_enter_cmd := 'cd /containers/${c.name} && runc exec ${c.name} ${args.cmd}'
		pane.send_command(container_enter_cmd)!
	} else {
		return error('No panes available in container ${c.name}')
	}
}

pub fn (mut c Container) get_logs() !string {
	// Get the session and window
	mut session := c.tmux.session_get(c.name)!
	mut window := session.window_get(name: 'main')!

	// Get logs from the first pane
	if window.panes.len > 0 {
		mut pane := window.panes[0]
		return pane.logs_all()!
	} else {
		return error('No panes available in container ${c.name}')
	}
}
