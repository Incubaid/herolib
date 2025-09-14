module code

pub struct WriteCode {
	destination string
}

@[params]
pub struct WriteOptions {
pub:
	format    bool
	overwrite bool
	document  bool
	prefix    string
	compile   bool // whether to compile the written code
	test      bool // whether to test the written code
}

interface ICodeItem {
	vgen() string
}

pub fn vgen(code []CodeItem) string {
	mut str := ''
	for item in code {
		if item is Function {
			str += '\n${item.vgen()}'
		}
		if item is Struct {
			str += '\n${item.vgen()}'
		}
		if item is Interface {
			str += '\n${item.vgen()}'
		}
		if item is CustomCode {
			str += '\n${item.vgen()}'
		}
	}
	return str
}

// pub fn (code Code) vgen() string {
// 	return code.items.map(it.vgen()).join_lines()
// }

// vgen_import generates an import statement for a given type
pub fn (import_ Import) vgen() string {
	types_str := if import_.types.len > 0 {
		'{${import_.types.join(', ')}}'
	} else {
		''
	} // comma separated string list of  types
	return 'import ${import_.mod} ${types_str}'
}

pub fn vgen_generics(generics map[string]string) string {
	if generics.keys().len == 0 {
		return ''
	}
	mut vstr := '['
	for key, val in generics {
		vstr += if val != '' { val } else { key }
	}
	return '${vstr}]'
}

pub fn (custom CustomCode) vgen() string {
	return custom.text
}
