module heropods

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.tmux
import freeflowuniverse.herolib.osal.core as osal
import time
import freeflowuniverse.herolib.builder
import json

pub struct Container {
pub mut:
	name      string
	node      ?&builder.Node
	tmux_pane ?&tmux.Pane
	factory   &ContainerFactory
}

// Struct to parse JSON output of `crun state`
struct CrunState {
	id      string
	status  string
	pid     int
	bundle  string
	created string
}

pub fn (mut self Container) start() ! {
	// Check if container exists in crun
	container_exists := self.container_exists_in_crun()!

	if !container_exists {
		// Container doesn't exist, create it first
		console.print_debug('Container ${self.name} does not exist, creating it...')
		osal.exec(
			cmd:    'crun create --bundle ${self.factory.base_dir}/configs/${self.name} ${self.name}'
			stdout: true
		)!
		console.print_debug('Container ${self.name} created')
	}

	status := self.status()!
	if status == .running {
		console.print_debug('Container ${self.name} is already running')
		return
	}

	// If container exists but is stopped, we need to delete and recreate it
	// because crun doesn't allow restarting a stopped container
	if container_exists && status != .running {
		console.print_debug('Container ${self.name} exists but is stopped, recreating...')
		osal.exec(cmd: 'crun delete ${self.name}', stdout: false) or {}
		osal.exec(
			cmd:    'crun create --bundle ${self.factory.base_dir}/configs/${self.name} ${self.name}'
			stdout: true
		)!
		console.print_debug('Container ${self.name} recreated')
	}

	// start the container (crun start doesn't have --detach flag)
	osal.exec(cmd: 'crun start ${self.name}', stdout: true)!
	console.print_green('Container ${self.name} started')
}

pub fn (mut self Container) stop() ! {
	status := self.status()!
	if status == .stopped {
		console.print_debug('Container ${self.name} is already stopped')
		return
	}

	osal.exec(cmd: 'crun kill ${self.name} SIGTERM', stdout: false) or {}
	time.sleep(2 * time.second)

	// Force kill if still running
	if self.status()! == .running {
		osal.exec(cmd: 'crun kill ${self.name} SIGKILL', stdout: false) or {}
	}
	console.print_green('Container ${self.name} stopped')
}

pub fn (mut self Container) delete() ! {
	// Check if container exists before trying to delete
	if !self.container_exists_in_crun()! {
		console.print_debug('Container ${self.name} does not exist, nothing to delete')
		return
	}

	self.stop()!
	osal.exec(cmd: 'crun delete ${self.name}', stdout: false) or {}

	// Remove from factory's container cache
	if self.name in self.factory.containers {
		self.factory.containers.delete(self.name)
	}

	console.print_green('Container ${self.name} deleted')
}

// Execute command inside the container
pub fn (mut self Container) exec(cmd_ osal.Command) !string {
	// Ensure container is running
	if self.status()! != .running {
		self.start()!
	}

	// Use the builder node to execute inside container
	mut node := self.node()!
	return node.exec(cmd: cmd_.cmd, stdout: cmd_.stdout)
}

pub fn (self Container) status() !ContainerStatus {
	result := osal.exec(cmd: 'crun state ${self.name}', stdout: false) or { return .unknown }

	// Parse JSON output from crun state
	state := json.decode(CrunState, result.output) or { return .unknown }

	return match state.status {
		'running' { .running }
		'stopped' { .stopped }
		'paused' { .paused }
		else { .unknown }
	}
}

// Check if container exists in crun (regardless of its state)
fn (self Container) container_exists_in_crun() !bool {
	// Try to get container state - if it fails, container doesn't exist
	result := osal.exec(cmd: 'crun state ${self.name}', stdout: false) or { return false }

	// If we get here, the container exists (even if stopped/paused)
	return result.exit_code == 0
}

pub enum ContainerStatus {
	running
	stopped
	paused
	unknown
}

// Get CPU usage in percentage
pub fn (self Container) cpu_usage() !f64 {
	// Use cgroup stats to get CPU usage
	result := osal.exec(
		cmd:    'cat /sys/fs/cgroup/system.slice/crun-${self.name}.scope/cpu.stat'
		stdout: false
	) or { return 0.0 }

	for line in result.output.split_into_lines() {
		if line.starts_with('usage_usec') {
			usage := line.split(' ')[1].f64()
			return usage / 1000000.0 // Convert to percentage
		}
	}
	return 0.0
}

// Get memory usage in MB
pub fn (self Container) mem_usage() !f64 {
	result := osal.exec(
		cmd:    'cat /sys/fs/cgroup/system.slice/crun-${self.name}.scope/memory.current'
		stdout: false
	) or { return 0.0 }

	bytes := result.output.trim_space().f64()
	return bytes / (1024 * 1024) // Convert to MB
}

pub struct TmuxPaneArgs {
pub mut:
	window_name string
	pane_nr     int
	pane_name   string            // optional
	cmd         string            // optional, will execute this cmd
	reset       bool              // if true will reset everything and restart a cmd
	env         map[string]string // optional, will set these env vars in the pane
}

pub fn (mut self Container) tmux_pane(args TmuxPaneArgs) !&tmux.Pane {
	mut t := tmux.new()!
	session_name := 'herorun'

	mut session := if t.session_exist(session_name) {
		t.session_get(session_name)!
	} else {
		t.session_create(name: session_name)!
	}

	// Get or create window
	mut window := session.window_get(name: args.window_name) or {
		session.window_new(name: args.window_name)!
	}

	// Get existing pane by number, or create a new one
	mut pane := window.pane_get(args.pane_nr) or { window.pane_new()! }

	if args.reset {
		pane.clear()!
	}

	// Set environment variables if provided
	for key, value in args.env {
		pane.send_keys('export ${key}="${value}"')!
	}

	// Execute command if provided
	if args.cmd != '' {
		pane.send_keys('crun exec ${self.name} ${args.cmd}')!
	}

	self.tmux_pane = pane
	return pane
}

pub fn (mut self Container) node() !&builder.Node {
	// If node already initialized, return it
	if self.node != none {
		return self.node
	}

	mut b := builder.new()!

	mut exec := builder.ExecutorCrun{
		container_id: self.name
		debug:        false
	}

	exec.init() or {
		return error('Failed to init ExecutorCrun for container ${self.name}: ${err}')
	}

	// Create node using the factory method, then override the executor
	mut node := b.node_new(name: 'container_${self.name}', ipaddr: 'localhost')!
	node.executor = exec
	node.platform = .alpine
	node.cputype = .intel
	node.done = map[string]string{}
	node.environment = map[string]string{}
	node.hostname = self.name

	self.node = node
	return node
}
