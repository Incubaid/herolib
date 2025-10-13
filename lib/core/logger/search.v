module logger

import os
import incubaid.herolib.core.texttools
import incubaid.herolib.data.ourtime

@[params]
pub struct SearchArgs {
pub mut:
	timestamp_from ?ourtime.OurTime
	timestamp_to   ?ourtime.OurTime
	cat            string // can be empty
	log            string // any content in here will be looked for
	logtype        LogType
	maxitems       int = 10000
}

pub fn (mut l Logger) search(args_ SearchArgs) ![]LogItem {
	mut args := args_

	// Format category (max 10 chars, ascii only)
	args.cat = texttools.name_fix(args.cat)
	if args.cat.len > 10 {
		return error('category cannot be longer than 10 chars')
	}

	mut timestamp_from := args.timestamp_from or { ourtime.OurTime{} }
	mut timestamp_to := args.timestamp_to or { ourtime.OurTime{} }

	// Get time range
	from_time := timestamp_from.unix()
	to_time := timestamp_to.unix()
	if from_time > to_time {
		return error('from_time cannot be after to_time: ${from_time} <  ${to_time}')
	}

	mut result := []LogItem{}

	// Find log files in time range
	mut files := os.ls(l.path.path)!
	files.sort()

	for file in files {
		if !file.ends_with('.log') {
			continue
		}

		// Parse dayhour from filename
		dayhour := file[..file.len - 4] // remove .log
		file_time := ourtime.new(dayhour)!
		mut current_time := ourtime.OurTime{}
		mut current_item := LogItem{}
		mut collecting := false

		// Skip if file is outside time range
		if file_time.unix() < from_time || file_time.unix() > to_time {
			continue
		}

		// Read and parse log file
		content := os.read_file('${l.path.path}/${file}')!
		lines := content.split('\n')

		for line in lines {
			if result.len >= args.maxitems {
				return result
			}

			line_trim := line.trim_space()
			if line_trim == '' {
				continue
			}

			// Check if this is a timestamp line
			if !(line.starts_with(' ') || line.starts_with('E')) {
				current_time = ourtime.new(line_trim)!
				if collecting {
					process(mut result, current_item, current_time, args, from_time, to_time)!
				}
				collecting = false
				continue
			}

			if collecting && line.len > 14 && line[13] == `-` {
				process(mut result, current_item, current_time, args, from_time, to_time)!
				collecting = false
			}

			// Parse log line
			is_error := line.starts_with('E')
			if !collecting {
				// Start new item
				current_item = LogItem{
					timestamp: current_time
					cat:       line[2..12].trim_space()
					log:       line[15..].trim_space()
					logtype:   if is_error { .error } else { .stdout }
				}
				// println('new current item: ${current_item}')
				collecting = true
			} else {
				// Continuation line
				if line_trim.len < 16 {
					current_item.log += '\n'
				} else {
					current_item.log += '\n' + line[15..]
				}
			}
		}

		// Add last item if collecting
		if collecting {
			process(mut result, current_item, current_time, args, from_time, to_time)!
		}
	}

	return result
}

fn process(mut result []LogItem, current_item LogItem, current_time ourtime.OurTime, args SearchArgs, from_time i64, to_time i64) ! {
	// Add previous item if it matches filters
	log_epoch := current_item.timestamp.unix()
	if log_epoch < from_time || log_epoch > to_time {
		return
	}
	if (args.cat == '' || current_item.cat.trim_space() == args.cat)
		&& (args.log == '' || current_item.log.contains(args.log))
		&& args.logtype == current_item.logtype {
		result << current_item
	}
}
