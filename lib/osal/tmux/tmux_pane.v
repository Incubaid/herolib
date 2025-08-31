module tmux

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.data.ourtime
import time

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
