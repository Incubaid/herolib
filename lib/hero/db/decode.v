module db

import x.json2
import json

pub fn decode_int(data string) !int {
	return json2.decode[int](data) or { return error('Failed to decode int: ${data}') }
}

pub fn decode_u32(data string) !u32 {
	return json2.decode[u32](data) or { return error('Failed to decode u32: ${data}') }
}

pub fn decode_bool(data string) !bool {
	return json2.decode[bool](data) or { return error('Failed to decode bool: ${data}') }
}

pub fn decode_generic[T](data string) !T {
	mut r := json.decode(T, data) or { 
		println('Failed to decode T: \n***\n${data}\n***\n${err}')
		println(T{})
		return error('Failed to decode T: ${data}\n${err}') 
	}
	return r
}
