module logic

import freeflowuniverse.herolib.ai.escalayer
import freeflowuniverse.herolib.lang.rust
import freeflowuniverse.herolib.ai.utils
import os

pub fn generate_rhai_wrapper(name string, source_path string) !string {
	// Detect source package and module information
	source_pkg_info := rust.detect_source_package(source_path)!
	source_code := rust.read_source_code(source_path)!
	prompt := rhai_wrapper_generation_prompt(name, source_code, source_pkg_info)!
	return run_wrapper_generation_task(prompt, RhaiGen{
		name:            name
		dir:             source_path
		source_pkg_info: source_pkg_info
	})!
}

// Runs the task to generate Rhai wrappers
pub fn run_wrapper_generation_task(prompt_content string, gen RhaiGen) !string {
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
pub fn rhai_wrapper_generation_prompt(name string, source_code string, source_pkg_info rust.SourcePackageInfo) !string {
	current_dir := os.dir(@FILE)
	example_rhai := os.read_file('${current_dir}/prompts/example_script.md')!
	wrapper_md := os.read_file('${current_dir}/prompts/wrapper.md')!
	errors_md := os.read_file('${current_dir}/prompts/errors.md')!

	// Load all required template and guide files
	guides := os.read_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhaiwrapping_classicai.md')!
	engine := $tmpl('./prompts/engine.md')
	vector_vs_array := os.read_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhai_array_vs_vector.md')!
	rhai_integration_fixes := os.read_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhai_integration_fixes.md')!
	rhai_syntax_guide := os.read_file('/Users/timurgordon/code/git.threefold.info/herocode/sal/aiprompts/rhai_syntax_guide.md')!
	generic_wrapper_rs := $tmpl('./templates/generic_wrapper.rs')

	prompt := $tmpl('./prompts/main.md')
	return prompt
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
pub fn write_rhai_wrapper_module(wrapper WrapperModule, name string, path string) !string {
	// Define project directory paths
	project_dir := '${path}/rhai'

	// Create the project using cargo new --lib
	if os.exists(project_dir) {
		os.rmdir_all(project_dir) or {
			return error('Failed to clean existing project directory: ${err}')
		}
	}

	// Run cargo new --lib to create the project
	os.chdir(path) or { return error('Failed to change directory to base directory: ${err}') }

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
	} else {
		// Use default lib.rs template if none provided
		lib_rs_content := $tmpl('./templates/lib.rs')
		os.write_file('${project_dir}/src/lib.rs', lib_rs_content) or {
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
	} else {
		// Use default example.rs template if none provided
		example_rs_content := $tmpl('./templates/example.rs')
		os.write_file('${examples_dir}/example.rs', example_rs_content) or {
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
	os.write_file('${project_dir}/Cargo.toml', wrapper.cargo_toml) or {
		return error('Failed to write Cargo.toml: ${err}')
	}

	// Write the example.rhai file
	os.write_file('${examples_dir}/example.rhai', wrapper.example_rhai) or {
		return error('Failed to write example.rhai: ${err}')
	}

	return project_dir
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
	name            string
	dir             string
	source_pkg_info rust.SourcePackageInfo
}

// Process the AI response and compile the generated code
pub fn (gen RhaiGen) process_rhai_wrappers(input string) !string {
	blocks := extract_code_blocks(input)!
	source_pkg_info := gen.source_pkg_info
	// Create the module structure
	mod := WrapperModule{
		lib_rs:             blocks.lib_rs
		engine_rs:          blocks.engine_rs
		example_rhai:       blocks.example_rhai
		generic_wrapper_rs: $tmpl('./templates/generic_wrapper.rs')
		wrapper_rs:         blocks.wrapper_rs
	}

	// Write the module files
	project_dir := write_rhai_wrapper_module(mod, gen.name, gen.dir)!

	return project_dir
}

// CodeBlocks struct to hold extracted code blocks
struct CodeBlocks {
	wrapper_rs   string
	engine_rs    string
	example_rhai string
	lib_rs       string
}

// Extract code blocks from the AI response
fn extract_code_blocks(response string) !CodeBlocks {
	// Extract wrapper.rs content
	wrapper_rs_content := utils.extract_code_block(response, 'wrapper.rs', 'rust')
	if wrapper_rs_content == '' {
		return error('Failed to extract wrapper.rs content from response. Please ensure your code is properly formatted inside a code block that starts with ```rust\n// wrapper.rs and ends with ```')
	}

	// Extract engine.rs content
	mut engine_rs_content := utils.extract_code_block(response, 'engine.rs', 'rust')
	if engine_rs_content == '' {
		// Try to extract from the response without explicit language marker
		engine_rs_content = utils.extract_code_block(response, 'engine.rs', '')
	}

	// Extract example.rhai content
	mut example_rhai_content := utils.extract_code_block(response, 'example.rhai', 'rhai')
	if example_rhai_content == '' {
		// Try to extract from the response without explicit language marker
		example_rhai_content = utils.extract_code_block(response, 'example.rhai', '')
		if example_rhai_content == '' {
			return error('Failed to extract example.rhai content from response. Please ensure your code is properly formatted inside a code block that starts with ```rhai\n// example.rhai and ends with ```')
		}
	}

	// Extract lib.rs content
	lib_rs_content := utils.extract_code_block(response, 'lib.rs', 'rust')
	if lib_rs_content == '' {
		return error('Failed to extract lib.rs content from response. Please ensure your code is properly formatted inside a code block that starts with ```rust\n// lib.rs and ends with ```')
	}

	return CodeBlocks{
		wrapper_rs:   wrapper_rs_content
		engine_rs:    engine_rs_content
		example_rhai: example_rhai_content
		lib_rs:       lib_rs_content
	}
}

// Format success message
fn format_success_message(project_dir string, build_output string, run_output string) string {
	return 'Successfully generated Rhai wrappers and ran the example!\n\nProject created at: ${project_dir}\n\nBuild output:\n${build_output}\n\nRun output:\n${run_output}'
}
