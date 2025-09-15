module redisclient

import freeflowuniverse.herolib.data.resp
import freeflowuniverse.herolib.ui.console

// send list of strings, expect OK back
pub fn (mut r Redis) send_expect_ok(items []string) ! {
	r.mtx.lock()
	defer {
		r.mtx.unlock()
	}
	r.write_cmds(items)!
	res := r.get_string()!
	if res != 'OK' {
		console.print_debug("'${res}'")
		return error('did not get ok back')
	}
}

// send list of strings, expect int back
pub fn (mut r Redis) send_expect_int(items []string) !int {
	r.mtx.lock()
	defer {
		r.mtx.unlock()
	}
	r.write_cmds(items)!
	return r.get_int()
}

pub fn (mut r Redis) send_expect_bool(items []string) !bool {
	r.mtx.lock()
	defer {
		r.mtx.unlock()
	}
	r.write_cmds(items)!
	return r.get_bool()
}

// send list of strings, expect string back
pub fn (mut r Redis) send_expect_str(items []string) !string {
	r.mtx.lock()
	defer {
		r.mtx.unlock()
	}
	r.write_cmds(items)!
	return r.get_string()
}

// send list of strings, expect string or nil back
pub fn (mut r Redis) send_expect_strnil(items []string) !string {
	r.mtx.lock()
	defer {
		r.mtx.unlock()
	}
	r.write_cmds(items)!
	d := r.get_string_nil()!
	return d
}

// send list of strings, expect list of strings back
pub fn (mut r Redis) send_expect_list_str(items []string) ![]string {
	r.mtx.lock()
	defer {
		r.mtx.unlock()
	}
	r.write_cmds(items)!
	return r.get_list_str()
}

pub fn (mut r Redis) send_expect_list_int(items []string) ![]int {
	r.mtx.lock()
	defer {
		r.mtx.unlock()
	}
	r.write_cmds(items)!
	return r.get_list_int()
}

pub fn (mut r Redis) send_expect_list(items []string) ![]resp.RValue {
	r.mtx.lock()
	defer {
		r.mtx.unlock()
	}
	r.write_cmds(items)!
	res := r.get_response()!

	// Check if we got an error response
	if res is resp.RError {
		return error('Redis error: ${res.value}')
	}

	// Check if we got an array response
	if res !is resp.RArray {
		return error('Expected array response but got ${res.type_name()}. Response: ${resp.get_redis_value(res)}')
	}

	return resp.get_redis_array(res)
}
