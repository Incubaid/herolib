module redisclient

import freeflowuniverse.herolib.data.resp

pub fn (mut r Redis) cmd_str(script string, args []string) !string {
	mut cmds := []string{}
	cmds << script
	cmds << args
	return r.send_expect_strnil(cmds)!
}

pub fn (mut r Redis) cmd_list_str(script string, args []string) ![]string {
	mut cmds := []string{}
	cmds << script
	cmds << args
	response := r.send_expect_list(cmds)!
	mut result := []string{}
	for item in response {
		result << resp.get_redis_value(item)
	}
	return result
}

pub fn (mut r Redis) cmd_int(script string, args []string) !int {
	mut cmds := []string{}
	cmds << script
	cmds << args
	return r.send_expect_int(cmds)!
}
