module hetznermanager

import freeflowuniverse.herolib.core.texttools
import time
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.builder

/////////////////////////// LIST

pub struct ServerInfo {
pub mut:
	server_ip       string
	server_ipv6_net string
	server_number   int
	server_name     string
	product         string
	dc              string
	traffic         string
	status          string
	cancelled       bool
	paid_until      string
	ip              []string
	subnet          []Subnet
}

pub struct ServerInfoDetailed {
	ServerInfo
pub mut:
	reset    bool
	rescue   bool
	vnc      bool
	windows  bool
	plesk    bool
	cpanel   bool
	wol      bool
	hot_swap bool
	// linked_storagebox    int
}

pub struct Subnet {
pub mut:
	ip   string
	mask string
}

pub fn (mut h HetznerManager) servers_list() ![]ServerInfo {
	mut conn := h.connection()!
	return conn.get_json_list_generic[ServerInfo](
		method:        .get
		prefix:        'server'
		list_dict_key: 'server'
		debug:         false
	)!
}

// ///////////////////////////GETID

pub struct ServerGetArgs {
pub mut:
	id   int
	name string
}

pub fn (mut h HetznerManager) server_info_get(args_ ServerGetArgs) !ServerInfoDetailed {
	mut args := args_

	args.name = texttools.name_fix(args.name)

	l := h.servers_list()!

	mut res := []ServerInfo{}

	for item in l {
		// console.print_debug("Checking server: ${item.server_name} ${item.server_number} against args: '${args.name}:${args.id}'")
		if args.id > 0 && item.server_number != args.id {
			continue
		}
		server_name := texttools.name_fix(item.server_name)
		//if id specified then we always use that one
		if args.id == 0 && args.name.len > 0 && server_name != args.name {
			continue
		}
		res << item
	}

	if res.len > 1 {
		return error("Found too many servers with: '${args}'")
	}
	if res.len == 0 {
		return error("couldn't find server with: '${args}'")
	}

	mut conn := h.connection()!
	return conn.get_json_generic[ServerInfoDetailed](
		method:        .get
		prefix:        'server/${res[0].server_number}'
		dict_key:      'server'
		cache_disable: true
	)!
}
