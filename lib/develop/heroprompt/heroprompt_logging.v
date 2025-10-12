module heroprompt

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.logger

// log writes a log message with the specified level
// Outputs to both console and log file (unless run_in_tests is true)
pub fn (mut hp HeroPrompt) log(level LogLevel, text string) {
	// Skip logging if running in tests
	if hp.run_in_tests {
		return
	}

	// Console output with appropriate colors
	match level {
		.error {
			console.print_stderr('ERROR: ${text}')
		}
		.warning {
			console.print_warn('WARNING: ${text}')
		}
		.info {
			console.print_info(text)
		}
		.debug {
			console.print_debug(text)
		}
	}

	// File logging - use the stored logger instance (no resource leak)
	level_str := match level {
		.error { 'ERROR' }
		.warning { 'WARNING' }
		.info { 'INFO' }
		.debug { 'DEBUG' }
	}

	logtype := match level {
		.error { logger.LogType.error }
		else { logger.LogType.stdout }
	}

	hp.logger.log(
		cat:     level_str
		log:     text
		logtype: logtype
	) or { console.print_stderr('Failed to write log: ${err}') }
}
