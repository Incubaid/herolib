module main

import os
import io
import incubaid.herolib.core.logger
import incubaid.herolib.core.texttools

struct Args {
mut:
	logpath  string
	pane_id  string
	log      bool = true
	logreset bool
}

fn main() {
	args := parse_args() or {
		eprintln('Error: ${err}')
		print_usage()
		exit(1)
	}

	if !args.log {
		// If logging is disabled, just consume stdin and exit
		mut reader := io.new_buffered_reader(reader: os.stdin())
		for {
			reader.read_line() or { break }
		}
		return
	}

	// Determine the actual log directory path
	log_dir_path := determine_log_path(args) or {
		eprintln('Error determining log path: ${err}')
		exit(1)
	}

	// Handle log reset if requested
	if args.logreset {
		reset_logs(log_dir_path) or {
			eprintln('Error resetting logs: ${err}')
			exit(1)
		}
	}

	// Create logger - the logger factory expects a directory path
	mut l := logger.new(path: log_dir_path) or {
		eprintln('Failed to create logger: ${err}')
		exit(1)
	}

	// Read from stdin using a more direct approach that works with tmux pipe-pane
	// The issue is that tmux pipe-pane sends data differently than regular pipes

	mut buffer := []u8{len: 1024}
	mut line_buffer := ''

	for {
		// Read raw bytes from stdin - this is more compatible with tmux pipe-pane
		data, bytes_read := os.fd_read(0, buffer.len)

		if bytes_read == 0 {
			// No data available - for tmux pipe-pane this is normal, continue waiting
			continue
		}

		// Convert bytes to string and add to line buffer
		line_buffer += data

		// Process complete lines
		for line_buffer.contains('\n') {
			idx := line_buffer.index('\n') or { break }
			line := line_buffer[..idx].trim_space()
			line_buffer = line_buffer[idx + 1..]

			if line.len == 0 {
				continue
			}

			// Detect output type and set appropriate category
			category, logtype := categorize_output(line)

			// Log immediately - the logger handles its own file operations
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

	// Process any remaining data in the buffer
	if line_buffer.trim_space().len > 0 {
		line := line_buffer.trim_space()
		category, logtype := categorize_output(line)
		l.log(
			cat:     category
			log:     line
			logtype: logtype
		) or { eprintln('Failed to log final line: ${err}') }
	}
}

fn parse_args() !Args {
	if os.args.len < 2 {
		return error('Missing required argument: logpath')
	}

	mut args := Args{
		logpath: os.args[1]
	}

	// Parse optional pane_id (second positional argument)
	if os.args.len >= 3 {
		args.pane_id = os.args[2]
	}

	// Parse optional flags
	for i in 3 .. os.args.len {
		arg := os.args[i]
		if arg == '--no-log' || arg == '--log=false' {
			args.log = false
		} else if arg == '--logreset' || arg == '--logreset=true' {
			args.logreset = true
		} else if arg.starts_with('--log=') {
			val := arg.all_after('=').to_lower()
			args.log = val == 'true' || val == '1' || val == 'yes'
		} else if arg.starts_with('--logreset=') {
			val := arg.all_after('=').to_lower()
			args.logreset = val == 'true' || val == '1' || val == 'yes'
		}
	}

	return args
}

fn determine_log_path(args Args) !string {
	mut log_path := args.logpath

	// Check if logpath is a directory or file
	if os.exists(log_path) && os.is_dir(log_path) {
		// It's an existing directory
		if args.pane_id == '' {
			return error('When logpath is a directory, pane_id must be provided')
		}
		// Create a subdirectory for this pane
		pane_dir := os.join_path(log_path, args.pane_id)
		return pane_dir
	} else if log_path.contains('.') && !log_path.ends_with('/') {
		// It looks like a file path, use parent directory
		parent_dir := os.dir(log_path)
		return parent_dir
	} else {
		// It's a directory path (may not exist yet)
		if args.pane_id == '' {
			return log_path
		}
		// Create a subdirectory for this pane
		pane_dir := os.join_path(log_path, args.pane_id)
		return pane_dir
	}
}

fn reset_logs(logpath string) ! {
	if !os.exists(logpath) {
		return
	}

	if os.is_dir(logpath) {
		// Remove all .log files in the directory
		files := os.ls(logpath) or { return }
		for file in files {
			if file.ends_with('.log') {
				full_path := os.join_path(logpath, file)
				os.rm(full_path) or { eprintln('Warning: Failed to remove ${full_path}: ${err}') }
			}
		}
	} else {
		// Remove the specific log file
		os.rm(logpath) or { return error('Failed to remove log file ${logpath}: ${err}') }
	}
}

fn categorize_output(line string) (string, logger.LogType) {
	line_lower := line.to_lower().trim_space()

	// Error patterns - use .error logtype
	if line_lower.contains('error') || line_lower.contains('err:') || line_lower.contains('failed')
		|| line_lower.contains('exception') || line_lower.contains('panic')
		|| line_lower.starts_with('e ') || line_lower.contains('fatal')
		|| line_lower.contains('critical') {
		return texttools.expand('error', 10, ' '), logger.LogType.error
	}

	// Warning patterns - use .stdout logtype but warning category
	if line_lower.contains('warning') || line_lower.contains('warn:')
		|| line_lower.contains('deprecated') {
		return texttools.expand('warning', 10, ' '), logger.LogType.stdout
	}

	// Info/debug patterns - use .stdout logtype
	if line_lower.contains('info:') || line_lower.contains('debug:')
		|| line_lower.starts_with('info ') || line_lower.starts_with('debug ') {
		return texttools.expand('info', 10, ' '), logger.LogType.stdout
	}

	// Default to stdout category and logtype
	return texttools.expand('stdout', 10, ' '), logger.LogType.stdout
}

fn print_usage() {
	eprintln('Usage: tmux_logger <logpath> [pane_id] [options]')
	eprintln('')
	eprintln('Arguments:')
	eprintln('  logpath    Directory or file path where logs will be stored')
	eprintln('  pane_id    Optional pane identifier (required if logpath is a directory)')
	eprintln('')
	eprintln('Options:')
	eprintln('  --log=true|false     Enable/disable logging (default: true)')
	eprintln('  --no-log             Disable logging (same as --log=false)')
	eprintln('  --logreset=true|false Reset existing logs before starting (default: false)')
	eprintln('  --logreset           Reset existing logs (same as --logreset=true)')
	eprintln('')
	eprintln('Examples:')
	eprintln('  tmux_logger /tmp/logs pane1')
	eprintln('  tmux_logger /tmp/logs/session.log')
	eprintln('  tmux_logger /tmp/logs pane1 --logreset')
	eprintln('  tmux_logger /tmp/logs pane1 --no-log')
}
