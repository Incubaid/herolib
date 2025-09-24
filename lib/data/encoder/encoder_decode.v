module encoder

import encoding.binary as bin
import freeflowuniverse.herolib.data.ourtime
import time
import freeflowuniverse.herolib.data.gid
import freeflowuniverse.herolib.data.currency

pub struct Decoder {
pub mut:
	version u8 = 1 // is important
	data    []u8
}

pub fn decoder_new(data []u8) Decoder {
	mut e := Decoder{}
	e.data = data
	return e
}

pub fn (mut d Decoder) get_string() !string {
	n := d.get_u16()!
	// THIS IS ALWAYS TRUE BECAUSE u16 is max 64KB
	// if n > 64 * 1024 { // 64KB limit
	// 	return error('string length ${n} exceeds 64KB limit')
	// }
	if n > d.data.len {
		return error('string length ${n} exceeds remaining data length ${d.data.len}')
	}
	mut bytes := []u8{len: int(n)}
	for i in 0 .. n {
		bytes[i] = d.data[i]
	}
	d.data.delete_many(0, n)
	return bytes.bytestr()
}

pub fn (mut d Decoder) get_int() !int {
	return int(d.get_u32()!)
}

pub fn (mut d Decoder) get_bytes() ![]u8 {
	n := int(d.get_u32()!)
	if n > 64 * 1024 { // 64KB limit
		return error('bytes length ${n} exceeds 64KB limit')
	}
	if n > d.data.len {
		return error('bytes length ${n} exceeds remaining data length ${d.data.len}')
	}
	mut bytes := []u8{len: int(n)}
	for i in 0 .. n {
		bytes[i] = d.data[i]
	}
	d.data.delete_many(0, n)
	return bytes
}

pub fn (mut d Decoder) get_bool() !bool {
	val := d.get_u8()!
	return val == 1
}

// adds u16 length of string in bytes + the bytes
pub fn (mut d Decoder) get_u8() !u8 {
	if d.data.len < 1 {
		return error('not enough data for u8')
	}
	v := d.data.first()
	d.data.delete(0)
	return v
}

pub fn (mut d Decoder) get_u16() !u16 {
	if d.data.len < 2 {
		return error('not enough data for u16')
	}
	mut bytes := []u8{len: 2}
	bytes[0] = d.data[0]
	bytes[1] = d.data[1]
	d.data.delete_many(0, 2)
	return bin.little_endian_u16(bytes)
}

pub fn (mut d Decoder) get_u32() !u32 {
	if d.data.len < 4 {
		return error('not enough data for u32')
	}
	mut bytes := []u8{len: 4}
	bytes[0] = d.data[0]
	bytes[1] = d.data[1]
	bytes[2] = d.data[2]
	bytes[3] = d.data[3]
	d.data.delete_many(0, 4)
	return bin.little_endian_u32(bytes)
}

pub fn (mut d Decoder) get_u64() !u64 {
	if d.data.len < 8 {
		return error('not enough data for u64')
	}
	mut bytes := []u8{len: 8}
	bytes[0] = d.data[0]
	bytes[1] = d.data[1]
	bytes[2] = d.data[2]
	bytes[3] = d.data[3]
	bytes[4] = d.data[4]
	bytes[5] = d.data[5]
	bytes[6] = d.data[6]
	bytes[7] = d.data[7]
	d.data.delete_many(0, 8)
	return bin.little_endian_u64(bytes)
}

pub fn (mut d Decoder) get_i64() !i64 {
	if d.data.len < 8 {
		return error('not enough data for i64')
	}
	mut bytes := []u8{len: 8}
	bytes[0] = d.data[0]
	bytes[1] = d.data[1]
	bytes[2] = d.data[2]
	bytes[3] = d.data[3]
	bytes[4] = d.data[4]
	bytes[5] = d.data[5]
	bytes[6] = d.data[6]
	bytes[7] = d.data[7]
	d.data.delete_many(0, 8)
	return u64(bin.little_endian_u64(bytes))
}

pub fn (mut d Decoder) get_f64() !f64 {
	// Get the u64 bits first and then convert back to f64
	bits := d.get_u64()!
	// Use unsafe to convert bits to f64
	f := unsafe { *(&f64(&bits)) }
	return f
}

pub fn (mut d Decoder) get_time() !time.Time {
	secs_ := d.get_u32()!
	secs := i64(secs_)
	return time.unix(secs)
}

pub fn (mut d Decoder) get_ourtime() !ourtime.OurTime {
	return ourtime.OurTime{
		unixt: d.get_u32()!
	}
}

pub fn (mut d Decoder) get_currency() !currency.Amount {
	curstring := d.get_string()!
	if curstring.len == 0 {
		return error('currency string is empty')
	}
	currencyo := currency.get(curstring)!
	return currency.Amount{
		currency: currencyo
		val:      d.get_f64()!
	}
}

pub fn (mut d Decoder) get_percentage() !u8 {
	val := d.get_u8()!
	if val > 100 {
		return error('percentage value ${val} exceeds 100')
	}
	return val
}

pub fn (mut d Decoder) get_list_string() ![]string {
	n := d.get_u16()!
	mut v := []string{len: int(n)}
	for i in 0 .. n {
		v[i] = d.get_string()!
	}
	return v
}

pub fn (mut d Decoder) get_list_int() ![]int {
	n := d.get_u16()!
	mut v := []int{len: int(n)}
	for i in 0 .. n {
		v[i] = d.get_int()!
	}
	return v
}

pub fn (mut d Decoder) get_list_u8() ![]u8 {
	n := d.get_u16()!
	if n > 64 * 1024 { // 64KB limit
		return error('list length ${n} exceeds 64KB limit')
	}
	if n > d.data.len {
		return error('list length ${n} exceeds remaining data length ${d.data.len}')
	}
	mut bytes := []u8{len: int(n)}
	for i in 0 .. n {
		bytes[i] = d.data[i]
	}
	d.data.delete_many(0, n)
	return bytes
}

pub fn (mut d Decoder) get_list_u16() ![]u16 {
	n := d.get_u16()!
	mut v := []u16{len: int(n)}
	for i in 0 .. n {
		v[i] = d.get_u16()!
	}
	return v
}

pub fn (mut d Decoder) get_list_u32() ![]u32 {
	n := d.get_u16()!
	mut v := []u32{len: int(n)}
	for i in 0 .. n {
		v[i] = d.get_u32()!
	}
	return v
}

pub fn (mut d Decoder) get_list_u64() ![]u64 {
	n := d.get_u16()!
	mut v := []u64{len: int(n)}
	for i in 0 .. n {
		v[i] = d.get_u64()!
	}
	return v
}

pub fn (mut d Decoder) get_map_string() !map[string]string {
	n := d.get_u16()!
	mut v := map[string]string{}
	for _ in 0 .. n {
		key := d.get_string()!
		val := d.get_string()!
		v[key] = val
	}
	return v
}

pub fn (mut d Decoder) get_map_bytes() !map[string][]u8 {
	n := d.get_u16()!
	mut v := map[string][]u8{}
	for _ in 0 .. n {
		key := d.get_string()!
		val := d.get_bytes()!
		v[key] = val
	}
	return v
}

// Gets GID from encoded string
pub fn (mut d Decoder) get_gid() !gid.GID {
	gid_str := d.get_string()!
	return gid.new(gid_str)
}
