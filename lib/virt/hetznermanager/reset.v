module hetznermanager

import freeflowuniverse.herolib.core.texttools
import time
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.builder

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
}

pub fn (mut h HetznerManager) server_reset(args ServerRebootArgs) !ResetInfo {
	mut serverinfo := h.server_info_get(id: args.id, name: args.name)!

	console.print_header('server ${serverinfo.server_name} goes for reset')

	mut serveractive := false
	if osal.ping(address: serverinfo.server_ip)! == .ok {
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
	// now need to wait till it goes off
	if serveractive {
		for {
			console.print_debug('wait for server ${serverinfo.server_name} to go down.')
			pingresult := osal.ping(address: serverinfo.server_ip)!
			if pingresult != .ok {
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
			console.print_debug('wait for ${serverinfo.server_name}')
			if osal.ping(address: serverinfo.server_ip)! == .ok {
				console.print_debug('ping ok')
				osal.tcp_port_test(address: serverinfo.server_ip, port: 22, timeout: 3000)
				console.print_debug('ssh tcp port ok')
				console.print_header('server is rebooted: ${serverinfo.server_name}')
				break
			}
			x += 1
			if x > 60 * 5 {
				// 5 min
				return error('Could not reboot server ${serverinfo.server_name} in 5 min')
			}
		}
	}

	return o
}

// /////////////////////////////////////BOOT

// struct BootRoot {
// 	boot Boot
// }

// struct Boot {
// 	rescue RescueInfo
// }

// pub fn (mut h HetznerManager) server_boot(id int) !RescueInfo {
// 	mut conn := h.connection()!
// 	boot := conn.get_json[BootRoot](prefix: 'boot/${id}')!
// 	return boot.boot.rescue
// }
