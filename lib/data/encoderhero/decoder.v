module encoderhero

import time
import freeflowuniverse.herolib.data.paramsparser
import freeflowuniverse.herolib.core.texttools

pub struct Decoder[T] {
pub mut:
	object T
	data   string
}

pub fn decode[T](data string) !T {
	return decode_struct[T](T{}, data)
}

// decode_struct is a generic function that decodes a JSON map into the struct T.
fn decode_struct[T](_ T, data string) !T {
	mut typ := T{}
	// println(data)
	$if T is $struct {
		obj_name := T.name.all_after_last('.').to_lower()
		mut action_name := '${obj_name}.define'
		if !data.contains(action_name) {
			action_name = '${obj_name}.configure'
			if !data.contains(action_name) {
				$if debug {
					print_backtrace()
				}
				return error('Data does not contain action name: ${obj_name}.define or ${action_name}')
			}
		}
		actions_split := data.split('!!')
		actions := actions_split.filter(it.starts_with(action_name))
		// println('actions: ${actions}')
		mut action_str := ''
		// action_str := '!!define.${obj_name}'
		if actions.len > 0 {
			action_str = actions[0]
			params_str := action_str.trim_string_left(action_name)
			params := paramsparser.parse(params_str) or {
				panic('could not parse: ${params_str}\n${err}')
			}
			typ = params.decode[T](typ)!
		}

		// return t_
		$for field in T.fields {
			// Check if field has skip attribute
			mut should_skip := false

			for attr in field.attrs {
				if attr.contains('skip') {
					should_skip = true
					break
				}
				if attr.contains('skipdecode') {
					should_skip = true
					break
				}
			}
			if !should_skip {
				$if field.is_struct {
					// $if field.typ !is time.Time {
					// 	if !field.name[0].is_capital() {
					// 		// skip embedded ones
					// 		mut data_fmt := data.replace(action_str, '')
					// 		data_fmt = data.replace('define.${obj_name}', 'define')
					// 		typ.$(field.name) = decode_struct(typ.$(field.name), data_fmt)!
					// 	}
					// }
				} $else $if field.is_array {
					// arr := decode_array(typ.$(field.name), data_fmt)!
					// typ.$(field.name) = arr
					// if is_struct_array(typ.$(field.name))! {
					// 	mut data_fmt := data.replace(action_str, '')
					// 	data_fmt = data.replace('define.${obj_name}', 'define')
					// 	arr := decode_array(typ.$(field.name), data_fmt)!
					// 	typ.$(field.name) = arr
					// }
				}
			}
		}
	} $else {
		return error("The type `${T.name}` can't be decoded.")
	}
	return typ
}

pub fn is_struct_array[U](_ []U) !bool {
	$if U is $struct {
		return true
	}
	return false
}

pub fn decode_array[T](_ []T, data string) ![]T {
	mut arr := []T{}
	// for i in 0 .. val.len {
	value := T{}
	$if T is $struct {
		// arr << decode_struct(value, data)!
	} $else {
		arr << decode[T](data)!
	}
	// }
	return arr
}
