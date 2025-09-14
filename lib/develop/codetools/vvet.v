module code

import freeflowuniverse.herolib.ui.console
import os

// ===== FILE AND DIRECTORY OPERATIONS =====

// list_v_files returns all .v files in a directory (non-recursive), excluding generated files ending with _.v
// ARGS:
//   dir string - directory path to search
// RETURNS:
//   []string - list of absolute paths to V files
pub fn list_v_files(dir string) ![]string {
	files := os.ls(dir) or { return error('Error listing directory: ${err}') }

	mut v_files := []string{}
	for file in files {
		if file.ends_with('.v') && !file.ends_with('_.v') {
			filepath := os.join_path(dir, file)
			v_files << filepath
		}
	}

	return v_files
}

// get_module_dir converts a V module path to a directory path
// ARGS:
//   mod string - module name (e.g., 'freeflowuniverse.herolib.mcp')
// RETURNS:
//   string - absolute path to the module directory
pub fn get_module_dir(mod string) string {
	module_parts := mod.trim_string_left('freeflowuniverse.herolib').split('.')
	return '${os.home_dir()}/code/github/freeflowuniverse/herolib/lib/${module_parts.join('/')}'
}

// ===== CODE PARSING UTILITIES =====

// find_closing_brace finds the position of the closing brace that matches an opening brace
// ARGS:
//   content string - the string to search in
//   start_i int - the position after the opening brace
// RETURNS:
//   ?int - position of the matching closing brace, or none if not found
fn find_closing_brace(content string, start_i int) ?int {
	mut brace_count := 1
	for i := start_i; i < content.len; i++ {
		if content[i] == `{` {
			brace_count++
		} else if content[i] == `}` {
			brace_count--
			if brace_count == 0 {
				return i
			}
		}
	}
	return none
}

// get_function_from_file parses a V file and extracts a specific function block including its comments
// ARGS:
//   file_path string - path to the V file
//   function_name string - name of the function to extract
// RETURNS:
//   string - the function block including comments, or error if not found
pub fn get_function_from_file(file_path string, function_name string) !Function {
	content := os.read_file(file_path) or {
		return error('Failed to read file ${file_path}: ${err}')
	}

	vfile := parse_vfile(content) or { return error('Failed to parse file ${file_path}: ${err}') }

	if fn_obj := vfile.get_function(function_name) {
		return fn_obj
	}

	return error('function ${function_name} not found in file ${file_path}')
}

// get_function_from_module searches for a function in all V files within a module
// ARGS:
//   module_path string - path to the module directory
//   function_name string - name of the function to find
// RETURNS:
//   string - the function definition if found, or error if not found
pub fn get_function_from_module(module_path string, function_name string) !Function {
	v_files := list_v_files(module_path) or {
		return error('Failed to list V files in ${module_path}: ${err}')
	}

	console.print_stderr('Found ${v_files} V files in ${module_path}')
	for v_file in v_files {
		// Read the file content
		content := os.read_file(v_file) or { continue }

		// Parse the file
		vfile := parse_vfile(content) or { continue }

		// Look for the function
		if fn_obj := vfile.get_function(function_name) {
			return fn_obj
		}
	}

	return error('function ${function_name} not found in module ${module_path}')
}

// get_type_from_module searches for a type definition in all V files within a module
// ARGS:
//   module_path string - path to the module directory
//   type_name string - name of the type to find
// RETURNS:
//   string - the type definition if found, or error if not found
pub fn get_type_from_module(module_path string, type_name string) !string {
	console.print_debug('Looking for type ${type_name} in module ${module_path}')
	v_files := list_v_files(module_path) or {
		return error('Failed to list V files in ${module_path}: ${err}')
	}

	for v_file in v_files {
		console.print_debug('Checking file: ${v_file}')
		content := os.read_file(v_file) or { return error('Failed to read file ${v_file}: ${err}') }

		// Look for both regular and pub struct declarations
		mut type_str := 'struct ${type_name} {'
		mut i := content.index(type_str) or { -1 }
		mut is_pub := false

		if i == -1 {
			// Try with pub struct
			type_str = 'pub struct ${type_name} {'
			i = content.index(type_str) or { -1 }
			is_pub = true
		}

		if i == -1 {
			type_import := content.split_into_lines().filter(it.contains('import')
				&& it.contains(type_name))
			if type_import.len > 0 {
				mod := type_import[0].trim_space().trim_string_left('import ').all_before(' ')
				return get_type_from_module(get_module_dir(mod), type_name)
			}
			continue
		}
		console.print_debug('Found type ${type_name} in ${v_file} at position ${i}')

		// Find the start of the struct definition including comments
		mut comment_start := i
		mut line_start := i

		// Find the start of the line containing the struct definition
		for j := i; j >= 0; j-- {
			if j == 0 || content[j - 1] == `\n` {
				line_start = j
				break
			}
		}

		// Find the start of the comment block (if any)
		for j := line_start - 1; j >= 0; j-- {
			if j == 0 {
				comment_start = 0
				break
			}

			// If we hit a blank line or a non-comment line, stop
			if content[j] == `\n` {
				if j > 0 && j < content.len - 1 {
					// Check if the next line starts with a comment
					next_line_start := j + 1
					if next_line_start < content.len && content[next_line_start] != `/` {
						comment_start = j + 1
						break
					}
				}
			}
		}

		// Find the end of the struct definition
		closing_i := find_closing_brace(content, i + type_str.len) or {
			return error('could not find where declaration for type ${type_name} ends')
		}

		// Get the full struct definition including the struct declaration line
		full_struct := content.substr(line_start, closing_i + 1)
		console.print_debug('Found struct definition:\n${full_struct}')

		// Return the full struct definition
		return full_struct
	}

	return error('type ${type_name} not found in module ${module_path}')
}

// ===== V LANGUAGE TOOLS =====

// vtest runs v test on the specified file or directory
// ARGS:
//   fullpath string - path to the file or directory to test
// RETURNS:
//   string - test results output, or error if test fails
pub fn vtest(fullpath string) !string {
	console.print_item('test ${fullpath}')
	if !os.exists(fullpath) {
		return error('File or directory does not exist: ${fullpath}')
	}
	if os.is_dir(fullpath) {
		mut results := ''
		for item in list_v_files(fullpath)! {
			results += vtest(item)!
			results += '\n-----------------------\n'
		}
		return results
	} else {
		cmd := 'v -gc none -stats -enable-globals -show-c-output -keepc -n -w -cg -o /tmp/tester.c -g -cc tcc test ${fullpath}'
		console.print_debug('Executing command: ${cmd}')
		result := os.execute(cmd)
		if result.exit_code != 0 {
			return error('Test failed for ${fullpath} with exit code ${result.exit_code}\n${result.output}')
		} else {
			console.print_item('Test completed for ${fullpath}')
		}
		return 'Command: ${cmd}\nExit code: ${result.exit_code}\nOutput:\n${result.output}'
	}
}

// vet_file runs v vet on a single file
// ARGS:
//   file string - path to the file to vet
// RETURNS:
//   string - vet results output, or error if vet fails
fn vet_file(file string) !string {
	cmd := 'v vet -v -w ${file}'
	console.print_debug('Executing command: ${cmd}')
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Vet failed for ${file} with exit code ${result.exit_code}\n${result.output}')
	} else {
		console.print_item('Vet completed for ${file}')
	}
	return 'Command: ${cmd}\nExit code: ${result.exit_code}\nOutput:\n${result.output}'
}

// vvet runs v vet on the specified file or directory
// ARGS:
//   fullpath string - path to the file or directory to vet
// RETURNS:
//   string - vet results output, or error if vet fails
pub fn vvet(fullpath string) !string {
	console.print_item('vet ${fullpath}')
	if !os.exists(fullpath) {
		return error('File or directory does not exist: ${fullpath}')
	}

	if os.is_dir(fullpath) {
		mut results := ''
		files := list_v_files(fullpath) or { return error('Error listing V files: ${err}') }
		for file in files {
			results += vet_file(file) or {
				console.print_stderr('Failed to vet ${file}: ${err}')
				return error('Failed to vet ${file}: ${err}')
			}
			results += '\n-----------------------\n'
		}
		return results
	} else {
		return vet_file(fullpath)
	}
}
