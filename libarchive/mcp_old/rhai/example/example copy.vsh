#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.mcp.aitools.escalayer
import os

fn main() {
	// Get the current directory
	current_dir := os.dir(@FILE)

	// Check if a source code path was provided as an argument
	if os.args.len < 2 {
		println('Please provide the path to the source code directory as an argument')
		println('Example: ./example.vsh /path/to/source/code/directory')
		return
	}

	// Get the source code path from the command line arguments
	source_code_path := os.args[1]

	// Check if the path exists and is a directory
	if !os.exists(source_code_path) {
		println('Source code path does not exist: ${source_code_path}')
		return
	}

	if !os.is_dir(source_code_path) {
		println('Source code path is not a directory: ${source_code_path}')
		return
	}

	// Get all Rust files in the directory
	files := os.ls(source_code_path) or {
		println('Failed to list files in directory: ${err}')
		return
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
		println('No Rust files found in directory: ${source_code_path}')
		return
	}

	// Read the rhaiwrapping.md file
	rhai_wrapping_md := os.read_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhaiwrapping.md') or {
		println('Failed to read rhaiwrapping.md: ${err}')
		return
	}

	// Determine the crate path from the source code path
	// Extract the path relative to the src directory
	src_index := source_code_path.index('src/') or {
		println('Could not determine crate path: src/ not found in path')
		return
	}

	mut path_parts := source_code_path[src_index + 4..].split('/')
	// Remove the last part (the file name)
	if path_parts.len > 0 {
		path_parts.delete_last()
	}
	rel_path := path_parts.join('::')
	crate_path := 'sal::${rel_path}'

	// Create a new task
	mut task := escalayer.new_task(
		name:        'rhai_wrapper_creator.escalayer'
		description: 'Create Rhai wrappers for Rust functions that follow builder pattern and create examples corresponding to the provided example file'
	)

	// Create model configs
	sonnet_model := escalayer.ModelConfig{
		name:        'anthropic/claude-3.7-sonnet'
		provider:    'anthropic'
		temperature: 0.7
		max_tokens:  25000
	}

	gpt4_model := escalayer.ModelConfig{
		name:        'gpt-4'
		provider:    'openai'
		temperature: 0.7
		max_tokens:  25000
	}

	// Extract the module name from the directory path (last component)
	dir_parts := source_code_path.split('/')
	name := dir_parts[dir_parts.len - 1]

	// Create the prompt with source code, wrapper example, and rhai_wrapping_md
	prompt_content := create_rhai_wrappers(name, source_code, os.read_file('${current_dir}/prompts/example_script.md') or {
		''
	}, os.read_file('${current_dir}/prompts/wrapper.md') or { '' }, os.read_file('${current_dir}/prompts/errors.md') or {
		''
	}, crate_path)

	// Create a prompt function that returns the prepared content
	prompt_function := fn [prompt_content] (input string) string {
		return prompt_content
	}

	gen := RhaiGen{
		name: name
		dir:  source_code_path
	}

	// Define a single unit task that handles everything
	task.new_unit_task(
		name:              'create_rhai_wrappers'
		prompt_function:   prompt_function
		callback_function: gen.process_rhai_wrappers
		base_model:        sonnet_model
		retry_model:       gpt4_model
		retry_count:       1
	)

	// Initiate the task
	result := task.initiate('') or {
		println('Task failed: ${err}')
		return
	}

	println('Task completed successfully')
	println('The wrapper files have been generated and compiled in the target directory.')
	println('Check /Users/timurgordon/code/git.threefold.info/herocode/sal/src/rhai for the compiled output.')
}

// Define the prompt functions
fn separate_functions(input string) string {
	return 'Read the following Rust code and separate it into functions. Identify all the methods in the Container implementation and their purposes.\n\n${input}'
}

fn create_wrappers(input string) string {
	return 'Create Rhai wrappers for the Rust functions identified in the previous step. The wrappers should follow the builder pattern and provide a clean API for use in Rhai scripts. Include error handling and type conversion.\n\n${input}'
}

fn create_example(input string) string {
	return 'Create a Rhai example script that demonstrates how to use the wrapper functions. The example should be based on the provided example.rs file but adapted for Rhai syntax. Create a web server example that uses the container functions.\n\n${input}'
}

// Define a Rhai wrapper generator function for Container functions
fn create_rhai_wrappers(name string, source_code string, example_rhai string, wrapper_md string, errors_md string, crate_path string) string {
	guides := os.read_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhaiwrapping_classicai.md') or {
		panic('Failed to read guides')
	}
	engine := $tmpl('./prompts/engine.md')
	vector_vs_array := os.read_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhai_array_vs_vector.md') or {
		panic('Failed to read guides')
	}
	rhai_integration_fixes := os.read_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhai_integration_fixes.md') or {
		panic('Failed to read guides')
	}
	rhai_syntax_guide := os.read_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhai_syntax_guide.md') or {
		panic('Failed to read guides')
	}
	generic_wrapper_rs := $tmpl('./templates/generic_wrapper.rs')
	return 'You are a Rust developer tasked with creating Rhai wrappers for Rust functions. Please review the following best practices for Rhai wrappers and then create the necessary files.
${guides}
${vector_vs_array}
${example_rhai}
${wrapper_md}

## Common Errors to Avoid
${errors_md}
${rhai_integration_fixes}
${rhai_syntax_guide}

## Your Task

Please create a wrapper.rs file that implements Rhai wrappers for the provided Rust code, and an example.rhai script that demonstrates how to use these wrappers:

## Rust Code to Wrap

```rust
${source_code}
```

IMPORTANT NOTES:
1. For Rhai imports, use: `use rhai::{Engine, EvalAltResult, plugin::*, Dynamic, Map, Array};` - only import what you actually use
2. The following dependencies are available in Cargo.toml:
   - rhai = "1.21.0"
   - serde = { version = "1.0", features = ["derive"] }
   - serde_json = "1.0"
   - sal = { path = "../../../" }

3. For the wrapper: `use sal::${name};` this way you can access the module functions and objects with ${name}::

4. The generic_wrapper.rs file will be hardcoded into the package, you can use code from there.

```rust
${generic_wrapper_rs}
```

5. IMPORTANT: Prefer strongly typed return values over Dynamic types whenever possible. Only use Dynamic when absolutely necessary.
   - For example, return `Result<String, Box<EvalAltResult>>` instead of `Dynamic` when a function returns a string
   - Use `Result<bool, Box<EvalAltResult>>` instead of `Dynamic` when a function returns a boolean
   - Use `Result<Vec<String>, Box<EvalAltResult>>` instead of `Dynamic` when a function returns a list of strings

6. Your code should include public functions that can be called from Rhai scripts

7. Make sure to implement all necessary helper functions for type conversion

8. DO NOT use the #[rhai_fn] attribute - functions will be registered directly in the engine

9. Make sure to handle string type consistency - use String::from() for string literals when returning in match arms with format!() strings

10. When returning path references, convert them to owned strings (e.g., path().to_string())

11. For error handling, use proper Result types with Box<EvalAltResult> for the error type:
    ```rust
    // INCORRECT:
    pub fn some_function(arg: &str) -> Dynamic {
        match some_operation(arg) {
            Ok(result) => Dynamic::from(result),
            Err(err) => Dynamic::from(format!("Error: {}", err))
        }
    }
    
    // CORRECT:
    pub fn some_function(arg: &str) -> Result<String, Box<EvalAltResult>> {
        some_operation(arg).map_err(|err| {
            Box::new(EvalAltResult::ErrorRuntime(
                format!("Error: {}", err).into(),
                rhai::Position::NONE
            ))
        })
    }
    ```

12. IMPORTANT: Format your response with the code between triple backticks as follows:

```rust
// wrapper.rs
// Your wrapper implementation here
```

```rust
// engine.rs
// Your engine.rs implementation here
```

```rhai
// example.rhai
// Your example Rhai script here
```

13. The example.rhai script should demonstrate the use of all the wrapper functions you create

14. The engine.rs file should contain a register_module function that registers all the wrapper functions and types with the Rhai engine, and a create function. For example:

${engine}

MOST IMPORTANT:
import package being wrapped as `use sal::<name>`
your engine create function is called `create_rhai_engine`

```
'
}

@[params]
pub struct WrapperModule {
pub:
	lib_rs             string
	example_rs         string
	engine_rs          string
	cargo_toml         string
	example_rhai       string
	generic_wrapper_rs string
	wrapper_rs         string
}

// functions is a list of function names that AI should extract and pass in
fn create_wrapper_module(wrapper WrapperModule, functions []string, name_ string, base_dir string) !string {
	// Define project directory paths
	name := name_
	project_dir := '${base_dir}/rhai'

	// Create the project using cargo new --lib
	if os.exists(project_dir) {
		os.rmdir_all(project_dir) or {
			return error('Failed to clean existing project directory: ${err}')
		}
	}

	// Run cargo new --lib to create the project
	os.chdir(base_dir) or { return error('Failed to change directory to base directory: ${err}') }

	cargo_new_result := os.execute('cargo new --lib rhai')
	if cargo_new_result.exit_code != 0 {
		return error('Failed to create new library project: ${cargo_new_result.output}')
	}

	// Create examples directory
	examples_dir := '${project_dir}/examples'
	os.mkdir_all(examples_dir) or { return error('Failed to create examples directory: ${err}') }

	// Write the lib.rs file
	if wrapper.lib_rs != '' {
		os.write_file('${project_dir}/src/lib.rs', wrapper.lib_rs) or {
			return error('Failed to write lib.rs: ${err}')
		}
	}

	// Write the wrapper.rs file
	if wrapper.wrapper_rs != '' {
		os.write_file('${project_dir}/src/wrapper.rs', wrapper.wrapper_rs) or {
			return error('Failed to write wrapper.rs: ${err}')
		}
	}

	// Write the generic wrapper.rs file
	if wrapper.generic_wrapper_rs != '' {
		os.write_file('${project_dir}/src/generic_wrapper.rs', wrapper.generic_wrapper_rs) or {
			return error('Failed to write generic wrapper.rs: ${err}')
		}
	}

	// Write the example.rs file
	if wrapper.example_rs != '' {
		os.write_file('${examples_dir}/example.rs', wrapper.example_rs) or {
			return error('Failed to write example.rs: ${err}')
		}
	}

	// Write the engine.rs file if provided
	if wrapper.engine_rs != '' {
		os.write_file('${project_dir}/src/engine.rs', wrapper.engine_rs) or {
			return error('Failed to write engine.rs: ${err}')
		}
	}

	// Write the Cargo.toml file
	if wrapper.cargo_toml != '' {
		os.write_file('${project_dir}/Cargo.toml', wrapper.cargo_toml) or {
			return error('Failed to write Cargo.toml: ${err}')
		}
	}

	// Write the example.rhai file if provided
	if wrapper.example_rhai != '' {
		os.write_file('${examples_dir}/example.rhai', wrapper.example_rhai) or {
			return error('Failed to write example.rhai: ${err}')
		}
	}

	return project_dir
}

// Helper function to extract code blocks from the response
fn extract_code_block(response string, identifier string, language string) string {
	// Find the start marker for the code block
	mut start_marker := '```${language}\n// ${identifier}'
	if language == '' {
		start_marker = '```\n// ${identifier}'
	}

	start_index := response.index(start_marker) or {
		// Try alternative format
		mut alt_marker := '```${language}\n${identifier}'
		if language == '' {
			alt_marker = '```\n${identifier}'
		}

		response.index(alt_marker) or { return '' }
	}

	// Find the end marker
	end_marker := '```'
	end_index := response.index_after(end_marker, start_index + start_marker.len) or { return '' }

	// Extract the content between the markers
	content_start := start_index + start_marker.len
	content := response[content_start..end_index].trim_space()

	return content
}

// Extract module name from wrapper code
fn extract_module_name(code string) string {
	lines := code.split('\n')

	for line in lines {
		// Look for pub mod or mod declarations
		if line.contains('pub mod ') || line.contains('mod ') {
			// Extract module name
			mut parts := []string{}
			if line.contains('pub mod ') {
				parts = line.split('pub mod ')
			} else {
				parts = line.split('mod ')
			}

			if parts.len > 1 {
				// Extract the module name and remove any trailing characters
				mut name := parts[1].trim_space()
				// Remove any trailing { or ; or whitespace
				name = name.trim_right('{').trim_right(';').trim_space()
				if name != '' {
					return name
				}
			}
		}
	}

	return ''
}

struct RhaiGen {
	name string
	dir  string
}

// Define the callback function that processes the response and compiles the code
fn (gen RhaiGen) process_rhai_wrappers(response string) !string {
	// Extract wrapper.rs content
	wrapper_rs_content := extract_code_block(response, 'wrapper.rs', 'rust')
	if wrapper_rs_content == '' {
		return error('Failed to extract wrapper.rs content from response. Please ensure your code is properly formatted inside a code block that starts with ```rust\n// wrapper.rs and ends with ```')
	}

	// Extract engine.rs content
	mut engine_rs_content := extract_code_block(response, 'engine.rs', 'rust')
	if engine_rs_content == '' {
		// Try to extract from the response without explicit language marker
		engine_rs_content = extract_code_block(response, 'engine.rs', '')
		// if engine_rs_content == '' {
		//     // Use the template engine.rs
		//     engine_rs_content = $tmpl('./templates/engine.rs')
		// }
	}

	// Extract example.rhai content
	mut example_rhai_content := extract_code_block(response, 'example.rhai', 'rhai')
	if example_rhai_content == '' {
		// Try to extract from the response without explicit language marker
		example_rhai_content = extract_code_block(response, 'example.rhai', '')
		if example_rhai_content == '' {
			// Use the example from the template
			example_script_md := os.read_file('${os.dir(@FILE)}/prompts/example_script.md') or {
				return error('Failed to read example.rhai template: ${err}')
			}

			// Extract the code block from the markdown file
			example_rhai_content = extract_code_block(example_script_md, 'example.rhai',
				'rhai')
			if example_rhai_content == '' {
				return error('Failed to extract example.rhai from template file')
			}
		}
	}

	// Extract function names from the wrapper.rs content
	functions := extract_functions_from_code(wrapper_rs_content)

	println('Using module name: ${gen.name}_rhai')
	println('Extracted functions: ${functions.join(', ')}')

	name := gen.name
	// Create a WrapperModule struct with the extracted content
	wrapper := WrapperModule{
		lib_rs:             $tmpl('./templates/lib.rs')
		wrapper_rs:         wrapper_rs_content
		example_rs:         $tmpl('./templates/example.rs')
		engine_rs:          engine_rs_content
		generic_wrapper_rs: $tmpl('./templates/generic_wrapper.rs')
		cargo_toml:         $tmpl('./templates/cargo.toml')
		example_rhai:       example_rhai_content
	}

	// Create the wrapper module
	base_target_dir := gen.dir
	project_dir := create_wrapper_module(wrapper, functions, gen.name, base_target_dir) or {
		return error('Failed to create wrapper module: ${err}')
	}

	// Run the example
	os.chdir(project_dir) or { return error('Failed to change directory to project: ${err}') }

	// Run cargo build first
	build_result := os.execute('cargo build')
	if build_result.exit_code != 0 {
		return error('Compilation failed. Please fix the following errors and ensure your code is compatible with the existing codebase:\n\n${build_result.output}')
	}

	// Run the example
	run_result := os.execute('cargo run --example example')

	return 'Successfully generated Rhai wrappers and ran the example!\n\nProject created at: ${project_dir}\n\nBuild output:\n${build_result.output}\n\nRun output:\n${run_result.output}'
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
