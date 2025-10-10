#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.ai.mcp.aitools.escalayer
import os

fn main() {
	// Get the current directory where this script is located
	current_dir := os.dir(@FILE)

	// Validate command line arguments
	source_code_path := validate_command_args() or {
		println(err)
		return
	}

	// Read and combine all Rust files in the source directory
	source_code := read_source_code(source_code_path) or {
		println(err)
		return
	}

	// Determine the crate path from the source code path
	crate_path := determine_crate_path(source_code_path) or {
		println(err)
		return
	}

	// Extract the module name from the directory path (last component)
	name := extract_module_name_from_path(source_code_path)

	// Create the prompt content for the AI
	prompt_content := create_rhai_wrappers(name, source_code, read_file_safely('${current_dir}/prompts/example_script.md'),
		read_file_safely('${current_dir}/prompts/wrapper.md'), read_file_safely('${current_dir}/prompts/errors.md'),
		crate_path)

	// Create the generator instance
	gen := RhaiGen{
		name: name
		dir:  source_code_path
	}

	// Run the task to generate Rhai wrappers
	run_wrapper_generation_task(prompt_content, gen) or {
		println('Task failed: ${err}')
		return
	}

	println('Task completed successfully')
	println('The wrapper files have been generated and compiled in the target directory.')
	println('Check /Users/timurgordon/code/git.threefold.info/herocode/sal/src/rhai for the compiled output.')
}

// Validates command line arguments and returns the source code path
fn validate_command_args() !string {
	if os.args.len < 2 {
		return error('Please provide the path to the source code directory as an argument\nExample: ./example.vsh /path/to/source/code/directory')
	}

	source_code_path := os.args[1]

	if !os.exists(source_code_path) {
		return error('Source code path does not exist: ${source_code_path}')
	}

	if !os.is_dir(source_code_path) {
		return error('Source code path is not a directory: ${source_code_path}')
	}

	return source_code_path
}

// Reads and combines all Rust files in the given directory
fn read_source_code(source_code_path string) !string {
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
fn determine_crate_path(source_code_path string) !string {
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
fn extract_module_name_from_path(path string) string {
	dir_parts := path.split('/')
	return dir_parts[dir_parts.len - 1]
}

// Helper function to read a file or return empty string if file doesn't exist
fn read_file_safely(file_path string) string {
	return os.read_file(file_path) or { '' }
}

// Runs the task to generate Rhai wrappers
fn run_wrapper_generation_task(prompt_content string, gen RhaiGen) !string {
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

	// Create a prompt function that returns the prepared content
	prompt_function := fn [prompt_content] (input string) string {
		return prompt_content
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
	return task.initiate('')
}

// Define a Rhai wrapper generator function for Container functions
fn create_rhai_wrappers(name string, source_code string, example_rhai string, wrapper_md string, errors_md string, crate_path string) string {
	// Load all required template and guide files
	guides := load_guide_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhaiwrapping_classicai.md')
	engine := $tmpl('./prompts/engine.md')
	vector_vs_array := load_guide_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhai_array_vs_vector.md')
	rhai_integration_fixes := load_guide_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhai_integration_fixes.md')
	rhai_syntax_guide := load_guide_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhai_syntax_guide.md')
	generic_wrapper_rs := $tmpl('./templates/generic_wrapper.rs')

	// Build the prompt content
	return build_prompt_content(name, source_code, example_rhai, wrapper_md, errors_md,
		guides, vector_vs_array, rhai_integration_fixes, rhai_syntax_guide, generic_wrapper_rs,
		engine)
}

// Helper function to load guide files with error handling
fn load_guide_file(path string) string {
	return os.read_file(path) or {
		eprintln('Warning: Failed to read guide file: ${path}')
		return ''
	}
}

// Builds the prompt content for the AI
fn build_prompt_content(name string, source_code string, example_rhai string, wrapper_md string,
	errors_md string, guides string, vector_vs_array string,
	rhai_integration_fixes string, rhai_syntax_guide string,
	generic_wrapper_rs string, engine string) string {
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
import package being wrapped as `use sal::<n>`
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

// RhaiGen struct for generating Rhai wrappers
struct RhaiGen {
	name string
	dir  string
}

// Process the AI response and compile the generated code
fn (gen RhaiGen) process_rhai_wrappers(response string) !string {
	// Extract code blocks from the response
	code_blocks := extract_code_blocks(response) or { return err }

	// Extract function names from the wrapper.rs content
	functions := extract_functions_from_code(code_blocks.wrapper_rs)

	println('Using module name: ${gen.name}_rhai')
	println('Extracted functions: ${functions.join(', ')}')

	name := gen.name

	// Create a WrapperModule struct with the extracted content
	wrapper := WrapperModule{
		lib_rs:             $tmpl('./templates/lib.rs')
		wrapper_rs:         code_blocks.wrapper_rs
		example_rs:         $tmpl('./templates/example.rs')
		engine_rs:          code_blocks.engine_rs
		generic_wrapper_rs: $tmpl('./templates/generic_wrapper.rs')
		cargo_toml:         $tmpl('./templates/cargo.toml')
		example_rhai:       code_blocks.example_rhai
	}

	// Create the wrapper module
	project_dir := create_wrapper_module(wrapper, functions, gen.name, gen.dir) or {
		return error('Failed to create wrapper module: ${err}')
	}

	// Build and run the project
	build_output, run_output := build_and_run_project(project_dir) or { return err }

	return format_success_message(project_dir, build_output, run_output)
}

// CodeBlocks struct to hold extracted code blocks
struct CodeBlocks {
	wrapper_rs   string
	engine_rs    string
	example_rhai string
}

// Extract code blocks from the AI response
fn extract_code_blocks(response string) !CodeBlocks {
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
	}

	// Extract example.rhai content
	mut example_rhai_content := extract_code_block(response, 'example.rhai', 'rhai')
	if example_rhai_content == '' {
		// Try to extract from the response without explicit language marker
		example_rhai_content = extract_code_block(response, 'example.rhai', '')
		if example_rhai_content == '' {
			// Use the example from the template
			example_rhai_content = load_example_from_template() or { return err }
		}
	}

	return CodeBlocks{
		wrapper_rs:   wrapper_rs_content
		engine_rs:    engine_rs_content
		example_rhai: example_rhai_content
	}
}

// Load example.rhai from template file
fn load_example_from_template() !string {
	example_script_md := os.read_file('${os.dir(@FILE)}/prompts/example_script.md') or {
		return error('Failed to read example.rhai template: ${err}')
	}

	// Extract the code block from the markdown file
	example_rhai_content := extract_code_block(example_script_md, 'example.rhai', 'rhai')
	if example_rhai_content == '' {
		return error('Failed to extract example.rhai from template file')
	}

	return example_rhai_content
}

// Build and run the project
fn build_and_run_project(project_dir string) !(string, string) {
	// Change to the project directory
	os.chdir(project_dir) or { return error('Failed to change directory to project: ${err}') }

	// Run cargo build first
	build_result := os.execute('cargo build')
	if build_result.exit_code != 0 {
		return error('Compilation failed. Please fix the following errors and ensure your code is compatible with the existing codebase:\n\n${build_result.output}')
	}

	// Run the example
	run_result := os.execute('cargo run --example example')

	return build_result.output, run_result.output
}

// Format success message
fn format_success_message(project_dir string, build_output string, run_output string) string {
	return 'Successfully generated Rhai wrappers and ran the example!\n\nProject created at: ${project_dir}\n\nBuild output:\n${build_output}\n\nRun output:\n${run_output}'
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
