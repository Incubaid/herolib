module code

import log
import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import os

pub interface IFile {
	name string
	write(string, WriteOptions) !
	write_str(WriteOptions) !string
}

pub struct File {
pub mut:
	name      string
	extension string
	content   string
}

pub fn (f File) write(path string, params WriteOptions) ! {
	mut fd_file := pathlib.get_file(path: '${path}/${f.name}.${f.extension}')!
	fd_file.write(f.content)!
	if f.extension == 'ts' {
		return f.typescript(path, params)
	}
}

pub fn (f File) write_str(params WriteOptions) !string {
	return f.content
}

pub fn (f File) typescript(path string, params WriteOptions) ! {
	if params.format {
		os.execute('npx prettier --write ${path}')
	}
}

pub struct VFile {
pub mut:
	name    string
	mod     string
	imports []Import
	consts  []Const
	items   []CodeItem
	content string
}

pub fn new_file(config VFile) VFile {
	return VFile{
		...config
		mod:   texttools.name_fix(config.mod)
		items: config.items
	}
}

pub fn (mut file VFile) add_import(import_ Import) ! {
	for mut i in file.imports {
		if i.mod == import_.mod {
			i.add_types(import_.types)
			return
		}
	}
	file.imports << import_
}

pub fn (code VFile) write(path string, options WriteOptions) ! {
	filename := '${options.prefix}${texttools.name_fix(code.name)}.v'
	mut filepath := pathlib.get('${path}/${filename}')

	if !options.overwrite && filepath.exists() {
		return
	}

	imports_str := code.imports.map(it.vgen()).join_lines()

	code_str := if code.content != '' {
		code.content
	} else {
		vgen(code.items)
	}

	consts_str := if code.consts.len > 1 {
		stmts := code.consts.map('${it.name} = ${it.value}')
		'\nconst(\n${stmts.join('\n')}\n)\n'
	} else if code.consts.len == 1 {
		'\nconst ${code.consts[0].name} = ${code.consts[0].value}\n'
	} else {
		''
	}

	mut file := pathlib.get_file(
		path:   filepath.path
		create: true
	)!

	mod_stmt := if code.mod == '' {
		''
	} else {
		'module ${code.mod}'
	}

	file.write('${mod_stmt}\n${imports_str}\n${consts_str}${code_str}')!
	if options.format {
		os.execute('v fmt -w ${file.path}')
	}
}

pub fn (code VFile) write_str(options WriteOptions) !string {
	imports_str := code.imports.map(it.vgen()).join_lines()

	code_str := if code.content != '' {
		code.content
	} else {
		vgen(code.items)
	}

	consts_str := if code.consts.len > 1 {
		stmts := code.consts.map('${it.name} = ${it.value}')
		'\nconst(\n${stmts.join('\n')}\n)\n'
	} else if code.consts.len == 1 {
		'\nconst ${code.consts[0].name} = ${code.consts[0].value}\n'
	} else {
		''
	}

	mod_stmt := if code.mod == '' {
		''
	} else {
		'module ${code.mod}'
	}

	return '${mod_stmt}\n${imports_str}\n${consts_str}${code_str}'
}

pub fn (file VFile) get_function(name string) ?Function {
	log.error('Looking for function ${name} in file ${file.name}')
	functions := file.items.filter(it is Function).map(it as Function)
	target_lst := functions.filter(it.name == name)

	if target_lst.len == 0 {
		return none
	}
	if target_lst.len > 1 {
		panic('This should never happen')
	}
	return target_lst[0]
}

pub fn (mut file VFile) set_function(function Function) ! {
	function_names := file.items.map(if it is Function { it.name } else { '' })

	index := function_names.index(function.name)
	if index == -1 {
		return error('function not found')
	}
	file.items[index] = function
}

pub fn (file VFile) functions() []Function {
	return file.items.filter(it is Function).map(it as Function)
}

pub fn (file VFile) structs() []Struct {
	return file.items.filter(it is Struct).map(it as Struct)
}

pub fn (file VFile) enums() []Enum {
	return file.items.filter(it is Enum).map(it as Enum)
}

pub fn (file VFile) interfaces() []Interface {
	return file.items.filter(it is Interface).map(it as Interface)
}

// parse_vfile parses V code into a VFile struct
// It extracts the module name, imports, constants, structs, functions, enums and interfaces
pub fn parse_vfile(code string) !VFile {
	mut vfile := VFile{
		content: code
	}

	lines := code.split_into_lines()

	// Extract module name
	for line in lines {
		trimmed := line.trim_space()
		if trimmed.starts_with('module ') {
			vfile.mod = trimmed.trim_string_left('module ').trim_space()
			break
		}
	}

	// Extract imports
	for line in lines {
		trimmed := line.trim_space()
		if trimmed.starts_with('import ') {
			import_obj := parse_import(trimmed)
			vfile.imports << import_obj
		}
	}

	// Extract constants
	vfile.consts = parse_consts(code) or { []Const{} }

	// Split code into chunks for parsing structs, functions, enums, and interfaces
	mut chunks := []string{}
	mut current_chunk := ''
	mut brace_count := 0
	mut in_struct_or_fn := false
	mut comment_block := []string{}

	for line in lines {
		trimmed := line.trim_space()

		// Collect comments
		if trimmed.starts_with('//') && !in_struct_or_fn {
			comment_block << line
			continue
		}

		// Check for struct, enum, interface or function start
		if (trimmed.starts_with('struct ') || trimmed.starts_with('pub struct ')
			|| trimmed.starts_with('enum ') || trimmed.starts_with('pub enum ')
			|| trimmed.starts_with('interface ')
			|| trimmed.starts_with('pub interface ') || trimmed.starts_with('fn ')
			|| trimmed.starts_with('pub fn ')) && !in_struct_or_fn {
			in_struct_or_fn = true
			current_chunk = comment_block.join('\n')
			if current_chunk != '' {
				current_chunk += '\n'
			}
			current_chunk += line
			comment_block = []string{}

			if line.contains('{') {
				brace_count += line.count('{')
			}
			if line.contains('}') {
				brace_count -= line.count('}')
			}

			if brace_count == 0 {
				// Single line definition
				chunks << current_chunk
				current_chunk = ''
				in_struct_or_fn = false
			}
			continue
		}

		// Add line to current chunk if we're inside a struct, enum, interface or function
		if in_struct_or_fn {
			current_chunk += '\n' + line

			if line.contains('{') {
				brace_count += line.count('{')
			}
			if line.contains('}') {
				brace_count -= line.count('}')
			}

			// Check if we've reached the end
			if brace_count == 0 {
				chunks << current_chunk
				current_chunk = ''
				in_struct_or_fn = false
			}
		}
	}

	// Parse each chunk and add to items
	for chunk in chunks {
		trimmed := chunk.trim_space()

		if trimmed.contains('struct ') || trimmed.contains('pub struct ') {
			// Parse struct
			struct_obj := parse_struct(chunk) or {
				// Skip invalid structs
				continue
			}
			vfile.items << struct_obj
		} else if trimmed.contains('enum ') || trimmed.contains('pub enum ') {
			// Parse enum
			enum_obj := parse_enum(chunk) or {
				// Skip invalid enums
				continue
			}
			vfile.items << enum_obj
		} else if trimmed.contains('interface ') || trimmed.contains('pub interface ') {
			// Parse interface - TODO: implement when needed
			continue
		} else if trimmed.contains('fn ') || trimmed.contains('pub fn ') {
			// Parse function
			fn_obj := parse_function(chunk) or {
				// Skip invalid functions
				continue
			}
			vfile.items << fn_obj
		}
	}

	return vfile
}
