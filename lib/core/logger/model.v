module logger

import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.core.pathlib

@[heap]
pub struct Logger {
pub mut:
	path           pathlib.Path
	lastlog_time   i64  // to see in log format, every second we put a time down, we need to know if we are in a new second (logs can come in much faster)
	console_output bool // whether to also output to console/stdout
}

pub struct LogItem {
pub mut:
	timestamp ourtime.OurTime
	cat       string
	log       string
	logtype   LogType
}

pub enum LogType {
	stdout
	error
}
