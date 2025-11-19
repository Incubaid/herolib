module heropods

import incubaid.herolib.osal.tmux
import incubaid.herolib.osal.core as osal
import incubaid.herolib.virt.crun
import time
import incubaid.herolib.builder
import json

// Container lifecycle timeout constants
const cleanup_retry_delay_ms = 500 // Time to wait for filesystem cleanup to complete
const sigterm_timeout_ms = 5000 // Time to wait for graceful shutdown (5 seconds)
const sigkill_wait_ms = 500 // Time to wait after SIGKILL
const stop_check_interval_ms = 500 // Interval to check if container stopped

// Container represents a running or stopped OCI container managed by crun
//
// Thread Safety:
// Container operations that interact with network configuration (start, stop, delete)
// are thread-safe because they delegate to HeroPods.network_* methods which use
// the network_mutex for protection.
@[heap]
pub struct Container {
pub mut:
	name        string            // Unique container name
	node        ?&builder.Node    // Builder node for executing commands inside container
	tmux_pane   ?&tmux.Pane       // Optional tmux pane for interactive access
	crun_config ?&crun.CrunConfig // OCI runtime configuration
	factory     &HeroPods         // Reference to parent HeroPods instance
}

// CrunState represents the JSON output of `crun state` command
struct CrunState {
	id      string // Container ID
	status  string // Container status (running, stopped, paused)
	pid     int    // PID of container init process
	bundle  string // Path to OCI bundle
	created string // Creation timestamp
}

// Start the container
//
// This method handles the complete container startup lifecycle:
// 1. Creates the container in crun if it doesn't exist
// 2. Handles leftover state cleanup if creation fails
// 3. Starts the container process
// 4. Sets up networking (thread-safe via network_mutex)
//
// Thread Safety:
// Network setup is thread-safe via HeroPods.network_setup_container()
pub fn (mut self Container) start() ! {
	// Check if container exists in crun
	container_exists := self.container_exists_in_crun()!

	if !container_exists {
		// Container doesn't exist, create it first
		self.factory.logger.log(
			cat:     'container'
			log:     'Container ${self.name} does not exist, creating it...'
			logtype: .stdout
		) or {}
		// Try to create the container, if it fails with "File exists" error,
		// try to force delete any leftover state and retry
		crun_root := '${self.factory.base_dir}/runtime'
		_ := osal.exec(
			cmd:    'crun --root ${crun_root} create --bundle ${self.factory.base_dir}/configs/${self.name} ${self.name}'
			stdout: true
		) or {
			if err.msg().contains('File exists') {
				self.factory.logger.log(
					cat:     'container'
					log:     'Container creation failed with "File exists", attempting to clean up leftover state...'
					logtype: .stdout
				) or {}
				// Force delete any leftover state - try multiple cleanup approaches
				osal.exec(cmd: 'crun --root ${crun_root} delete ${self.name}', stdout: false) or {}
				osal.exec(cmd: 'crun delete ${self.name}', stdout: false) or {} // Also try default root
				// Clean up any leftover runtime directories
				osal.exec(cmd: 'rm -rf ${crun_root}/${self.name}', stdout: false) or {}
				osal.exec(cmd: 'rm -rf /run/crun/${self.name}', stdout: false) or {}
				// Wait a moment for cleanup to complete
				time.sleep(cleanup_retry_delay_ms * time.millisecond)
				// Retry creation
				osal.exec(
					cmd:    'crun --root ${crun_root} create --bundle ${self.factory.base_dir}/configs/${self.name} ${self.name}'
					stdout: true
				)!
			} else {
				return err
			}
		}
		self.factory.logger.log(
			cat:     'container'
			log:     'Container ${self.name} created'
			logtype: .stdout
		) or {}
	}

	status := self.status()!
	if status == .running {
		self.factory.logger.log(
			cat:     'container'
			log:     'Container ${self.name} is already running'
			logtype: .stdout
		) or {}
		return
	}

	// If container exists but is stopped, we need to delete and recreate it
	// because crun doesn't allow restarting a stopped container
	if container_exists && status != .running {
		self.factory.logger.log(
			cat:     'container'
			log:     'Container ${self.name} exists but is stopped, recreating...'
			logtype: .stdout
		) or {}
		crun_root := '${self.factory.base_dir}/runtime'
		osal.exec(cmd: 'crun --root ${crun_root} delete ${self.name}', stdout: false) or {}
		osal.exec(
			cmd:    'crun --root ${crun_root} create --bundle ${self.factory.base_dir}/configs/${self.name} ${self.name}'
			stdout: true
		)!
		self.factory.logger.log(
			cat:     'container'
			log:     'Container ${self.name} recreated'
			logtype: .stdout
		) or {}
	}

	// start the container (crun start doesn't have --detach flag)
	crun_root := '${self.factory.base_dir}/runtime'
	// Start the container
	osal.exec(cmd: 'crun --root ${crun_root} start ${self.name}', stdout: true) or {
		return error('Failed to start container: ${err}')
	}

	// Setup network for the container (thread-safe)
	// If this fails, stop the container to clean up
	self.setup_network() or {
		self.factory.logger.log(
			cat:     'container'
			log:     'Network setup failed, stopping container: ${err}'
			logtype: .error
		) or {}
		// Use stop() method to properly clean up (kills process, cleans network, etc.)
		// Ignore errors from stop since we're already in an error path
		self.stop() or {
			self.factory.logger.log(
				cat:     'container'
				log:     'Failed to stop container during cleanup: ${err}'
				logtype: .error
			) or {}
		}
		return error('Failed to setup network for container: ${err}')
	}

	// Setup Mycelium IPv6 overlay network if enabled
	if self.factory.mycelium_enabled {
		container_pid := self.pid()!
		self.factory.mycelium_setup_container(self.name, container_pid) or {
			self.factory.logger.log(
				cat:     'container'
				log:     'Mycelium setup failed, stopping container: ${err}'
				logtype: .error
			) or {}
			// Stop container to clean up
			self.stop() or {
				self.factory.logger.log(
					cat:     'container'
					log:     'Failed to stop container during Mycelium cleanup: ${err}'
					logtype: .error
				) or {}
			}
			return error('Failed to setup Mycelium for container: ${err}')
		}
	}

	self.factory.logger.log(
		cat:     'container'
		log:     'Container ${self.name} started'
		logtype: .stdout
	) or {}
}

// Stop the container gracefully (SIGTERM) or forcefully (SIGKILL)
//
// This method:
// 1. Sends SIGTERM for graceful shutdown
// 2. Waits up to sigterm_timeout_ms for graceful stop
// 3. Sends SIGKILL if still running after timeout
// 4. Cleans up network resources (thread-safe)
//
// Thread Safety:
// Network cleanup is thread-safe via HeroPods.network_cleanup_container()
pub fn (mut self Container) stop() ! {
	status := self.status()!
	if status == .stopped {
		self.factory.logger.log(
			cat:     'container'
			log:     'Container ${self.name} is already stopped'
			logtype: .stdout
		) or {}
		return
	}

	crun_root := '${self.factory.base_dir}/runtime'

	// Send SIGTERM for graceful shutdown
	osal.exec(cmd: 'crun --root ${crun_root} kill ${self.name} SIGTERM', stdout: false) or {
		self.factory.logger.log(
			cat:     'container'
			log:     'Failed to send SIGTERM (container may already be stopped): ${err}'
			logtype: .stdout
		) or {}
	}

	// Wait up to sigterm_timeout_ms for graceful shutdown
	mut attempts := 0
	max_attempts := sigterm_timeout_ms / stop_check_interval_ms
	for attempts < max_attempts {
		time.sleep(stop_check_interval_ms * time.millisecond)
		current_status := self.status() or {
			// If we can't get status, assume it's stopped (container may have been deleted)
			ContainerStatus.stopped
		}
		if current_status == .stopped {
			self.factory.logger.log(
				cat:     'container'
				log:     'Container ${self.name} stopped gracefully'
				logtype: .stdout
			) or {}
			self.cleanup_network()! // Thread-safe network cleanup
			self.factory.logger.log(
				cat:     'container'
				log:     'Container ${self.name} stopped'
				logtype: .stdout
			) or {}
			return
		}
		attempts++
	}

	// Force kill if still running after timeout
	self.factory.logger.log(
		cat:     'container'
		log:     'Container ${self.name} did not stop gracefully, force killing'
		logtype: .stdout
	) or {}
	osal.exec(cmd: 'crun --root ${crun_root} kill ${self.name} SIGKILL', stdout: false) or {
		self.factory.logger.log(
			cat:     'container'
			log:     'Failed to send SIGKILL: ${err}'
			logtype: .error
		) or {}
	}

	// Wait for SIGKILL to take effect
	time.sleep(sigkill_wait_ms * time.millisecond)

	// Verify it's actually stopped
	final_status := self.status() or {
		// If we can't get status, assume it's stopped (container may have been deleted)
		ContainerStatus.stopped
	}
	if final_status != .stopped {
		return error('Failed to stop container ${self.name} - status: ${final_status}')
	}

	// Cleanup network resources (thread-safe)
	self.cleanup_network()!

	self.factory.logger.log(
		cat:     'container'
		log:     'Container ${self.name} stopped'
		logtype: .stdout
	) or {}
}

// Delete the container
//
// This method:
// 1. Checks if container exists in crun
// 2. Stops the container (which cleans up network)
// 3. Deletes the container from crun
// 4. Removes from factory's container cache
//
// Thread Safety:
// Network cleanup is thread-safe via stop() -> cleanup_network()
pub fn (mut self Container) delete() ! {
	// Check if container exists before trying to delete
	if !self.container_exists_in_crun()! {
		self.factory.logger.log(
			cat:     'container'
			log:     'Container ${self.name} does not exist in crun'
			logtype: .stdout
		) or {}
		// Still cleanup network resources in case they exist (thread-safe)
		self.cleanup_network() or {
			self.factory.logger.log(
				cat:     'container'
				log:     'Network cleanup failed (may not exist): ${err}'
				logtype: .stdout
			) or {}
		}
		// Remove from factory's container cache only after all cleanup is done
		if self.name in self.factory.containers {
			self.factory.containers.delete(self.name)
		}
		self.factory.logger.log(
			cat:     'container'
			log:     'Container ${self.name} removed from cache'
			logtype: .stdout
		) or {}
		return
	}

	// Stop the container (this will cleanup network via stop())
	self.stop()!

	// Delete the container from crun
	crun_root := '${self.factory.base_dir}/runtime'
	osal.exec(cmd: 'crun --root ${crun_root} delete ${self.name}', stdout: false) or {
		self.factory.logger.log(
			cat:     'container'
			log:     'Failed to delete container from crun: ${err}'
			logtype: .error
		) or {}
	}

	// Remove from factory's container cache only after all cleanup is complete
	if self.name in self.factory.containers {
		self.factory.containers.delete(self.name)
	}

	self.factory.logger.log(
		cat:     'container'
		log:     'Container ${self.name} deleted'
		logtype: .stdout
	) or {}
}

// Execute command inside the container
pub fn (mut self Container) exec(cmd_ osal.Command) !string {
	// Ensure container is running
	if self.status()! != .running {
		self.start()!
	}

	// Use the builder node to execute inside container
	mut node := self.node()!
	self.factory.logger.log(
		cat:     'container'
		log:     'Executing command in container ${self.name}: ${cmd_.cmd}'
		logtype: .stdout
	) or {}

	// Execute and provide better error context
	return node.exec(cmd: cmd_.cmd, stdout: cmd_.stdout) or {
		// Check if container still exists to provide better error message
		if !self.container_exists_in_crun()! {
			return error('Container ${self.name} was deleted during command execution')
		}
		return error('Command execution failed in container ${self.name}: ${err}')
	}
}

pub fn (self Container) status() !ContainerStatus {
	crun_root := '${self.factory.base_dir}/runtime'
	result := osal.exec(cmd: 'crun --root ${crun_root} state ${self.name}', stdout: false) or {
		// Container doesn't exist - this is expected in some cases (e.g., before creation)
		// Check error message to distinguish between "not found" and real errors
		err_msg := err.msg().to_lower()
		if err_msg.contains('does not exist') || err_msg.contains('not found')
			|| err_msg.contains('no such') {
			return .stopped
		}
		// Real error (permissions, crun not installed, etc.) - propagate it
		return error('Failed to get container status: ${err}')
	}

	// Parse JSON output from crun state
	state := json.decode(CrunState, result.output) or {
		return error('Failed to parse container state JSON: ${err}')
	}

	status_result := match state.status {
		'running' {
			ContainerStatus.running
		}
		'stopped' {
			ContainerStatus.stopped
		}
		'paused' {
			ContainerStatus.paused
		}
		else {
			// Unknown status - return unknown (can't log here as function is immutable)
			ContainerStatus.unknown
		}
	}
	return status_result
}

// Get the PID of the container's init process
pub fn (self Container) pid() !int {
	crun_root := '${self.factory.base_dir}/runtime'
	result := osal.exec(
		cmd:    'crun --root ${crun_root} state ${self.name}'
		stdout: false
	)!

	// Parse JSON output from crun state
	state := json.decode(CrunState, result.output)!

	if state.pid == 0 {
		return error('Container ${self.name} has no PID (not running?)')
	}

	return state.pid
}

// Setup network for this container (thread-safe)
//
// Delegates to HeroPods.network_setup_container() which uses network_mutex
// for thread-safe IP allocation and network configuration.
fn (mut self Container) setup_network() ! {
	// Get container PID
	container_pid := self.pid()!

	// Delegate to factory's network setup (thread-safe)
	mut factory := self.factory
	factory.network_setup_container(self.name, container_pid)!
}

// Cleanup network for this container (thread-safe)
//
// Delegates to HeroPods.network_cleanup_container() which uses network_mutex
// for thread-safe IP deallocation and network cleanup.
// Also cleans up Mycelium IPv6 overlay network if enabled.
fn (mut self Container) cleanup_network() ! {
	mut factory := self.factory
	factory.network_cleanup_container(self.name)!

	// Cleanup Mycelium IPv6 overlay network if enabled
	if factory.mycelium_enabled {
		factory.mycelium_cleanup_container(self.name) or {
			factory.logger.log(
				cat:     'container'
				log:     'Warning: Failed to cleanup Mycelium for container ${self.name}: ${err}'
				logtype: .error
			) or {}
		}
	}
}

// Check if container exists in crun (regardless of its state)
fn (self Container) container_exists_in_crun() !bool {
	// Try to get container state - if it fails, container doesn't exist
	crun_root := '${self.factory.base_dir}/runtime'
	result := osal.exec(cmd: 'crun --root ${crun_root} state ${self.name}', stdout: false) or {
		return false
	}

	// If we get here, the container exists (even if stopped/paused)
	return result.exit_code == 0
}

// ContainerStatus represents the current state of a container
pub enum ContainerStatus {
	running // Container is running
	stopped // Container is stopped or doesn't exist
	paused  // Container is paused
	unknown // Unknown status (error case)
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
		crun_root := '${self.factory.base_dir}/runtime'
		pane.send_keys('crun --root ${crun_root} exec ${self.name} ${args.cmd}')!
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
		crun_root:    '${self.factory.base_dir}/runtime'
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

// Get the crun configuration for this container
pub fn (self Container) config() !&crun.CrunConfig {
	return self.crun_config or { return error('Container ${self.name} has no crun configuration') }
}

// Container configuration customization methods
pub fn (mut self Container) set_memory_limit(limit_mb u64) !&Container {
	mut config := self.config()!
	config.set_memory_limit(limit_mb * 1024 * 1024) // Convert MB to bytes
	return &self
}

pub fn (mut self Container) set_cpu_limits(period u64, quota i64, shares u64) !&Container {
	mut config := self.config()!
	config.set_cpu_limits(period, quota, shares)
	return &self
}

pub fn (mut self Container) add_mount(source string, destination string, mount_type crun.MountType, options []crun.MountOption) !&Container {
	mut config := self.config()!
	config.add_mount(source, destination, mount_type, options)
	return &self
}

pub fn (mut self Container) add_capability(cap crun.Capability) !&Container {
	mut config := self.config()!
	config.add_capability(cap)
	return &self
}

pub fn (mut self Container) remove_capability(cap crun.Capability) !&Container {
	mut config := self.config()!
	config.remove_capability(cap)
	return &self
}

pub fn (mut self Container) add_env(key string, value string) !&Container {
	mut config := self.config()!
	config.add_env(key, value)
	return &self
}

pub fn (mut self Container) set_working_dir(dir string) !&Container {
	mut config := self.config()!
	config.set_working_dir(dir)
	return &self
}

// Save the current configuration to disk
pub fn (self Container) save_config() ! {
	config := self.config()!
	config_path := '${self.factory.base_dir}/configs/${self.name}/config.json'
	config.save_to_file(config_path)!
}
