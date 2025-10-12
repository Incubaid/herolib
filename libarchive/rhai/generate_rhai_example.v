module rhai

import log
import incubaid.herolib.ai.escalayer

pub struct WrapperGenerator {
pub:
	function string
	structs  []string
}

// given a list of rhai functions and structs, generate a Rhai example script
pub fn generate_rhai_example(functions []string, structs []string) !string {
	mut task := escalayer.new_task(
		name:        'generate_rhai_function_wrapper'
		description: 'Create a single Rhai wrapper for a Rust function'
	)

	mut gen := WrapperGenerator{
		function: functions
		structs:  structs
	}

	// Define a single unit task that handles everything
	task.new_unit_task(
		name:              'generate_rhai_function_wrapper'
		prompt_function:   gen.generate_rhai_function_wrapper_prompt
		callback_function: gen.generate_rhai_function_wrapper_callback
		base_model:        escalayer.claude_3_sonnet // Use actual model identifier
		retry_model:       escalayer.claude_3_sonnet // Use actual model identifier
		retry_count:       2
	)

	return task.initiate('')
}

pub fn (gen WrapperGenerator) generate_rhai_function_wrapper_prompt(input string) string {
	return $tmpl('./prompts/generate_rhai_function_wrapper.md')
}

// generate_rhai_function_wrapper_callback validates the generated Rhai wrapper.
//
// Args:
//     rhai_wrapper (string): The generated wrapper code.
//
// Returns:
//     !string: The validated wrapper code or an error.
pub fn (gen WrapperGenerator) generate_rhai_function_wrapper_callback(output string) !string {
	verify_rhai_wrapper(gen.function, gen.structs, output) or {
		log.error('Failed to verify, will retry ${err}')
		return err
	}
	return output
}
