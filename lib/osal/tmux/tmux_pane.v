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
	for _ in 0 .. 2000 {
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
// Supports both single-line and multi-line commands
pub fn (mut p Pane) send_command(command string) ! {
	// Check if command contains multiple lines
	if command.contains('\n') {
		// Multi-line command - create temporary script
		p.send_multiline_command(command)!
	} else {
		// Single-line command - send directly
		cmd := 'tmux send-keys -t ${p.window.session.name}:@${p.window.id}.%${p.id} "${command}" Enter'
		osal.execute_silent(cmd) or { return error('Cannot send command to pane %${p.id}: ${err}') }
	}
}

// Send command with declarative mode logic (intelligent state management)
// This method implements the full declarative logic:
// 1. Check if pane has previous command (Redis lookup)
// 2. If previous command exists:
//    a. Check if still running (process verification)
//    b. Compare MD5 hashes
//    c. If different command OR not running: proceed
//    d. If same command AND running: skip
// 3. If proceeding: kill existing processes, then start new command
pub fn (mut p Pane) send_command_declarative(command string) ! {
	console.print_debug('Declarative command for pane ${p.id}: ${command[..if command.len > 50 {
		50
	} else {
		command.len
	}]}...')

	// Step 1: Check if command has changed
	command_changed := p.has_command_changed(command)

	// Step 2: Check if stored command is still running
	stored_running := p.is_stored_command_running()

	// Step 3: Decide whether to proceed
	should_execute := command_changed || !stored_running

	if !should_execute {
		console.print_debug('Skipping command execution for pane ${p.id}: same command already running')
		return
	}

	// Step 4: If we have a running command that needs to be replaced, kill it
	if stored_running && command_changed {
		console.print_debug('Killing existing command in pane ${p.id} before starting new one')
		p.kill_running_command()!
		// Give processes time to die
		time.sleep(500 * time.millisecond)
	}

	// Step 5: Ensure bash is the parent process
	p.ensure_bash_parent()!

	// Step 6: Reset pane if it appears empty or needs cleanup
	p.reset_if_needed()!

	// Step 7: Execute the new command
	p.send_command(command)!

	// Step 8: Store the new command state
	// Get the PID of the command we just started (this is approximate)
	time.sleep(100 * time.millisecond) // Give command time to start
	p.store_command_state(command, 'running', p.pid)!

	console.print_debug('Successfully executed declarative command for pane ${p.id}')
}

// Kill the currently running command in this pane
pub fn (mut p Pane) kill_running_command() ! {
	stored_state := p.get_command_state() or { return }

	if stored_state.pid > 0 && osal.process_exists(stored_state.pid) {
		// Kill the process and its children
		osal.process_kill_recursive(pid: stored_state.pid)!
		console.print_debug('Killed running command (PID: ${stored_state.pid}) in pane ${p.id}')
	}

	// Also try to kill any processes that might be running in the pane
	p.kill_pane_process_group()!

	// Update the command state to reflect that it's no longer running
	p.update_command_status('killed')!
}

// Reset pane if it appears empty or needs cleanup
pub fn (mut p Pane) reset_if_needed() ! {
	if p.is_pane_empty()! {
		console.print_debug('Pane ${p.id} appears empty, sending reset')
		p.send_reset()!
		return
	}

	if !p.is_at_clean_prompt()! {
		console.print_debug('Pane ${p.id} not at clean prompt, sending reset')
		p.send_reset()!
	}
}

// Check if pane is completely empty
pub fn (mut p Pane) is_pane_empty() !bool {
	logs := p.logs_all() or { return true }
	lines := logs.split_into_lines()

	// Filter out empty lines
	mut non_empty_lines := []string{}
	for line in lines {
		if line.trim_space().len > 0 {
			non_empty_lines << line
		}
	}

	return non_empty_lines.len == 0
}

// Check if pane is at a clean shell prompt
pub fn (mut p Pane) is_at_clean_prompt() !bool {
	logs := p.logs_all() or { return false }
	lines := logs.split_into_lines()

	if lines.len == 0 {
		return false
	}

	// Check last few lines for shell prompt indicators
	check_lines := if lines.len > 5 { lines[lines.len - 5..] } else { lines }

	for line in check_lines.reverse() {
		line_clean := line.trim_space()
		if line_clean.len == 0 {
			continue
		}

		// Look for common shell prompt patterns
		if line_clean.ends_with('$ ') || line_clean.ends_with('# ') || line_clean.ends_with('> ')
			|| line_clean.ends_with('$') || line_clean.ends_with('#') || line_clean.ends_with('>') {
			console.print_debug('Found clean prompt in pane ${p.id}: "${line_clean}"')
			return true
		}

		// If we find a non-prompt line, we're not at a clean prompt
		break
	}

	return false
}

// Send reset command to pane
pub fn (mut p Pane) send_reset() ! {
	cmd := 'tmux send-keys -t ${p.window.session.name}:@${p.window.id}.%${p.id} "reset" Enter'
	osal.execute_silent(cmd) or { return error('Cannot send reset to pane %${p.id}: ${err}') }
	console.print_debug('Sent reset command to pane ${p.id}')

	// Give reset time to complete
	time.sleep(200 * time.millisecond)
}

// Verify that bash is the first process in this pane
pub fn (mut p Pane) verify_bash_parent() !bool {
	if p.pid <= 0 {
		return false
	}

	// Get process information for the pane's main process
	proc_info := osal.processinfo_get(p.pid) or { return false }

	// Check if the process command contains bash
	if proc_info.cmd.contains('bash') || proc_info.cmd.contains('/bin/bash')
		|| proc_info.cmd.contains('/usr/bin/bash') {
		console.print_debug('Pane ${p.id} has bash as parent process (PID: ${p.pid})')
		return true
	}

	console.print_debug('Pane ${p.id} does NOT have bash as parent process. Current: ${proc_info.cmd}')
	return false
}

// Ensure bash is the first process in the pane
pub fn (mut p Pane) ensure_bash_parent() ! {
	if p.verify_bash_parent()! {
		return
	}

	console.print_debug('Ensuring bash is parent process for pane ${p.id}')

	// Kill any existing processes in the pane
	p.kill_pane_process_group()!

	// Send a new bash command to establish bash as the parent
	cmd := 'tmux send-keys -t ${p.window.session.name}:@${p.window.id}.%${p.id} "exec bash" Enter'
	osal.execute_silent(cmd) or { return error('Cannot start bash in pane %${p.id}: ${err}') }

	// Give bash time to start
	time.sleep(500 * time.millisecond)

	// Update pane information
	p.window.scan()!

	// Verify bash is now running
	if !p.verify_bash_parent()! {
		return error('Failed to establish bash as parent process in pane ${p.id}')
	}

	console.print_debug('Successfully established bash as parent process for pane ${p.id}')
}

// Get all child processes of this pane's main process
pub fn (mut p Pane) get_child_processes() ![]osal.ProcessInfo {
	if p.pid <= 0 {
		return []osal.ProcessInfo{}
	}

	children_map := osal.processinfo_children(p.pid)!
	return children_map.processes
}

// Check if commands are running as children of bash
pub fn (mut p Pane) verify_command_hierarchy() !bool {
	// First verify bash is the parent
	if !p.verify_bash_parent()! {
		return false
	}

	// Get child processes
	children := p.get_child_processes()!

	if children.len == 0 {
		// No child processes, which is fine
		return true
	}

	// Check if child processes have bash as their parent
	for child in children {
		if child.ppid != p.pid {
			console.print_debug('Child process ${child.pid} (${child.cmd}) does not have pane process as parent')
			return false
		}
	}

	console.print_debug('Command hierarchy verified for pane ${p.id}: ${children.len} child processes')
	return true
}

// Handle multi-line commands by creating a temporary script
fn (mut p Pane) send_multiline_command(command string) ! {
	// Create temporary directory for tmux scripts
	script_dir := '/tmp/tmux/${p.window.session.name}'
	os.mkdir_all(script_dir) or { return error('Cannot create script directory: ${err}') }

	// Create unique script file for this pane
	script_path := '${script_dir}/pane_${p.id}_script.sh'

	// Prepare script content with proper shebang and commands
	script_content := '#!/bin/bash\n' + command.trim_space()

	// Write script to file
	os.write_file(script_path, script_content) or {
		return error('Cannot write script file ${script_path}: ${err}')
	}

	// Make script executable
	os.chmod(script_path, 0o755) or {
		return error('Cannot make script executable ${script_path}: ${err}')
	}

	// Execute the script in the pane
	cmd := 'tmux send-keys -t ${p.window.session.name}:@${p.window.id}.%${p.id} "${script_path}" Enter'
	osal.execute_silent(cmd) or { return error('Cannot execute script in pane %${p.id}: ${err}') }

	// Optional: Clean up script after a delay (commented out for debugging)
	// spawn {
	// 	time.sleep(5 * time.second)
	// 	os.rm(script_path) or {}
	// }
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
