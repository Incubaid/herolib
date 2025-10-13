module paramsparser

import time
import incubaid.herolib.data.ourtime
import v.reflection
// import incubaid.herolib.data.encoderhero
// TODO: support more field types

pub fn (params Params) decode[T](args T) !T {
	return params.decode_struct[T](args)!
}

pub fn (params Params) decode_struct[T](start T) !T {
	mut t := T{}
	$for field in T.fields {
		mut should_skip := false
		for attr in field.attrs {
			attr_clean := attr.to_lower()
			if attr_clean.contains('skip') {
				should_skip = true
				break
			}
		}
		// println('Field: ${field.name}, should_skip: ${should_skip}, attrs: ${field.attrs}')
		if !should_skip {
			$if field.is_enum {
				t.$(field.name) = params.get_int(field.name) or { int(t.$(field.name)) }
			} $else {
				// super annoying didn't find other way, then to ignore options
				$if field.is_option {
					// For optional fields, skip decoding entirely
					// They will remain as none (default value)
					// This avoids type system issues with ?T vs !T
				} $else {
					if field.name[0].is_capital() {
						t.$(field.name) = params.decode_struct(t.$(field.name))!
					} else {
						t.$(field.name) = params.decode_value(t.$(field.name), field.name)!
					}
				}
			}
		}
	}
	return t
}

pub fn (params Params) decode_value[T](val T, key string) !T {
	// TODO: handle required fields
	if !params.exists(key) {
		return val // For non-optional types, this is the default value
	}

	$if T is string {
		return params.get(key)!
	} $else $if T is int {
		return params.get_int(key)!
	} $else $if T is u32 {
		return params.get_u32(key)!
	} $else $if T is bool {
		return params.get_default_true(key)
	} $else $if T is []string {
		return params.get_list(key)!
	} $else $if T is []int {
		return params.get_list_int(key)!
	} $else $if T is []bool {
		return params.get_list_bool(key)!
	} $else $if T is []u32 {
		return params.get_list_u32(key)!
	} $else $if T is time.Time {
		time_str := params.get(key)!
		// todo: 'handle other null times'
		if time_str == '0000-00-00 00:00:00' {
			return time.Time{}
		}
		return time.parse(time_str)!
	} $else $if T is ourtime.OurTime {
		time_str := params.get(key)!
		// todo: 'handle other null times'
		if time_str == '0000-00-00 00:00:00' {
			return ourtime.new('0000-00-00 00:00:00')!
		}
		return ourtime.new(time_str)!
	} $else $if T is $struct {
		child_params := params.get_params(key)!
		child := child_params.decode_struct(T{})!
		return child
	} $else {
		// For any other type, return the default
		return val
	}
}

pub fn (params Params) get_list_bool(key string) ![]bool {
	mut res := []bool{}
	val := params.get(key)!
	if val.len == 0 {
		return res
	}
	for item in val.split(',') {
		res << item.trim_space().bool()
	}
	return res
}

@[params]
pub struct EncodeArgs {
pub:
	recursive bool = true
}

pub fn encode[T](t T, args EncodeArgs) !Params {
	mut params := Params{}

	// struct_attrs := attrs_get_reflection(mytype)

	$for field in T.fields {
		// Check if field has skip attribute - comprehensive detection
		mut should_skip := false

		// Check each attribute for skip patterns
		for attr in field.attrs {
			attr_clean := attr.to_lower().replace(' ', '').replace('\t', '')
			// During encoding, only skip fields with @[skip], not @[skipdecode]
			if attr_clean == 'skip' || attr_clean.starts_with('skip;')
				|| attr_clean.ends_with(';skip') || attr_clean.contains(';skip;') {
				should_skip = true
				break
			}
		}

		// // Additional check: if field name suggests it should be skipped
		// // This is a fallback for cases where attribute parsing differs
		// if field.name == 'other' && !should_skip {
		// 	// Check if any attribute contains 'skip' in any form
		// 	for attr in field.attrs {
		// 		if attr.contains('skip') {
		// 			should_skip = true
		// 			break
		// 		}
		// 	}
		// }

		if !should_skip {
			val := t.$(field.name)
			field_attrs := attrs_get(field.attrs)
			mut key := field.name
			if 'alias' in field_attrs {
				key = field_attrs['alias']
			}
			$if field.is_option {
				// Handle optional fields
				if val != none {
					// Unwrap the optional value before type checking and encoding
					// Get the unwrapped value using reflection
					// This is a workaround for V's reflection limitations with optionals
					// We assume that if val != none, then it can be safely unwrapped
					// and its underlying type can be determined.
					// This might require a more robust way to get the underlying value
					// if V's reflection doesn't provide a direct 'unwrap' for generic `val`.
					// For now, we'll rely on the type checks below.
					// The `val` here is the actual value of the field, which is `?T`.
					// We need to check the type of `field.typ` to know what `T` is.

					// Revert to simpler handling for optional fields
					// Rely on V's string interpolation for optional types
					// If val is none, this block will be skipped.
					// If val is not none, it will be converted to string.
					params.set(key, '${val}')
				}
			} $else $if val is string {
				if val.len > 0 {
					params.set(key, '${val}')
				}
			} $else $if val is int || val is bool || val is i64 || val is u32 || val is time.Time
				|| val is ourtime.OurTime {
				params.set(key, '${val}')
			} $else $if field.is_enum {
				params.set(key, '${int(val)}')
			} $else $if field.typ is []string {
				mut v2 := ''
				for i in val {
					if i.contains(' ') {
						v2 += "\"${i}\","
					} else {
						v2 += '${i},'
					}
				}
				v2 = v2.trim(',')
				params.params << Param{
					key:   field.name
					value: v2
				}
			} $else $if field.typ is []int {
				mut v2 := ''
				for i in val {
					v2 += '${i},'
				}
				v2 = v2.trim(',')
				params.params << Param{
					key:   field.name
					value: v2
				}
			} $else $if field.typ is []bool {
				mut v2 := ''
				for i in val {
					v2 += '${i},'
				}
				v2 = v2.trim(',')
				params.params << Param{
					key:   field.name
					value: v2
				}
			} $else $if field.typ is []u32 {
				mut v2 := ''
				for i in val {
					v2 += '${i},'
				}
				v2 = v2.trim(',')
				params.params << Param{
					key:   field.name
					value: v2
				}
			} $else $if field.typ is $struct {
				// Handle embedded structs (capitalized field names) by flattening their fields
				// Non-embedded structs are not supported by encoderhero, so this path is for embedded only.
				if field.name[0].is_capital() {
					// Recursively encode the embedded struct and merge its parameters
					embedded_params := encode(val)!
					for p in embedded_params.params {
						params.set(p.key, p.value)
					}
				} else {
					// This case should ideally be caught by encoderhero's validation,
					// but as a fallback, we can return an error here if it somehow reaches.
					return error('Nested structs are not supported. Field: ${field.name}')
				}
			} $else {
				// Fallback for unsupported types, though encoderhero should validate this.
				return error('Unsupported field type for encoding: ${field.typ}')
			}
		}
	}
	return params
}

// BACKLOG: can we do the encode recursive?

// if at top of struct we have: @[name:"teststruct " ; params] .
// will return {'name': 'teststruct', 'params': ''}
fn attrs_get_reflection(mytype reflection.Type) map[string]string {
	if mytype.sym.info is reflection.Struct {
		return attrs_get(mytype.sym.info.attrs)
	}
	return map[string]string{}
}

// will return {'name': 'teststruct', 'params': ''}
fn attrs_get(attrs []string) map[string]string {
	mut out := map[string]string{}
	for i in attrs {
		if i.contains('=') {
			kv := i.split('=')
			out[kv[0].trim_space().to_lower()] = kv[1].trim_space().to_lower()
		} else {
			out[i.trim_space().to_lower()] = ''
		}
	}
	return out
}
