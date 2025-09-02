module main

import os
import io
import freeflowuniverse.herolib.core.logger

fn main() {
	if os.args.len < 2 {
		eprintln('Usage: tmux_logger <log_path> [pane_id]')
		exit(1)
	}

	log_path := os.args[1]

	mut l := logger.new(path: log_path) or {
		eprintln('Failed to create logger: ${err}')
		exit(1)
	}

	// Read from stdin line by line and log with categorization
	mut reader := io.new_buffered_reader(reader: os.stdin())
	for {
		line := reader.read_line() or { break }
		if line.len == 0 {
			continue
		}

		// Detect output type and set appropriate category
		category, logtype := categorize_output(line)

		l.log(
			cat:     category
			log:     line
			logtype: logtype
		) or {
			eprintln('Failed to log line: ${err}')
			continue
		}
	}
}

fn categorize_output(line string) (string, logger.LogType) {
	line_lower := line.to_lower().trim_space()

	// Error patterns - use .error logtype
	if line_lower.contains('error') || line_lower.contains('err:') || line_lower.contains('failed')
		|| line_lower.contains('exception') || line_lower.contains('panic')
		|| line_lower.starts_with('e ') || line_lower.contains('fatal')
		|| line_lower.contains('critical') {
		return 'error', logger.LogType.error
	}

	// Warning patterns - use .stdout logtype but warning category
	if line_lower.contains('warning') || line_lower.contains('warn:')
		|| line_lower.contains('deprecated') {
		return 'warning', logger.LogType.stdout
	}

	// Info/debug patterns - use .stdout logtype
	if line_lower.contains('info:') || line_lower.contains('debug:')
		|| line_lower.starts_with('info ') || line_lower.starts_with('debug ') {
		return 'info', logger.LogType.stdout
	}

	// Default to stdout category and logtype
	return 'stdout', logger.LogType.stdout
}
