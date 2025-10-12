module code

import incubaid.herolib.core.texttools

pub struct Function {
pub:
	name     string @[omitempty]
	receiver Param  @[omitempty]
	is_pub   bool   @[omitempty]
	mod      string @[omitempty]
pub mut:
	summary     string  @[omitempty]
	description string  @[omitempty]
	params      []Param @[omitempty]
	body        string  @[omitempty]
	result      Param   @[omitempty]
	has_return  bool    @[omitempty]
}

// vgen_function generates a function statement for a function
pub fn (function Function) vgen(options WriteOptions) string {
	mut params_ := function.params.clone()
	optionals := function.params.filter(it.is_optional)
	options_struct := Struct{
		name:   '${texttools.pascal_case(function.name)}Options'
		attrs:  [Attribute{
			name: 'params'
		}]
		fields: optionals.map(StructField{
			name:        it.name
			description: it.description
			typ:         it.typ
		})
	}
	if optionals.len > 0 {
		params_ << Param{
			name: 'options'
			typ:  type_from_symbol(options_struct.name)
		}
	}

	params := params_.filter(!it.is_optional).map(it.vgen()).join(', ')

	receiver_ := Param{
		...function.receiver
		typ: if function.receiver.typ is Result {
			function.receiver.typ.typ
		} else {
			function.receiver.typ
		}
	}
	receiver := if receiver_.vgen().trim_space() != '' {
		'(${receiver_.vgen()})'
	} else {
		''
	}

	name := texttools.name_fix(function.name)
	result := function.result.typ.vgen()

	mut function_str := $tmpl('templates/function/function.v.template')

	// if options.format {
	// 	result := os.execute_opt('echo "${function_str.replace('$', '\\$')}" | v fmt') or {
	// 		panic('${function_str}\n${err}')
	// 	}
	// 	function_str = result.output
	// }
	function_str = function_str.split_into_lines().filter(!it.starts_with('import ')).join('\n')

	return if options_struct.fields.len != 0 {
		'${options_struct.vgen()}\n${function_str}'
	} else {
		function_str
	}
}

pub fn new_function(code string) !Function {
	// TODO: implement function from file line
	return parse_function(code)!
}

pub fn parse_function(code_ string) !Function {
	// Extract comments and actual function code
	mut lines := code_.split_into_lines()
	mut comment_lines := []string{}
	mut function_lines := []string{}
	mut in_function := false

	for line in lines {
		trimmed := line.trim_space()
		if !in_function && trimmed.starts_with('//') {
			comment_lines << trimmed.trim_string_left('//').trim_space()
		} else if !in_function && (trimmed.starts_with('pub fn') || trimmed.starts_with('fn')) {
			in_function = true
			function_lines << line
		} else if in_function {
			function_lines << line
		}
	}

	// Process the function code
	mut code := function_lines.join('\n').trim_space()
	is_pub := code.starts_with('pub ')
	if is_pub {
		code = code.trim_string_left('pub ').trim_space()
	}

	is_fn := code.starts_with('fn ')
	if !is_fn {
		return error('invalid function format')
	}
	code = code.trim_string_left('fn ').trim_space()

	receiver := if code.starts_with('(') {
		param_str := code.all_after('(').all_before(')').trim_space()
		code = code.all_after(')').trim_space()
		parse_param(param_str)!
	} else {
		Param{}
	}

	name := code.all_before('(').trim_space()
	code = code.trim_string_left(name).trim_space()

	params_str := code.all_after('(').all_before(')')
	params := if params_str.trim_space() != '' {
		params_str_lst := params_str.split(',')
		params_str_lst.map(parse_param(it)!)
	} else {
		[]Param{}
	}
	// Extract the result type, handling the ! for result types
	mut result_type := code.all_after(')').all_before('{').replace(' ', '')
	mut has_return := false

	// Check if the result type contains !
	if result_type.contains('!') {
		has_return = true
		result_type = result_type.replace('!', '')
	}

	result := new_param(
		v: result_type
	)!

	body := if code.contains('{') { code.all_after('{').all_before_last('}') } else { '' }

	// Process the comments into a description
	description := comment_lines.join('\n')

	return Function{
		name:        name
		receiver:    receiver
		params:      params
		result:      result
		body:        body
		description: description
		is_pub:      is_pub
		has_return:  has_return
	}
}
