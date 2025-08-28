module hetznermanager



pub fn (mut h HetznerManager) check_whitelist(args_ ServerRescueArgs)! {
	
	if h.whitelist.len == 0 {
		return
	}

	mut serverinfo := h.server_info_get(id: args_.id, name: args_.name)!

	if ! h.whitelist.contains(serverinfo.server_number) {
		return error('Server ${serverinfo}\nis not whitelisted')
	}

}
