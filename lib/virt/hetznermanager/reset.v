module hetznermanager

import incubaid.herolib.core.texttools
import time
import incubaid.herolib.ui.console
import incubaid.herolib.osal.core as osal
import incubaid.herolib.builder

// /////////////////////////////////////RESET

struct ResetInfo {
	server_ip        string
	server_ipv6_net  string
	server_number    int
	operating_status string
}

@[params]
pub struct ServerRebootArgs {
pub mut:
	id   int
	name string
	wait bool = true
	msg  string
}

pub fn (mut h HetznerManager) server_reset(args ServerRebootArgs) !ResetInfo {
	mut serverinfo := h.server_info_get(id: args.id, name: args.name)!

	console.print_header('server ${serverinfo.server_name} goes for reset')

	mut serveractive := false
	if osal.ping(address: serverinfo.server_ip)! {
		serveractive = true
		console.print_debug('server ${serverinfo.server_name} is active')
	} else {
		console.print_debug('server ${serverinfo.server_name} is down')
	}

	mut conn := h.connection()!
	o := conn.post_json_generic[ResetInfo](
		prefix:     'reset/${serverinfo.server_number}'
		params:     {
			'type': 'hw'
		}
		dataformat: .urlencoded
		// dict_key:'reset'
	)!
	console.print_debug('server ${serverinfo.server_name} reset done.')
	// now need to wait till it goes off
	if serveractive {
		for {
			console.print_debug('wait for server ${serverinfo.server_name} on ${serverinfo.server_ip} to go down.')
			pingresult := osal.ping(address: serverinfo.server_ip)!
			if !pingresult {
				console.print_debug('server ${serverinfo.server_name} is now down, now waitig for reboot.')
				break
			}
			time.sleep(1000 * time.millisecond)
		}
	}

	mut x := 0
	if args.wait {
		for {
			time.sleep(1000 * time.millisecond)
			console.print_debug('wait for ${serverinfo.server_name} on ${serverinfo.server_ip} ${args.msg}')
			if osal.ssh_test(address: serverinfo.server_ip)! == .ok {
				console.print_debug('ssh test ok')
				console.print_header('server is rebooted: ${serverinfo.server_name}')
				break
			}
			x += 1
			if x > 60 * 2 {
				// 2 min
				return error('Could not reboot server ${serverinfo.server_name} in 5 min')
			}
		}
	}

	return o
}
