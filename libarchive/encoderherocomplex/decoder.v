module encoderherocomplex

import incubaid.herolib.data.paramsparser
import time

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
    
    $if T is $struct {
        obj_name := T.name.all_after_last('.').to_lower()
        mut action_name := '${obj_name}.define'
        
        if !data.contains(action_name) {
            action_name = '${obj_name}.configure'
            if !data.contains(action_name) {
                action_name = 'define.${obj_name}'
                if !data.contains(action_name) {
                    action_name = 'configure.${obj_name}'
                    if !data.contains(action_name) {
                        return error('Data does not contain action: ${obj_name}.define, ${obj_name}.configure, define.${obj_name}, or configure.${obj_name}')
                    }
                }
            }
        }
        
        // Split by !! and filter for relevant actions
        actions_split := data.split('!!')
        actions := actions_split.filter(it.trim_space().len > 0)
        
        // Find and parse main action
        main_actions := actions.filter(it.contains(action_name) && !it.contains('.${obj_name}.'))
        
        if main_actions.len > 0 {
            action_str := main_actions[0]
            params_str := action_str.all_after(action_name).trim_space()
            params := paramsparser.parse(params_str) or {
                return error('Could not parse params: ${params_str}\n${err}')
            }
            typ = params.decode[T](typ)!
        }
        
        // Process nested fields
        $for field in T.fields {
            mut should_skip := false
            
            for attr in field.attrs {
                if attr.contains('skip') || attr.contains('skipdecode') {
                    should_skip = true
                    break
                }
            }
            
            if !should_skip {
                field_name := field.name.to_lower()
                
                $if field.is_struct {
                    $if field.typ !is time.Time {
                        // Handle nested structs
                        if !field.name[0].is_capital() {
                            nested_action := '${action_name}.${field_name}'
                            nested_actions := actions.filter(it.contains(nested_action))
                            
                            if nested_actions.len > 0 {
                                nested_data := '!!' + nested_actions.join('\n!!')
                                typ.$(field.name) = decode_struct(typ.$(field.name), nested_data)!
                            }
                        }
                    }
                } $else $if field.is_array {
                    // Handle arrays of structs
                    elem_type_name := field.typ.all_after(']').to_lower()
                    array_action := '${action_name}.${elem_type_name}'
                    array_actions := actions.filter(it.contains(array_action))
                    
                    if array_actions.len > 0 {
                        mut arr_data := []string{}
                        for action in array_actions {
                            arr_data << '!!' + action
                        }
                        
                        // Decode each array item
                        decoded_arr := decode_array(typ.$(field.name), arr_data.join('\n'))!
                        typ.$(field.name) = decoded_arr
                    }
                }
            }
        }
    } $else {
        return error("The type `${T.name}` can't be decoded.")
    }
    
    return typ
}

fn decode_array[T](_ []T, data string) ![]T {
    mut arr := []T{}
    
    $if T is $struct {
        // Split by !! to get individual items
        items := data.split('!!').filter(it.trim_space().len > 0)
        
        for item in items {
            item_data := '!!' + item
            decoded := decode_struct(T{}, item_data)!
            arr << decoded
        }
    } $else {
        return error('Array decoding only supports structs')
    }
    
    return arr
}

