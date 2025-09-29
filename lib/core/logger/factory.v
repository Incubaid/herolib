module logger

import freeflowuniverse.herolib.core.pathlib

// Logger Factory
pub struct LoggerFactoryArgs {
pub mut:
	path           string
	console_output bool = true
}

pub fn new(args LoggerFactoryArgs) !Logger {
	mut p := pathlib.get_dir(path: args.path, create: true)!
	return Logger{
		path:           p
		lastlog_time:   0
		console_output: args.console_output
	}
}
