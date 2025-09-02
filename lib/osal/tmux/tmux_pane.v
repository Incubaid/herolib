module tmux

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.ui.console
import time
import os

@[heap]
struct Pane {
pub mut:
	window             &Window @[str: skip]
	id                 int    // pane id (e.g., %1, %2)
	pid                int    // process id
	active             bool   // is this the active pane
	cmd                string // command running in pane
	env                map[string]string
	created_at         time.Time
	last_output_offset int // for tracking new logs
	// Logging fields
	log_enabled bool   // whether logging is enabled for this pane
	log_path    string // path where logs are stored
	logger_pid  int    // process id of the logger process
}

pub fn (mut p Pane) stats() !ProcessStats {
	if p.pid == 0 {
		return ProcessStats{
			cpu_percent:    0.0
			memory_percent: 0.0
			memory_bytes:   0
		}
	}

	// Use ps_tool to get process information
	process_info := osal.processinfo_get(p.pid) or {
		return error('Cannot get stats for PID ${p.pid}: ${err}')
	}

	return ProcessStats{
		cpu_percent:    f64(process_info.cpu_perc)
		memory_percent: f64(process_info.mem_perc)
		memory_bytes:   u64(process_info.rss * 1024) // rss is in KB, convert to bytes
	}
}

pub struct TMuxLogEntry {
pub mut:
	content   string
	timestamp time.Time
	offset    int
}

pub struct LogsGetArgs {
pub mut:
	reset bool
}

// get new logs since last call
pub fn (mut p Pane) logs_get_new(args LogsGetArgs) ![]TMuxLogEntry {
	if args.reset {
		p.last_output_offset = 0
	}
	// Capture pane content with line numbers
	cmd := 'tmux capture-pane -t ${p.window.session.name}:@${p.window.id}.%${p.id} -S ${p.last_output_offset} -p'
	result := osal.execute_silent(cmd) or { return error('Cannot capture pane output: ${err}') }

	lines := result.split_into_lines()
	mut entries := []TMuxLogEntry{}

	mut i := 0
	for line in lines {
		if line.trim_space() != '' {
			entries << TMuxLogEntry{
				content:   line
				timestamp: time.now()
				offset:    p.last_output_offset + i + 1
			}
		}
	}
	// Update offset to avoid duplicates next time
	if entries.len > 0 {
		p.last_output_offset = entries.last().offset
	}
	return entries
}

pub fn (mut p Pane) exit_status() !ProcessStatus {
	// Get the last few lines to see if there's an exit status
	logs := p.logs_all()!
	lines := logs.split_into_lines()

	// Look for shell prompt indicating command finished
	for line in lines.reverse() {
		line_clean := line.trim_space()
		if line_clean.contains('$') || line_clean.contains('#') || line_clean.contains('>') {
			// Found shell prompt, command likely finished
			// Could also check for specific exit codes in history
			return .finished_ok
		}
	}
	return .finished_error
}

pub fn (mut p Pane) logs_all() !string {
	cmd := 'tmux capture-pane -t ${p.window.session.name}:@${p.window.id}.%${p.id} -S -2000 -p'
	return osal.execute_silent(cmd) or { error('Cannot capture pane output: ${err}') }
}

// Fix the output_wait method to use correct method name
pub fn (mut p Pane) output_wait(c_ string, timeoutsec int) ! {
	mut t := ourtime.now()
	start := t.unix()
	c := c_.replace('\n', '')
	for i in 0 .. 2000 {
		entries := p.logs_get_new(reset: false)!
		for entry in entries {
			if entry.content.replace('\n', '').contains(c) {
				return
			}
		}
		mut t2 := ourtime.now()
		if t2.unix() > start + timeoutsec {
			return error('timeout on output wait for tmux.\n${p} .\nwaiting for:\n${c}')
		}
		time.sleep(100 * time.millisecond)
	}
}

// Get process information for this pane and all its children
pub fn (mut p Pane) processinfo() !osal.ProcessMap {
	if p.pid == 0 {
		return error('Pane has no associated process (pid is 0)')
	}

	return osal.processinfo_with_children(p.pid)!
}

// Get process information for just this pane's main process
pub fn (mut p Pane) processinfo_main() !osal.ProcessInfo {
	if p.pid == 0 {
		return error('Pane has no associated process (pid is 0)')
	}

	return osal.processinfo_get(p.pid)!
}

// Send a command to this pane
pub fn (mut p Pane) send_command(command string) ! {
	cmd := 'tmux send-keys -t ${p.window.session.name}:@${p.window.id}.%${p.id} "${command}" Enter'
	osal.execute_silent(cmd) or { return error('Cannot send command to pane %${p.id}: ${err}') }
}

// Send raw keys to this pane (without Enter)
pub fn (mut p Pane) send_keys(keys string) ! {
	cmd := 'tmux send-keys -t ${p.window.session.name}:@${p.window.id}.%${p.id} "${keys}"'
	osal.execute_silent(cmd) or { return error('Cannot send keys to pane %${p.id}: ${err}') }
}

// Kill this specific pane with comprehensive process cleanup
pub fn (mut p Pane) kill() ! {
	// First, disable logging if enabled
	if p.log_enabled {
		p.logging_disable() or {
			console.print_debug('Warning: Failed to disable logging for pane %${p.id}: ${err}')
		}
	}

	// Then, kill all processes running in this pane
	p.kill_processes()!

	// Finally, kill the tmux pane itself
	cmd := 'tmux kill-pane -t ${p.window.session.name}:@${p.window.id}.%${p.id}'
	osal.execute_silent(cmd) or { return error('Cannot kill pane %${p.id}: ${err}') }
}

// Kill all processes associated with this pane (main process and all children)
pub fn (mut p Pane) kill_processes() ! {
	if p.pid == 0 {
		console.print_debug('Pane %${p.id} has no associated process (pid is 0)')
		return
	}

	console.print_debug('Killing all processes for pane %${p.id} (main PID: ${p.pid})')

	// Use the recursive process killer to terminate the main process and all its children
	osal.process_kill_recursive(pid: p.pid) or {
		console.print_debug('Failed to kill processes for pane %${p.id}: ${err}')
		// Continue anyway - the process might already be dead
	}

	// Also try to kill any processes that might be running in the pane's process group
	// This handles cases where processes might have detached from the main process tree
	p.kill_pane_process_group()!
}

// Kill processes in the pane's process group (fallback cleanup)
fn (mut p Pane) kill_pane_process_group() ! {
	// Get all processes and find ones that might be related to this pane
	_ := osal.processmap_get() or {
		console.print_debug('Could not get process map for pane cleanup')
		return
	}

	// Look for processes that might be children of the pane's shell
	// or processes running commands that were sent to this pane
	mut pane_processes := []int{}

	// First, collect the main process and its direct children
	if p.pid > 0 && osal.process_exists(p.pid) {
		children_map := osal.processinfo_children(p.pid) or {
			console.print_debug('Could not get children for PID ${p.pid}')
			return
		}

		for child in children_map.processes {
			pane_processes << child.pid
		}
	}

	// Kill any remaining processes with SIGTERM first, then SIGKILL
	for pid in pane_processes {
		if osal.process_exists(pid) {
			// Try SIGTERM first (graceful shutdown)
			osal.execute_silent('kill -TERM ${pid}') or {
				console.print_debug('Could not send SIGTERM to PID ${pid}')
			}
		}
	}

	// Wait a moment for graceful shutdown
	time.sleep(500 * time.millisecond)

	// Force kill any remaining processes with SIGKILL
	for pid in pane_processes {
		if osal.process_exists(pid) {
			osal.execute_silent('kill -KILL ${pid}') or {
				console.print_debug('Could not send SIGKILL to PID ${pid}')
			}
		}
	}
}

// Select/activate this pane
pub fn (mut p Pane) select() ! {
	cmd := 'tmux select-pane -t ${p.window.session.name}:@${p.window.id}.%${p.id}'
	osal.execute_silent(cmd) or { return error('Cannot select pane %${p.id}: ${err}') }
	p.active = true
}

@[params]
pub struct PaneResizeArgs {
pub mut:
	direction string = 'right' // 'up', 'down', 'left', 'right'
	cells     int    = 5       // number of cells to resize by
}

// Resize this pane
pub fn (mut p Pane) resize(args PaneResizeArgs) ! {
	direction_flag := match args.direction.to_lower() {
		'up', 'u' { '-U' }
		'down', 'd' { '-D' }
		'left', 'l' { '-L' }
		'right', 'r' { '-R' }
		else { return error('Invalid resize direction: ${args.direction}. Use up, down, left, or right') }
	}

	cmd := 'tmux resize-pane -t ${p.window.session.name}:@${p.window.id}.%${p.id} ${direction_flag} ${args.cells}'
	osal.execute_silent(cmd) or { return error('Cannot resize pane %${p.id}: ${err}') }
}

// Convenience methods for resizing
pub fn (mut p Pane) resize_up(cells int) ! {
	p.resize(direction: 'up', cells: cells)!
}

pub fn (mut p Pane) resize_down(cells int) ! {
	p.resize(direction: 'down', cells: cells)!
}

pub fn (mut p Pane) resize_left(cells int) ! {
	p.resize(direction: 'left', cells: cells)!
}

pub fn (mut p Pane) resize_right(cells int) ! {
	p.resize(direction: 'right', cells: cells)!
}

// Get current pane width
pub fn (p Pane) get_width() !int {
	cmd := 'tmux display-message -t ${p.window.session.name}:@${p.window.id}.%${p.id} -p "#{pane_width}"'
	res := osal.exec(cmd: cmd, stdout: false, name: 'tmux_get_pane_width') or {
		return error("Can't get pane width: ${err}")
	}
	return res.output.trim_space().int()
}

// Get current pane height
pub fn (p Pane) get_height() !int {
	cmd := 'tmux display-message -t ${p.window.session.name}:@${p.window.id}.%${p.id} -p "#{pane_height}"'
	res := osal.exec(cmd: cmd, stdout: false, name: 'tmux_get_pane_height') or {
		return error("Can't get pane height: ${err}")
	}
	return res.output.trim_space().int()
}

@[params]
pub struct PaneLoggingEnableArgs {
pub mut:
	logpath  string // custom log path, if empty uses default
	logreset bool   // whether to reset/clear existing logs
}

// Enable logging for this pane
pub fn (mut p Pane) logging_enable(args PaneLoggingEnableArgs) ! {
	if p.log_enabled {
		return error('Logging is already enabled for pane %${p.id}')
	}

	// Determine log path
	mut log_path := args.logpath
	if log_path == '' {
		// Default path: /tmp/tmux_logs/session/window/pane_id
		log_path = '/tmp/tmux_logs/${p.window.session.name}/${p.window.name}/pane_${p.id}'
	}

	// Create log directory if it doesn't exist
	osal.exec(cmd: 'mkdir -p "${log_path}"', stdout: false, name: 'tmux_create_log_dir') or {
		return error("Can't create log directory ${log_path}: ${err}")
	}

	// Reset logs if requested
	if args.logreset {
		osal.exec(
			cmd:          'rm -f "${log_path}"/*.log'
			stdout:       false
			name:         'tmux_reset_logs'
			ignore_error: true
		) or {}
	}

	// Get the path to tmux_logger binary - use a more reliable path resolution
	// Find the herolib root by looking for the lib directory
	mut herolib_root := os.getwd()
	for {
		if os.exists('${herolib_root}/lib/osal/tmux/bin/tmux_logger.v') {
			break
		}
		parent := os.dir(herolib_root)
		if parent == herolib_root {
			return error('Could not find herolib root directory')
		}
		herolib_root = parent
	}

	logger_binary := '${herolib_root}/lib/osal/tmux/bin/tmux_logger'
	logger_source := '${herolib_root}/lib/osal/tmux/bin/tmux_logger.v'

	// Check if binary exists, if not try to compile it
	if !os.exists(logger_binary) {
		console.print_debug('Compiling tmux_logger binary...')
		console.print_debug('Source: ${logger_source}')
		console.print_debug('Binary: ${logger_binary}')
		compile_cmd := 'v -enable-globals -o "${logger_binary}" "${logger_source}"'
		osal.exec(cmd: compile_cmd, stdout: false, name: 'tmux_compile_logger') or {
			return error("Can't compile tmux_logger: ${err}")
		}
	}

	// Use the simple and reliable tmux pipe-pane approach with tmux_logger binary
	// This is the proven approach that works perfectly

	// Determine the pane identifier for logging
	pane_log_id := 'pane${p.id}'

	// Set up tmux pipe-pane to send all output directly to tmux_logger
	pipe_cmd := 'tmux pipe-pane -t ${p.window.session.name}:@${p.window.id}.%${p.id} -o "${logger_binary} ${log_path} ${pane_log_id}"'

	console.print_debug('Starting real-time logging: ${pipe_cmd}')

	osal.exec(cmd: pipe_cmd, stdout: false, name: 'tmux_start_pipe_logging') or {
		return error("Can't start pipe logging for pane %${p.id}: ${err}")
	}

	// Wait a moment for the process to start
	time.sleep(500 * time.millisecond)

	// Update pane state
	p.log_enabled = true
	p.log_path = log_path
	// Note: tmux pipe-pane doesn't return a PID, we'll track it differently if needed

	console.print_debug('Logging enabled for pane %${p.id} -> ${log_path}')
}

// Disable logging for this pane
pub fn (mut p Pane) logging_disable() ! {
	if !p.log_enabled {
		return error('Logging is not enabled for pane %${p.id}')
	}

	// Stop pipe-pane (in case it's running)
	cmd := 'tmux pipe-pane -t ${p.window.session.name}:@${p.window.id}.%${p.id}'
	osal.exec(cmd: cmd, stdout: false, name: 'tmux_stop_logging', ignore_error: true) or {}

	// Kill the tmux_logger process for this pane
	pane_log_id := 'pane${p.id}'
	kill_cmd := 'pkill -f "tmux_logger.*${pane_log_id}"'
	osal.exec(cmd: kill_cmd, stdout: false, name: 'kill_tmux_logger', ignore_error: true) or {}

	// No temp files to clean up with the simple pipe approach

	// Update pane state
	p.log_enabled = false
	p.log_path = ''
	p.logger_pid = 0

	console.print_debug('Logging disabled for pane %${p.id}')
}

// Get logging status for this pane
pub fn (p Pane) logging_status() string {
	if p.log_enabled {
		return 'enabled (${p.log_path})'
	}
	return 'disabled'
}
