module herorun

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.tmux
import freeflowuniverse.herolib.osal.core as osal
import time
import freeflowuniverse.herolib.builder
import json

pub struct Container {
pub mut:
	name string
	node ?&builder.Node
	tmux_pane ?&tmux.Pane
	factory &ContainerFactory
}

pub fn (mut self Container) start() ! {
	status := self.status()!
	if status == .running {
		console.print_debug('Container ${self.name} is already running')
		return
	}
	
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
	self.stop()!
	osal.exec(cmd: 'crun delete ${self.name}', stdout: false) or {}
	console.print_green('Container ${self.name} deleted')
}

// Execute command inside the container
pub fn (mut self Container) exec(args osal.ExecArgs) !string {
	// Ensure container is running
	if self.status()! != .running {
		self.start()!
	}
	
	// Use the builder node to execute inside container
	mut node := self.node()!
	return node.exec(cmd: args.cmd, stdout: args.stdout)
}

pub fn (self Container) status() !ContainerStatus {
	result := osal.exec(cmd: 'crun state ${self.name}', stdout: false) or {
		return .unknown
	}
	
	// Parse JSON output from crun state
	state := json.decode(map[string]json.Any, result) or {
		return .unknown
	}
	
	status_str := state['status'] or { json.Any('') }.str()
	
	return match status_str {
		'running' { .running }
		'stopped' { .stopped }
		'paused' { .paused }
		else { .unknown }
	}
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
	result := osal.exec(cmd: 'cat /sys/fs/cgroup/system.slice/crun-${self.name}.scope/cpu.stat', stdout: false) or {
		return 0.0
	}
	
	// Parse cpu.stat file and calculate usage percentage
	// This is a simplified implementation
	for line in result.split_into_lines() {
		if line.starts_with('usage_usec') {
			usage := line.split(' ')[1].f64()
			return usage / 1000000.0 // Convert to percentage
		}
	}
	return 0.0
}

// Get memory usage in MB
pub fn (self Container) mem_usage() !f64 {
	result := osal.exec(cmd: 'cat /sys/fs/cgroup/system.slice/crun-${self.name}.scope/memory.current', stdout: false) or {
		return 0.0
	}
	
	bytes := result.trim_space().f64()
	return bytes / (1024 * 1024) // Convert to MB
}

pub struct TmuxPaneArgs {
pub mut:
	window_name string
	pane_nr     int
	pane_name   string // optional
	cmd         string // optional, will execute this cmd
	reset       bool   // if true will reset everything and restart a cmd
	env         map[string]string // optional, will set these env vars in the pane
}

pub fn (mut self Container) tmux_pane(args TmuxPaneArgs) !&tmux.Pane {
	mut tmux_session := self.factory.tmux_session
	if tmux_session == '' {
		tmux_session = 'herorun'
	}
	
	// Get or create tmux session
	mut session := tmux.session_get(name: tmux_session) or {
		tmux.session_new(name: tmux_session)!
	}
	
	// Get or create window
	mut window := session.window_get(name: args.window_name) or {
		session.window_new(name: args.window_name)!
	}
	
	// Get or create pane
	mut pane := window.pane_get(nr: args.pane_nr) or {
		window.pane_new()!
	}
	
	if args.reset {
		pane.clear()!
	}
	
	// Set environment variables if provided
	for key, value in args.env {
		pane.send_keys('export ${key}="${value}"')!
	}
	
	// Execute command if provided
	if args.cmd != '' {
		// First enter the container namespace
		pane.send_keys('crun exec ${self.name} ${args.cmd}')!
	}
	
	self.tmux_pane = &pane
	return &pane
}

pub fn (mut self Container) node() !&builder.Node {
	if node := self.node {
		return node
	}
	
	// Create a new ExecutorCrun for this container
	mut executor := builder.ExecutorCrun{
		container_id: self.name
	}
	
	mut b := builder.new()!
	mut node := &builder.Node{
		name: 'container_${self.name}'
		executor: executor
		factory: &b
	}
	
	self.node = node
	return node
}