module db

import x.json2
import json
import strconv

pub fn decode_int(data string) !int {
	// Try JSON decode first (for proper JSON numbers like "123")
	if result := json2.decode[int](data) {
		return result
	}
	// If that fails, try parsing as a string number (for quoted strings like "\"123\"")
	trimmed := data.trim_space().trim('"')
	parsed_int := strconv.parse_int(trimmed, 10, 32) or {
		return error('Failed to decode int: ${data}')
	}
	return int(parsed_int)
}

pub fn decode_u32(data string) !u32 {
	// Try JSON decode first (for proper JSON numbers like "123")
	if result := json2.decode[u32](data) {
		return result
	}
	// If that fails, try parsing as a string number (for quoted strings like "\"123\"")
	trimmed := data.trim_space().trim('"')
	parsed_uint := strconv.parse_uint(trimmed, 10, 32) or {
		return error('Failed to decode u32: ${data}')
	}
	return u32(parsed_uint)
}

pub fn u32_ourtime(t u32) ourtime.OurTime {
	return ourtime.OurTime{
		unixt: i64(t)
	}
}

pub fn ourtime_u32(t ourtime.OurTime) u32 {
	return u32(t.unixt) // Convert unix time to u32
}


pub fn decode_string(data string) !string {
	// Try JSON decode first (for proper JSON strings)
	// if result := json2.decode[string](data) {
	// 	return result
	// }
	// If that fails, return an error
	return data
}

pub fn decode_bool(data string) !bool {
	return json2.decode[bool](data) or { return error('Failed to decode bool: ${data}') }
}

pub fn decode_generic[T](data string) !T {
	mut r := json.decode(T, data) or { return error('Failed to decode T: ${data}\n${err}') }
	return r
}
