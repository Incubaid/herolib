module vcode

import freeflowuniverse.herolib.mcp
import freeflowuniverse.herolib.mcp.logger
import os
import log

fn get_module_dir(mod string) string {
	module_parts := mod.trim_string_left('freeflowuniverse.herolib').split('.')
	return '${os.home_dir()}/code/github/freeflowuniverse/herolib/lib/${module_parts.join('/')}'
}

// given a module path and a type name, returns the type definition of that type within that module
// for instance: get_type_from_module('lib/mcp/developer/vlang.v', 'Developer') might return struct Developer {...}
fn get_type_from_module(module_path string, type_name string) !string {
	println('Looking for type ${type_name} in module ${module_path}')
	v_files := list_v_files(module_path) or {
		return error('Failed to list V files in ${module_path}: ${err}')
	}

	for v_file in v_files {
		println('Checking file: ${v_file}')
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
				log.debug('debugzoooo')
				mod := type_import[0].trim_space().trim_string_left('import ').all_before(' ')
				return get_type_from_module(get_module_dir(mod), type_name)
			}
			continue
		}
		println('Found type ${type_name} in ${v_file} at position ${i}')

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
		println('Found struct definition:\n${full_struct}')

		// Return the full struct definition
		return full_struct
	}

	return error('type ${type_name} not found in module ${module_path}')
}

// given a module path and a function name, returns the function definition of that function within that module
// for instance: get_function_from_module('lib/mcp/developer/vlang.v', 'develop') might return fn develop(...) {...}
fn get_function_from_module(module_path string, function_name string) !string {
	v_files := list_v_files(module_path) or {
		return error('Failed to list V files in ${module_path}: ${err}')
	}

	println('Found ${v_files.len} V files in ${module_path}')
	for v_file in v_files {
		println('Checking file: ${v_file}')
		result := get_function_from_file(v_file, function_name) or {
			println('Function not found in ${v_file}: ${err}')
			continue
		}
		println('Found function ${function_name} in ${v_file}')
		return result
	}

	return error('function ${function_name} not found in module ${module_path}')
}

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
// file_path string - path to the V file
// function_name string - name of the function to extract
// RETURNS: string - the function block including comments, or empty string if not found
fn get_function_from_file(file_path string, function_name string) !string {
	content := os.read_file(file_path) or {
		return error('Failed to read file: ${file_path}: ${err}')
	}

	lines := content.split_into_lines()
	mut result := []string{}
	mut in_function := false
	mut brace_count := 0
	mut comment_block := []string{}

	for i, line in lines {
		trimmed := line.trim_space()

		// Collect comments that might be above the function
		if trimmed.starts_with('//') {
			if !in_function {
				comment_block << line
			} else if brace_count > 0 {
				result << line
			}
			continue
		}

		// Check if we found the function
		if !in_function && (trimmed.starts_with('fn ${function_name}(')
			|| trimmed.starts_with('pub fn ${function_name}(')) {
			in_function = true
			// Add collected comments
			result << comment_block
			comment_block = []
			result << line
			if line.contains('{') {
				brace_count++
			}
			continue
		}

		// If we're inside the function, keep track of braces
		if in_function {
			result << line

			for c in line {
				if c == `{` {
					brace_count++
				} else if c == `}` {
					brace_count--
				}
			}

			// If brace_count is 0, we've reached the end of the function
			if brace_count == 0 && trimmed.contains('}') {
				return result.join('\n')
			}
		} else {
			// Reset comment block if we pass a blank line
			if trimmed == '' {
				comment_block = []
			}
		}
	}

	if !in_function {
		return error('Function "${function_name}" not found in ${file_path}')
	}

	return result.join('\n')
}

// list_v_files returns all .v files in a directory (non-recursive), excluding generated files ending with _.v
fn list_v_files(dir string) ![]string {
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

// test runs v test on the specified file or directory
pub fn vtest(fullpath string) !string {
	logger.info('test ${fullpath}')
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
		cmd := 'v -cg -gc none -stats -enable-globals -show-c-output -keepc -n -w -cg -o /tmp/tester.c -g -cc tcc test ${fullpath}'
		logger.debug('Executing command: ${cmd}')
		result := os.execute(cmd)
		if result.exit_code != 0 {
			return error('Test failed for ${fullpath} with exit code ${result.exit_code}\n${result.output}')
		} else {
			logger.info('Test completed for ${fullpath}')
		}
		return 'Command: ${cmd}\nExit code: ${result.exit_code}\nOutput:\n${result.output}'
	}
}

// vvet runs v vet on the specified file or directory
pub fn vvet(fullpath string) !string {
	logger.info('vet ${fullpath}')
	if !os.exists(fullpath) {
		return error('File or directory does not exist: ${fullpath}')
	}

	if os.is_dir(fullpath) {
		mut results := ''
		files := list_v_files(fullpath) or { return error('Error listing V files: ${err}') }
		for file in files {
			results += vet_file(file) or {
				logger.error('Failed to vet ${file}: ${err}')
				return error('Failed to vet ${file}: ${err}')
			}
			results += '\n-----------------------\n'
		}
		return results
	} else {
		return vet_file(fullpath)
	}
}

// vet_file runs v vet on a single file
fn vet_file(file string) !string {
	cmd := 'v vet -v -w ${file}'
	logger.debug('Executing command: ${cmd}')
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Vet failed for ${file} with exit code ${result.exit_code}\n${result.output}')
	} else {
		logger.info('Vet completed for ${file}')
	}
	return 'Command: ${cmd}\nExit code: ${result.exit_code}\nOutput:\n${result.output}'
}

// cmd := 'v -gc none -stats -enable-globals -show-c-output -keepc -n -w -cg -o /tmp/tester.c -g -cc tcc ${fullpath}'
