module rust

import os
import incubaid.herolib.core.pathlib

// Reads and combines all Rust files in the given directory
pub fn read_source_code(source_code_path string) !string {
	// Get all files in the directory
	files := os.ls(source_code_path) or {
		return error('Failed to list files in directory: ${err}')
	}

	// Combine all Rust files into a single source code string
	mut source_code := ''
	for file in files {
		file_path := os.join_path(source_code_path, file)

		// Skip directories and non-Rust files
		if os.is_dir(file_path) || !file.ends_with('.rs') {
			continue
		}

		// Read the file content
		file_content := os.read_file(file_path) or {
			println('Failed to read file ${file_path}: ${err}')
			continue
		}

		// Add file content to the combined source code
		source_code += '// File: ${file}\n${file_content}\n\n'
	}

	if source_code == '' {
		return error('No Rust files found in directory: ${source_code_path}')
	}

	return source_code
}

// Determines the crate path from the source code path
pub fn determine_crate_path(source_code_path string) !string {
	// Extract the path relative to the src directory
	src_index := source_code_path.index('src/') or {
		return error('Could not determine crate path: src/ not found in path')
	}

	mut path_parts := source_code_path[src_index + 4..].split('/')
	// Remove the last part (the file name)
	if path_parts.len > 0 {
		path_parts.delete_last()
	}
	rel_path := path_parts.join('::')
	return 'sal::${rel_path}'
}

// Extracts the module name from a directory path
pub fn extract_module_name_from_path(path string) string {
	dir_parts := path.split('/')
	return dir_parts[dir_parts.len - 1]
}

// Determines the source package information from a given source path
pub struct SourcePackageInfo {
pub:
	name   string // Package name
	path   string // Relative path to the package (for cargo.toml)
	module string // Full module path (e.g., herodb::logic)
}

// Detect source package and module information from a path
pub fn detect_source_package(source_path string) !SourcePackageInfo {
	// Look for Cargo.toml in parent directories to find the crate root
	mut current_path := source_path
	mut package_name := ''
	mut rel_path := ''
	mut module_parts := []string{}

	// Extract module name from the directory path
	mod_name := extract_module_name_from_path(source_path)
	module_parts << mod_name

	// Look up parent directories until we find a Cargo.toml
	for i := 0; i < 10; i++ { // limit depth to avoid infinite loops
		parent_dir := os.dir(current_path)
		cargo_path := os.join_path(parent_dir, 'Cargo.toml')

		if os.exists(cargo_path) {
			// Found the root of the crate
			cargo_content := os.read_file(cargo_path) or {
				return error('Failed to read Cargo.toml at ${cargo_path}: ${err}')
			}

			// Extract package name
			for line in cargo_content.split('\n') {
				if line.contains('name') && line.contains('=') {
					parts := line.split('=')
					if parts.len > 1 {
						package_name = parts[1].trim_space().trim('"').trim("'")
						break
					}
				}
			}

			// Calculate relative path from current working directory to crate root
			current_dir := os.getwd()
			rel_path = pathlib.path_relative(parent_dir, current_dir) or {
				return error('Failed to get relative path: ${err}')
			}
			if rel_path == '.' {
				rel_path = './'
			}

			break
		}

		// Go up one directory
		if parent_dir == current_path {
			break // We've reached the root
		}

		// Add directory name to module path parts (in reverse order)
		parent_dir_name := os.base(parent_dir)
		if parent_dir_name != '' && parent_dir_name != '.' {
			module_parts.insert(0, parent_dir_name)
		}

		current_path = parent_dir
	}

	if package_name == '' {
		// If no Cargo.toml found, use the last directory name as package name
		package_name = os.base(os.dir(source_path))
		rel_path = '../' // default to parent directory
	}

	// Construct the full module path
	mut module_path := module_parts.join('::')
	if module_parts.len >= 2 {
		// Use only the last two components for the module path
		module_path = module_parts[module_parts.len - 2..].join('::')
	}

	return SourcePackageInfo{
		name:   package_name
		path:   rel_path
		module: module_path
	}
}

// Build and run a Rust project with an example
pub fn run_example(project_dir string, example_name string) !(string, string) {
	// Change to the project directory
	os.chdir(project_dir) or { return error('Failed to change directory to project: ${err}') }

	// Run cargo build first
	build_result := os.execute('cargo build')
	if build_result.exit_code != 0 {
		return error('Compilation failed. Please fix the following errors and ensure your code is compatible with the existing codebase:\n\n${build_result.output}')
	}

	// Run the example
	run_result := os.execute('cargo run --example ${example_name}')

	return build_result.output, run_result.output
}

// Extract function names from wrapper code
fn extract_functions_from_code(code string) []string {
	mut functions := []string{}
	lines := code.split('\n')

	for line in lines {
		if line.contains('pub fn ') && !line.contains('//') {
			// Extract function name
			parts := line.split('pub fn ')
			if parts.len > 1 {
				name_parts := parts[1].split('(')
				if name_parts.len > 0 {
					fn_name := name_parts[0].trim_space()
					if fn_name != '' {
						functions << fn_name
					}
				}
			}
		}
	}

	return functions
}

// Extract function names from Rust file
pub fn list_functions_in_file(file_path string) ![]string {
	// Check if file exists
	if !os.exists(file_path) {
		return error('File not found: ${file_path}')
	}

	// Read file content
	content := os.read_file(file_path) or { return error('Failed to read file: ${err}') }

	return extract_functions_from_content(content)
}

// Extract function names from content string
pub fn extract_functions_from_content(content string) []string {
	mut functions := []string{}
	lines := content.split('\n')

	mut in_comment_block := false
	mut current_impl := '' // Track the current impl block
	mut impl_level := 0 // Track nesting level of braces within impl

	for line in lines {
		trimmed := line.trim_space()

		// Skip comment lines and empty lines
		if trimmed.starts_with('//') || trimmed == '' {
			continue
		}

		// Handle block comments
		if trimmed.starts_with('/*') {
			in_comment_block = true
		}
		if in_comment_block {
			if trimmed.contains('*/') {
				in_comment_block = false
			}
			continue
		}

		// Check for impl blocks
		if trimmed.starts_with('impl ') {
			// Extract the struct name from the impl declaration
			mut struct_name := ''

			// Handle generic impls like "impl<T> StructName<T>"
			if trimmed.contains('<') && trimmed.contains('>') {
				// Complex case with generics
				if trimmed.contains(' for ') {
					// Format: impl<T> Trait for StructName<T>
					parts := trimmed.split(' for ')
					if parts.len > 1 {
						struct_parts := parts[1].split('{')
						if struct_parts.len > 0 {
							struct_name = struct_parts[0].trim_space()
							// Remove any generic parameters
							if struct_name.contains('<') {
								struct_name = struct_name.all_before('<')
							}
						}
					}
				} else {
					// Format: impl<T> StructName<T>
					after_impl := trimmed.all_after('impl')
					after_generic := after_impl.all_after('>')
					struct_parts := after_generic.split('{')
					if struct_parts.len > 0 {
						struct_name = struct_parts[0].trim_space()
						// Remove any generic parameters
						if struct_name.contains('<') {
							struct_name = struct_name.all_before('<')
						}
					}
				}
			} else {
				// Simple case without generics
				if trimmed.contains(' for ') {
					// Format: impl Trait for StructName
					parts := trimmed.split(' for ')
					if parts.len > 1 {
						struct_parts := parts[1].split('{')
						if struct_parts.len > 0 {
							struct_name = struct_parts[0].trim_space()
						}
					}
				} else {
					// Format: impl StructName
					parts := trimmed.split('impl ')
					if parts.len > 1 {
						struct_parts := parts[1].split('{')
						if struct_parts.len > 0 {
							struct_name = struct_parts[0].trim_space()
						}
					}
				}
			}

			current_impl = struct_name
			if trimmed.contains('{') {
				impl_level = 1
			} else {
				impl_level = 0
			}
			continue
		}

		// Track brace levels to properly handle nested blocks
		if current_impl != '' {
			// Count opening braces
			for c in trimmed {
				if c == `{` {
					impl_level++
				} else if c == `}` {
					impl_level--
					// If we've closed the impl block, reset current_impl
					if impl_level == 0 {
						current_impl = ''
						break
					}
				}
			}
		}

		// Look for function declarations
		if (trimmed.starts_with('pub fn ') || trimmed.starts_with('fn ')) && !trimmed.contains(';') {
			mut fn_name := ''

			// Extract function name
			if trimmed.starts_with('pub fn ') {
				fn_parts := trimmed.split('pub fn ')
				if fn_parts.len > 1 {
					name_parts := fn_parts[1].split('(')
					if name_parts.len > 0 {
						fn_name = name_parts[0].trim_space()
					}
				}
			} else {
				fn_parts := trimmed.split('fn ')
				if fn_parts.len > 1 {
					name_parts := fn_parts[1].split('(')
					if name_parts.len > 0 {
						fn_name = name_parts[0].trim_space()
					}
				}
			}

			// Add function name to the list if it's not empty
			if fn_name != '' {
				if current_impl != '' {
					// All functions in an impl block use :: notation
					functions << '${current_impl}::${fn_name}'
				} else {
					// Regular function
					functions << fn_name
				}
			}
		}
	}

	return functions
}

// Extract struct names from Rust file
pub fn list_structs_in_file(file_path string) ![]string {
	// Check if file exists
	if !os.exists(file_path) {
		return error('File not found: ${file_path}')
	}

	// Read file content
	content := os.read_file(file_path) or { return error('Failed to read file: ${err}') }

	return extract_structs_from_content(content)
}

// Extract struct names from content string
pub fn extract_structs_from_content(content string) []string {
	mut structs := []string{}
	lines := content.split('\n')

	mut in_comment_block := false

	for line in lines {
		trimmed := line.trim_space()

		// Skip comment lines and empty lines
		if trimmed.starts_with('//') {
			continue
		}

		// Handle block comments
		if trimmed.starts_with('/*') {
			in_comment_block = true
		}
		if in_comment_block {
			if trimmed.contains('*/') {
				in_comment_block = false
			}
			continue
		}

		// Look for struct declarations
		if (trimmed.starts_with('pub struct ') || trimmed.starts_with('struct '))
			&& !trimmed.contains(';') {
			mut struct_name := ''

			// Extract struct name
			if trimmed.starts_with('pub struct ') {
				struct_parts := trimmed.split('pub struct ')
				if struct_parts.len > 1 {
					name_parts := struct_parts[1].split('{')
					if name_parts.len > 0 {
						parts := name_parts[0].split('<')
						struct_name = parts[0].trim_space()
					}
				}
			} else {
				struct_parts := trimmed.split('struct ')
				if struct_parts.len > 1 {
					name_parts := struct_parts[1].split('{')
					if name_parts.len > 0 {
						parts := name_parts[0].split('<')
						struct_name = parts[0].trim_space()
					}
				}
			}

			// Add struct name to the list if it's not empty
			if struct_name != '' {
				structs << struct_name
			}
		}
	}

	return structs
}

// Extract imports from a Rust file
pub fn extract_imports(file_path string) ![]string {
	// Check if file exists
	if !os.exists(file_path) {
		return error('File not found: ${file_path}')
	}

	// Read file content
	content := os.read_file(file_path) or { return error('Failed to read file: ${err}') }

	return extract_imports_from_content(content)
}

// Extract imports from content string
pub fn extract_imports_from_content(content string) []string {
	mut imports := []string{}
	lines := content.split('\n')

	mut in_comment_block := false

	for line in lines {
		trimmed := line.trim_space()

		// Skip comment lines and empty lines
		if trimmed.starts_with('//') {
			continue
		}

		// Handle block comments
		if trimmed.starts_with('/*') {
			in_comment_block = true
		}
		if in_comment_block {
			if trimmed.contains('*/') {
				in_comment_block = false
			}
			continue
		}

		// Extract use statements
		if trimmed.starts_with('use ') && trimmed.ends_with(';') {
			import_part := trimmed[4..trimmed.len - 1].trim_space() // Skip 'use ', remove trailing ';', trim spaces
			imports << import_part
		}
	}

	return imports
}

// Get module name from file path
pub fn get_module_name(file_path string) string {
	// Extract filename from path
	filename := os.base(file_path)

	// If it's mod.rs, use parent directory name
	if filename == 'mod.rs' {
		dir := os.dir(file_path)
		return os.base(dir)
	}

	// Otherwise use filename without extension
	return filename.all_before('.rs')
}

// List all modules in a directory
pub fn list_modules_in_directory(dir_path string) ![]string {
	// Check if directory exists
	if !os.exists(dir_path) || !os.is_dir(dir_path) {
		return error('Directory not found: ${dir_path}')
	}

	// Get all files in the directory
	files := os.ls(dir_path) or { return error('Failed to list files in directory: ${err}') }

	mut modules := []string{}

	// Check for mod.rs
	if files.contains('mod.rs') {
		modules << os.base(dir_path)
	}

	// Check for Rust files
	for file in files {
		if file.ends_with('.rs') && file != 'mod.rs' {
			modules << file.all_before('.rs')
		}
	}

	// Check for directories that contain mod.rs
	for file in files {
		file_path := os.join_path(dir_path, file)
		if os.is_dir(file_path) {
			subfiles := os.ls(file_path) or { continue }
			if subfiles.contains('mod.rs') {
				modules << file
			}
		}
	}

	return modules
}

// Generate an import statement for a module based on current file and target module path
pub fn generate_import_statement(current_file_path string, target_module_path string) !string {
	// Attempt to find the project root (directory containing Cargo.toml)
	mut project_root := ''
	mut current_path := os.dir(current_file_path)

	// Find the project root
	for i := 0; i < 10; i++ { // Limit depth to avoid infinite loops
		cargo_path := os.join_path(current_path, 'Cargo.toml')
		if os.exists(cargo_path) {
			project_root = current_path
			break
		}

		parent_dir := os.dir(current_path)
		if parent_dir == current_path {
			break // We've reached the root
		}
		current_path = parent_dir
	}

	if project_root == '' {
		return error('Could not find project root (Cargo.toml)')
	}

	// Get package info
	pkg_info := detect_source_package(current_file_path) or {
		return error('Failed to detect package info: ${err}')
	}

	// Check if target module is part of the same package
	target_pkg_info := detect_source_package(target_module_path) or {
		return error('Failed to detect target package info: ${err}')
	}

	// If same package, generate a relative import
	if pkg_info.name == target_pkg_info.name {
		// Convert file paths to module paths
		current_file_dir := os.dir(current_file_path)
		target_file_dir := os.dir(target_module_path)

		// Get paths relative to src
		current_rel_path := current_file_dir.replace('${project_root}/src/', '')
		target_rel_path := target_file_dir.replace('${project_root}/src/', '')

		// Convert paths to module format
		current_module := current_rel_path.replace('/', '::')
		target_module := target_rel_path.replace('/', '::')

		// Generate import based on path relationship
		if current_module == target_module {
			// Same module, import target directly
			target_name := get_module_name(target_module_path)
			return 'use crate::${target_module}::${target_name};'
		} else if current_module.contains(target_module) {
			// Target is parent module
			target_name := get_module_name(target_module_path)
			return 'use super::${target_name};'
		} else if target_module.contains(current_module) {
			// Target is child module
			target_name := get_module_name(target_module_path)
			child_path := target_module.replace('${current_module}::', '')
			return 'use self::${child_path}::${target_name};'
		} else {
			// Target is sibling or other module
			target_name := get_module_name(target_module_path)
			return 'use crate::${target_module}::${target_name};'
		}
	} else {
		// External package
		return 'use ${target_pkg_info.name}::${target_pkg_info.module};'
	}
}

// Extract dependencies from Cargo.toml
pub fn extract_dependencies(cargo_path string) !map[string]string {
	// Check if file exists
	if !os.exists(cargo_path) {
		return error('Cargo.toml not found: ${cargo_path}')
	}

	// Read file content
	content := os.read_file(cargo_path) or { return error('Failed to read Cargo.toml: ${err}') }

	mut dependencies := map[string]string{}
	mut in_dependencies_section := false

	lines := content.split('\n')
	for line in lines {
		trimmed := line.trim_space()

		// Check for dependencies section
		if trimmed == '[dependencies]' {
			in_dependencies_section = true
			continue
		} else if trimmed.starts_with('[') && in_dependencies_section {
			// Left dependencies section
			in_dependencies_section = false
			continue
		}

		// Extract dependency info
		if in_dependencies_section && trimmed != '' {
			if trimmed.contains('=') {
				eq_pos := trimmed.index('=') or { continue } // Find the first '='
				name := trimmed[..eq_pos].trim_space()
				mut value := trimmed[eq_pos + 1..].trim_space()

				// Remove surrounding quotes if they exist (optional, but good practice for simple strings)
				// Note: This won't remove braces for tables, which is desired.
				if value.starts_with('"') && value.ends_with('"') {
					value = value[1..value.len - 1]
				} else if value.starts_with("'") && value.ends_with("'") {
					value = value[1..value.len - 1]
				}
				dependencies[name] = value // Store the potentially complex value string
			}
		}
	}

	return dependencies
}

// Get a function declaration from a file by its name
pub fn get_function_from_file(file_path string, function_name string) !string {
	// Check if file exists
	if !os.exists(file_path) {
		return error('File not found: ${file_path}')
	}

	// Read file content
	content := os.read_file(file_path) or { return error('Failed to read file: ${err}') }

	return get_function_from_content(content, function_name)
}

// Get a function declaration from a module by its name
pub fn get_function_from_module(module_path string, function_name string) !string {
	// Check if directory exists
	if !os.exists(module_path) {
		return error('Module path not found: ${module_path}')
	}

	// If it's a directory, look for mod.rs or lib.rs
	if os.is_dir(module_path) {
		mod_rs_path := os.join_path(module_path, 'mod.rs')
		lib_rs_path := os.join_path(module_path, 'lib.rs')

		if os.exists(mod_rs_path) {
			result := get_function_from_file(mod_rs_path, function_name) or {
				if err.msg().contains('Function ${function_name} not found') {
					'' // Not found error, resolve or block to empty string
				} else {
					return err // Propagate other errors
				}
			}
			if result != '' {
				return result
			}
		}

		if os.exists(lib_rs_path) { // Changed else if to if
			result := get_function_from_file(lib_rs_path, function_name) or {
				if err.msg().contains('Function ${function_name} not found') {
					'' // Not found error, resolve or block to empty string
				} else {
					return err // Propagate other errors
				}
			}
			if result != '' {
				return result
			}
		}

		// Try to find the function in any Rust file in the directory
		files := os.ls(module_path) or {
			return error('Failed to list files in module directory: ${err}')
		}

		for file in files {
			if file.ends_with('.rs') {
				file_path := os.join_path(module_path, file)
				result := get_function_from_file(file_path, function_name) or {
					if err.msg().contains('Function ${function_name} not found') {
						'' // Not found error, resolve or block to empty string
					} else {
						return err // Propagate other errors
					}
				}
				if result != '' {
					return result
				}
				// Found it
			}
		}

		return error('Function ${function_name} not found in module ${module_path}')
	} else {
		// It's a file path, treat it as a direct file
		return get_function_from_file(module_path, function_name)
	}
}

// Get a function declaration from content by its name
pub fn get_function_from_content(content string, function_name string) !string {
	is_method := function_name.contains('::')
	mut struct_name := ''
	mut method_name := function_name
	if is_method {
		parts := function_name.split('::')
		if parts.len == 2 {
			struct_name = parts[0]
			method_name = parts[1]
		} else {
			return error('Invalid method format: ${function_name}')
		}
	}

	lines := content.split('\n')
	mut function_declaration := ''
	mut brace_level := 0
	mut function_start_line_found := false
	mut in_impl_block := false // Flag to track if we are inside the correct impl block
	mut impl_brace_level := 0 // To know when the impl block ends

	for line in lines {
		trimmed := line.trim_space()
		if trimmed.starts_with('//') {
			continue
		}
		// Skip single-line comments

		// Handle finding the correct impl block if it's a method
		if is_method && !in_impl_block {
			if trimmed.contains('impl') && trimmed.contains(struct_name) {
				in_impl_block = true
				// Calculate the brace level *before* this impl line
				// This is tricky, maybe just track entry/exit
				for c in line {
					if c == `{` {
						impl_brace_level += 1
					}
				}
				continue // Don't process the impl line itself as the start
			}
			continue // Skip lines until the correct impl block is found
		}

		// Handle exiting the impl block
		if is_method && in_impl_block {
			current_line_brace_change := line.count('{') - line.count('}')
			if impl_brace_level + current_line_brace_change <= 0 { // Assuming impl starts at level 0 relative to its scope
				in_impl_block = false // Exited the impl block
				impl_brace_level = 0
			}
			impl_brace_level += current_line_brace_change
		}

		// Find the function/method start line
		if !function_start_line_found {
			mut is_target_line := false
			if is_method && in_impl_block {
				// Inside the correct impl, look for method
				is_target_line = trimmed.contains('fn ${method_name}')
					|| trimmed.contains('fn ${method_name}<') // Handle generics
			} else if !is_method {
				// Look for standalone function
				is_target_line = trimmed.contains('fn ${function_name}')
					|| trimmed.contains('fn ${function_name}<')
			}

			if is_target_line {
				function_start_line_found = true
				function_declaration += line + '\n'

				// Count initial braces on the declaration line
				for c in line {
					if c == `{` {
						brace_level++
					} else if c == `}` {
						brace_level-- // Should ideally not happen on decl line
					}
				}

				// Handle single-line functions like `fn simple() -> i32 { 42 }` or trait methods ending with `;`
				if brace_level == 0 && (line.contains('}') || line.contains(';')) {
					break // Function definition is complete on this line
				}
				continue // Move to next line after finding the start
			}
		}

		// If function start found, append lines and track braces
		if function_start_line_found {
			function_declaration += line + '\n'

			// Count braces to determine when the function ends
			for c in line {
				if c == `{` {
					brace_level++
				} else if c == `}` {
					brace_level--
				}
			}

			// Check if function ended
			if brace_level <= 0 { // <= 0 to handle potential formatting issues
				break
			}
		}
	}

	if function_declaration == '' {
		return error('Function ${function_name} not found in content')
	}

	return function_declaration.trim_space()
}

// Get a struct declaration from a file by its name
pub fn get_struct_from_file(file_path string, struct_name string) !string {
	// Check if file exists
	if !os.exists(file_path) {
		return error('File not found: ${file_path}')
	}

	// Read file content
	content := os.read_file(file_path) or { return error('Failed to read file: ${err}') }

	return get_struct_from_content(content, struct_name)
}

// Get a struct declaration from a module by its name
pub fn get_struct_from_module(module_path string, struct_name string) !string {
	// Check if directory exists
	if !os.exists(module_path) {
		return error('Module path not found: ${module_path}')
	}

	// If it's a directory, look for mod.rs or lib.rs
	if os.is_dir(module_path) {
		mod_rs_path := os.join_path(module_path, 'mod.rs')
		lib_rs_path := os.join_path(module_path, 'lib.rs')

		if os.exists(mod_rs_path) {
			result := get_struct_from_file(mod_rs_path, struct_name) or {
				if err.msg().contains('Struct ${struct_name} not found') {
					'' // Not found error, resolve or block to empty string
				} else {
					return err // Propagate other errors
				}
			}
			if result != '' {
				return result
			}
		}

		if os.exists(lib_rs_path) { // Changed else if to if
			result := get_struct_from_file(lib_rs_path, struct_name) or {
				if err.msg().contains('Struct ${struct_name} not found') {
					'' // Not found error, resolve or block to empty string
				} else {
					return err // Propagate other errors
				}
			}
			if result != '' {
				return result
			}
		}

		// Try to find the struct in any Rust file in the directory
		files := os.ls(module_path) or {
			return error('Failed to list files in module directory: ${err}')
		}

		for file in files {
			if file.ends_with('.rs') {
				file_path := os.join_path(module_path, file)
				result := get_struct_from_file(file_path, struct_name) or {
					if err.msg().contains('Struct ${struct_name} not found') {
						'' // Not found error, resolve or block to empty string
					} else {
						return err // Propagate other errors
					}
				}
				if result != '' {
					return result
				}
				// Found it
			}
		}

		return error('Struct ${struct_name} not found in module ${module_path}')
	} else {
		// It's a file path, treat it as a direct file
		return get_struct_from_file(module_path, struct_name)
	}
}

// Get a struct declaration from content by its name
pub fn get_struct_from_content(content string, struct_name string) !string {
	lines := content.split('\n')

	mut in_comment_block := false
	mut brace_level := 0 // Tracks brace level *within* the target struct
	mut struct_declaration := ''
	mut struct_start_line_found := false

	for line in lines {
		trimmed := line.trim_space()
		if trimmed.starts_with('//') {
			continue
		}
		// Skip single-line comments

		// Handle block comments
		if trimmed.starts_with('/*') {
			in_comment_block = true
		}
		if in_comment_block {
			if trimmed.contains('*/') {
				in_comment_block = false
			}
			continue
		}

		// Find the struct start line
		if !struct_start_line_found {
			// Check for `pub struct Name` or `struct Name` followed by { or ;
			if (trimmed.starts_with('pub struct ${struct_name}')
				|| trimmed.starts_with('struct ${struct_name}'))
				&& (trimmed.contains('{') || trimmed.ends_with(';')
				|| trimmed.contains(' where ') || trimmed.contains('<')) {
				// Basic check to avoid matching struct names that are substrings of others
				// Example: Don't match `MyStructExtended` when looking for `MyStruct`
				// This is a simplified check, regex might be more robust
				name_part := trimmed.all_after('struct ').trim_space()
				if name_part.starts_with(struct_name) {
					// Check if the character after the name is one that indicates end of name ('{', ';', '<', '(' or whitespace)
					char_after := if name_part.len > struct_name.len {
						name_part[struct_name.len]
					} else {
						u8(` `)
					}
					if char_after == u8(`{`) || char_after == u8(`;`) || char_after == u8(`<`)
						|| char_after == u8(`(`) || char_after.is_space() {
						struct_start_line_found = true
						struct_declaration += line + '\n'

						// Count initial braces/check for semicolon on the declaration line
						for c in line {
							if c == `{` {
								brace_level++
							} else if c == `}` {
								brace_level--
							}
							// Should not happen on decl line
						}

						// Handle unit structs ending with semicolon
						if trimmed.ends_with(';') {
							break // Struct definition is complete on this line
						}

						// Handle single-line structs like `struct Simple { field: i32 }`
						if brace_level == 0 && line.contains('{') && line.contains('}') {
							break // Struct definition is complete on this line
						}
						continue // Move to next line after finding the start
					}
				}
			}
		}

		// If struct start found, append lines and track braces
		if struct_start_line_found {
			struct_declaration += line + '\n'

			// Count braces to determine when the struct ends
			for c in line {
				if c == `{` {
					brace_level++
				} else if c == `}` {
					brace_level--
				}
			}

			// Check if struct ended
			if brace_level <= 0 { // <= 0 handles potential formatting issues or initial non-zero level
				break
			}
		}
	}

	if struct_declaration == '' {
		return error('Struct ${struct_name} not found in content')
	}

	return struct_declaration.trim_space()
}

// Struct to hold parsed struct information
pub struct StructInfo {
pub:
	struct_name string
	fields      map[string]string // field_name: field_type
}

// Helper function to parse a Rust struct definition from a string
pub fn parse_rust_struct(definition string) !StructInfo {
	mut struct_name := ''
	mut fields := map[string]string{}
	mut in_struct := false
	mut brace_level := 0
	lines := definition.split('\n')

	for line in lines {
		trimmed_line := line.trim_space()

		if trimmed_line.starts_with('pub struct') || trimmed_line.starts_with('struct') {
			parts := trimmed_line.split(' ')
			for i, part in parts {
				if part == 'struct' && i + 1 < parts.len {
					struct_name = parts[i + 1].split('{')[0].trim_space()
					break
				}
			}
			in_struct = true
			if trimmed_line.contains('{') {
				brace_level++
			}
			continue
		}

		if in_struct {
			if trimmed_line.contains('{') {
				brace_level++
			}
			if trimmed_line.contains('}') {
				brace_level--
				if brace_level == 0 {
					in_struct = false
					break // End of struct definition
				}
			}

			// Inside the struct definition, parse fields (skip comments and attributes)
			if brace_level > 0 && !trimmed_line.starts_with('//') && !trimmed_line.starts_with('#[')
				&& trimmed_line.contains(':') {
				parts := trimmed_line.split(':')
				if parts.len >= 2 {
					// Extract field name (handle potential 'pub ')
					field_name_part := parts[0].trim_space()
					mut field_name := '' // Explicitly declare with type
					if field_name_part.starts_with('pub ') {
						field_name = field_name_part['pub '.len..].trim_space()
					} else {
						field_name = field_name_part
					}

					// Extract field type (remove trailing comma)
					mut field_type := parts[1..].join(':').trim_space()
					if field_type.ends_with(',') {
						field_type = field_type[..field_type.len - 1]
					}

					// Skip attributes or comments if they somehow got here (e.g. line ending comments)
					if field_name.starts_with('[') || field_name.starts_with('/')
						|| field_name == '' {
						continue
					}

					fields[field_name] = field_type
				}
			}
		}
	}

	if struct_name == '' {
		return error('Could not find struct name in definition')
	}
	if fields.len == 0 {
		return error('Could not parse any fields from the struct definition')
	}

	return StructInfo{struct_name, fields}
}

// Find the project root directory (the one containing Cargo.toml)
fn find_project_root(path string) string {
	mut current_path := path

	// If path is a file, get its directory
	if !os.is_dir(current_path) {
		current_path = os.dir(current_path)
	}

	// Look up parent directories until we find a Cargo.toml
	for i := 0; i < 10; i++ { // Limit depth to avoid infinite loops
		cargo_path := os.join_path(current_path, 'Cargo.toml')
		if os.exists(cargo_path) {
			return current_path
		}

		parent_dir := os.dir(current_path)
		if parent_dir == current_path {
			break // We've reached the filesystem root
		}
		current_path = parent_dir
	}

	return '' // No project root found
}

// Get module dependency information
pub fn get_module_dependency(importer_path string, module_path string) !ModuleDependency {
	// Verify paths exist
	if !os.exists(importer_path) {
		return error('Importer path does not exist: ${importer_path}')
	}

	if !os.exists(module_path) {
		return error('Module path does not exist: ${module_path}')
	}

	// Get import statement
	import_statement := generate_import_statement(importer_path, module_path)! // Use local function

	// Try to find the project roots for both paths
	importer_project_root := find_project_root(importer_path)
	module_project_root := find_project_root(module_path)

	mut dependency := ModuleDependency{
		import_statement: import_statement
		module_path:      module_path
	}

	// If they're in different projects, we need to extract dependency information
	if importer_project_root != module_project_root && module_project_root != '' {
		cargo_path := os.join_path(module_project_root, 'Cargo.toml')
		if os.exists(cargo_path) {
			// Get package info to determine name and version
			pkg_info := detect_source_package(module_path) or {
				return dependency // Return what we have if we can't get package info
			}
			dependency.package_name = pkg_info.name

			// Extract version from Cargo.toml if possible
			dependencies := extract_dependencies(cargo_path) or {
				return dependency // Return what we have if we can't extract dependencies
			}

			// Check if the package is already a dependency
			importer_cargo_path := os.join_path(importer_project_root, 'Cargo.toml')
			if os.exists(importer_cargo_path) {
				importer_dependencies := extract_dependencies(importer_cargo_path) or {
					map[string]string{} // Empty map if we can't extract dependencies
				}

				// Check if package is already a dependency
				if pkg_info.name in importer_dependencies {
					dependency.is_already_dependency = true
					dependency.current_version = importer_dependencies[pkg_info.name]
				}
			}

			// Add cargo dependency line
			dependency.cargo_dependency = '${pkg_info.name} = "<version>"' // Placeholder for version
		}
	} else {
		// Same project, no need for external dependency
		dependency.is_in_same_project = true
	}

	return dependency
}

// Information about a module dependency
pub struct ModuleDependency {
pub mut:
	import_statement      string // The Rust import statement to use
	module_path           string // Path to the module
	package_name          string // Name of the package (crate)
	cargo_dependency      string // Line to add to Cargo.toml
	current_version       string // Current version if already a dependency
	is_already_dependency bool   // Whether the package is already a dependency
	is_in_same_project    bool   // Whether the module is in the same project
}
