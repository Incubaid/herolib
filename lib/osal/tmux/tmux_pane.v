module tmux

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.data.ourtime
import time
// import freeflowuniverse.herolib.session
import os
import freeflowuniverse.herolib.ui.console

// Constants for memory calculations
const kb_to_bytes_factor = 1024
const memory_display_precision = 3
const memory_cache_ttl_seconds = 300 // Cache system memory for 5 minutes

// Global cache for system memory to avoid repeated syscalls
struct MemoryCache {
mut:
	total_bytes u64
	cached_at   time.Time
}

__global (
	memory_cache MemoryCache
)

// Platform-specific memory detection
fn get_total_system_memory() !u64 {
	$if macos {
		result := osal.execute_silent('sysctl -n hw.memsize') or {
			return error('Failed to get system memory on macOS: ${err}')
		}
		return result.trim_space().u64()
	} $else $if linux {
		// Read from /proc/meminfo
		content := os.read_file('/proc/meminfo') or {
			return error('Failed to read /proc/meminfo on Linux: ${err}')
		}
		for line in content.split_into_lines() {
			if line.starts_with('MemTotal:') {
				parts := line.split_any(' \t').filter(it.len > 0)
				if parts.len >= 2 {
					kb_value := parts[1].u64()
					return kb_value * kb_to_bytes_factor
				}
			}
		}
		return error('Could not parse MemTotal from /proc/meminfo')
	} $else {
		return error('Unsupported platform for memory detection')
	}
}

// Get cached or fresh system memory
fn get_system_memory_cached() u64 {
	now := time.now()

	// Check if cache is valid
	if memory_cache.total_bytes > 0
		&& now.unix() - memory_cache.cached_at.unix() < memory_cache_ttl_seconds {
		return memory_cache.total_bytes
	}

	// Refresh cache
	total_memory := get_total_system_memory() or {
		console.print_debug('Failed to get system memory: ${err}')
		return 0
	}

	memory_cache.total_bytes = total_memory
	memory_cache.cached_at = now

	return total_memory
}

// Calculate accurate memory percentage
fn calculate_memory_percentage(memory_bytes u64, ps_fallback_percent f64) f64 {
	total_memory := get_system_memory_cached()

	if total_memory > 0 {
		return (f64(memory_bytes) / f64(total_memory)) * 100.0
	}

	// Fallback to ps value if system memory detection fails
	return ps_fallback_percent
}

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
}

pub fn (mut p Pane) stats() !ProcessStats {
	if p.pid == 0 {
		return ProcessStats{
			cpu_percent:    0.0
			memory_percent: 0.0
			memory_bytes:   0
		}
	}

	// Use ps command to get CPU and memory stats (cross-platform compatible)
	cmd := 'ps -p ${p.pid} -o %cpu,%mem,rss'
	result := osal.execute_silent(cmd) or {
		return error('Cannot get stats for PID ${p.pid}: ${err}')
	}

	lines := result.split_into_lines()
	if lines.len < 2 {
		return error('Process ${p.pid} not found')
	}

	// Skip header line, get data line
	data_line := lines[1].trim_space()
	if data_line == '' {
		return error('Process ${p.pid} not found')
	}

	parts := data_line.split_any(' \t').filter(it != '')
	if parts.len < 3 {
		return error('Invalid ps output: ${data_line}')
	}

	// Parse values from ps output
	cpu_percent := parts[0].f64()
	ps_memory_percent := parts[1].f64()
	memory_bytes := parts[2].u64() * kb_to_bytes_factor

	// Calculate accurate memory percentage using cached system memory
	memory_percent := calculate_memory_percentage(memory_bytes, ps_memory_percent)

	return ProcessStats{
		cpu_percent:    cpu_percent
		memory_percent: memory_percent
		memory_bytes:   memory_bytes
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

// Kill this specific pane
pub fn (mut p Pane) kill() ! {
	cmd := 'tmux kill-pane -t ${p.window.session.name}:@${p.window.id}.%${p.id}'
	osal.execute_silent(cmd) or { return error('Cannot kill pane %${p.id}: ${err}') }
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
