module logger

import os
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.data.ourtime

@[params]
pub struct LogItemArgs {
pub mut:
	timestamp ?ourtime.OurTime
	cat       string
	log       string
	logtype   LogType
}

pub fn (mut l Logger) log(args_ LogItemArgs) ! {
	mut args := args_

	t := args.timestamp or {
		t2 := ourtime.now()
		t2
	}

	// Format category (max 10 chars, ascii only)
	args.cat = texttools.name_fix(args.cat)
	if args.cat.len > 10 {
		return error('category cannot be longer than 10 chars')
	}
	args.cat = texttools.expand(args.cat, 10, ' ')

	args.log = texttools.dedent(args.log).trim_space()

	mut logfile_path := '${l.path.path}/${t.dayhour()}.log'

	// Create log file if it doesn't exist
	if !os.exists(logfile_path) {
		os.write_file(logfile_path, '')!
		l.lastlog_time = 0 // make sure we put time again
	}

	mut f := os.open_append(logfile_path)!

	mut content := ''

	// Add timestamp if we're in a new second
	if t.unix() > l.lastlog_time {
		content += '\n${t.time().format_ss()}\n'
		l.lastlog_time = t.unix()
	}

	// Format log lines
	error_prefix := if args.logtype == .error { 'E' } else { ' ' }
	lines := args.log.split('\n')

	for i, line in lines {
		if i == 0 {
			content += '${error_prefix} ${args.cat} - ${line}\n'
		} else {
			content += '${error_prefix}              ${line}\n'
		}
	}
	f.writeln(content.trim_space_right())!
	f.close()

	// Also write to console if enabled
	if l.console_output {
		l.write_to_console(args, t)!
	}
}

// Write log message to console with clean formatting
fn (mut l Logger) write_to_console(args LogItemArgs, t ourtime.OurTime) ! {
	timestamp := t.time().format_ss()
	error_indicator := if args.logtype == .error { 'ERROR' } else { 'INFO' }
	category := args.cat.trim_space()
	lines := args.log.split('\n')

	for i, line in lines {
		if i == 0 {
			println('${timestamp} [${error_indicator}] [${category}] ${line}')
		} else {
			// Indent continuation lines
			println('${timestamp} [${error_indicator}] [${category}]   ${line}')
		}
	}
}
