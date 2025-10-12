module code

import incubaid.herolib.core.texttools

pub struct Param {
pub mut:
	required    bool   @[omitempty]
	mutable     bool   @[omitempty]
	is_shared   bool   @[omitempty]
	is_optional bool   @[omitempty]
	is_result   bool   @[omitempty]
	description string @[omitempty]
	name        string @[omitempty]
	typ         Type   @[omitempty]
}

@[params]
pub struct Params {
pub:
	v string
}

pub fn new_param(params Params) !Param {
	// TODO: implement function from file line
	return parse_param(params.v)!
}

pub fn (param Param) vgen() string {
	sym := param.typ.symbol()
	param_name := texttools.snake_case(param.name)
	mut vstr := '${param_name} ${sym}'
	if param.mutable {
		vstr = 'mut ${vstr}'
	}
	return '${vstr}'
}

pub fn (p Param) typescript() string {
	name := texttools.camel_case(p.name)
	suffix := if p.is_optional { '?' } else { '' }
	return '${name}${suffix}: ${p.typ.typescript()}'
}

pub fn parse_param(code_ string) !Param {
	mut code := code_.trim_space()

	if code == '!' {
		return Param{
			is_result: true
		}
	} else if code == '?' {
		return Param{
			is_optional: true
		}
	}

	is_mut := code.starts_with('mut ')
	if is_mut {
		code = code.trim_string_left('mut ').trim_space()
	}
	split := code.split(' ').filter(it != '')

	if split.len == 1 {
		// means anonymous param
		return Param{
			typ:     type_from_symbol(split[0])
			mutable: is_mut
		}
	}
	if split.len != 2 {
		return error('invalid param format: ${code_}')
	}
	return Param{
		name:    split[0]
		typ:     type_from_symbol(split[1])
		mutable: is_mut
	}
}
