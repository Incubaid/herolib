module hetznermanager

import freeflowuniverse.herolib.core.texttools
import time
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.builder

// ///////////////////////////RESCUE

pub struct RescueInfo {
pub mut:
	server_ip       string
	server_ipv6_net string
	server_number   int
	os              string
	arch            int
	active          bool
	password        string
	authorized_key  []string
	host_key        []string
}

pub struct ServerRescueArgs {
pub mut:
	id           int
	name         string
	wait         bool = true
	hero_install bool
	sshkey_name  string
	reset        bool // ask to do reset/rescue even if its already in that state
}

// put server in rescue mode, if sshkey_name not specified then will use the first one in the list
pub fn (mut h HetznerManager) server_rescue(args ServerRescueArgs) !ServerInfoDetailed {
	mut serverinfo := h.server_info_get(id: args.id, name: args.name)!

	console.print_header('server ${serverinfo.server_name} goes into rescue mode')

	// only do it if its not in rescue yet
	if serverinfo.rescue == false || args.reset {
		mut key := h.keys_get()![0]
		if args.sshkey_name == '' {
			key = h.key_get(args.sshkey_name)!
		}

		mut conn := h.connection()!
		rescue := conn.post_json_generic[RescueInfo](
			prefix:     'boot/${serverinfo.server_number}/rescue'
			params:     {
				'os':             'linux'
				'authorized_key': key.fingerprint
			}
			dict_key:   'rescue'
			dataformat: .urlencoded
		)!

		console.print_debug('hetzner rescue\n${rescue}')

		h.server_reset(id: args.id, name: args.name, wait: args.wait)!
	}

	if args.wait {
		// now we should check if ssh is responding
		// next will do that check
		mut b := builder.new()!
		mut n := b.node_new(ipaddr: serverinfo.server_ip)!
		println(n)
		$dbg;
		// builder.executor_new(ipaddr: serverinfo.server_ip, checkconnect: 60)!
	}

	if args.hero_install {
		mut b := builder.new()!
		mut n := b.node_new(ipaddr: serverinfo.server_ip)!
		n.hero_install()!
	}

	if args.hero_install {
		mut b := builder.new()!
		mut n := b.node_new(ipaddr: serverinfo.server_ip)!
		n.hero_install()!
	}

	mut serverinfo2 := h.server_info_get(id: args.id, name: args.name)!

	return serverinfo2
}

pub fn (mut h HetznerManager) server_rescue_node(args ServerRescueArgs) !&builder.Node {
	mut serverinfo := h.server_rescue(args)!

	mut b := builder.new()!
	mut n := b.node_new(ipaddr: serverinfo.server_ip)!

	return n
}
