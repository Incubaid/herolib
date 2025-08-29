module systemd

import freeflowuniverse.herolib.osal.core as osal

// Add more flexible journalctl options
@[params]
pub struct JournalArgs {
pub:
	service    string // name of service for which logs will be retrieved
	limit      int = 100 // number of last log lines to be shown
	since      string // time since when to show logs (e.g., "1 hour ago", "2024-01-01")
	follow     bool // follow logs in real-time
	priority   string // log priority (emerg, alert, crit, err, warning, notice, info, debug)
	grep       string // filter logs containing this text
}

pub fn journalctl(args JournalArgs) !string {
	mut cmd_parts := ['journalctl', '--no-pager']
	
	if args.limit > 0 {
		cmd_parts << ['-n', args.limit.str()]
	}
	
	if args.service != '' {
		cmd_parts << ['-u', name_fix(args.service)]
	}
	
	if args.since != '' {
		cmd_parts << ['--since', '"${args.since}"']
	}
	
	if args.follow {
		cmd_parts << ['-f']
	}
	
	if args.priority != '' {
		cmd_parts << ['-p', args.priority]
	}
	
	cmd := cmd_parts.join(' ')
	
	mut response := osal.execute_silent(cmd) or {
		return error('Failed to get journal logs for ${args.service}: ${err}')
	}
	
	if args.grep != '' {
		lines := response.split('\n')
		filtered_lines := lines.filter(it.contains(args.grep))
		response = filtered_lines.join('\n')
	}
	
	return response
}

// Add convenience methods
pub fn journalctl_errors(service string) !string {
	return journalctl(service: service, priority: 'err', limit: 50)
}

pub fn journalctl_recent(service string, since string) !string {
	return journalctl(service: service, since: since, limit: 200)
}
