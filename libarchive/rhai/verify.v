module rhai

import incubaid.herolib.core.texttools
// import strings // No longer needed directly here
import incubaid.herolib.lang.rust
import os

// Helper to extract the primary struct name from declarations
fn get_primary_struct_name(struct_declarations []string) string {
	if struct_declarations.len == 0 {
		return ''
	}
	// Simple extraction: assumes first line is `pub struct Name {` or `struct Name {`
	first_line := struct_declarations[0].trim_space()
	if first_line.starts_with('pub struct ') {
		name_part := first_line.all_after('pub struct ')
		return name_part.all_before('{').trim_space()
	} else if first_line.starts_with('struct ') {
		name_part := first_line.all_after('struct ')
		return name_part.all_before('{').trim_space()
	}
	return '' // Couldn't determine name
}

// verify_rhai_wrapper checks if the AI-generated output contains a plausible Rhai wrapper.
// It now uses the struct declarations to check for correct method naming.
fn verify_rhai_wrapper(rust_fn_signature string, struct_declarations []string, generated_output string) ! {
	// 1. Extract Rust code block (same as before)
	mut code_block := ''
	if generated_output.contains('```rust') { // Use contains() for strings
		start_index := generated_output.index('```rust') or { -1 }
		end_index := generated_output.index_after('```', start_index + 7) or { -1 }
		if start_index != -1 && end_index != -1 {
			code_block = generated_output[start_index + 7..end_index].trim_space()
		} else {
			code_block = generated_output.trim_space()
		}
	} else {
		code_block = generated_output.trim_space()
	}
	assert code_block.len > 0, 'Could not extract code block from generated output: \n`${generated_output}`'

	// 2. Determine Original Function Name and Expected Wrapper Name
	//    Ideally, use rust module parsing here, but for now, simple string parsing:
	is_method := rust_fn_signature.contains('&self') || rust_fn_signature.contains('&mut self')
	mut original_fn_name := ''
	sig_parts := rust_fn_signature.split('(')
	if sig_parts.len > 0 {
		name_parts := sig_parts[0].split(' ')
		if name_parts.len > 0 {
			original_fn_name = name_parts.last()
		}
	}
	assert original_fn_name != '', 'Could not extract function name from signature: ${rust_fn_signature}'

	expected_wrapper_fn_name := if is_method {
		struct_name := get_primary_struct_name(struct_declarations)
		assert struct_name != '', 'Could not determine struct name for method: ${rust_fn_signature}'
		'${texttools.snake_case(struct_name)}_${original_fn_name}' // e.g., mystruct_get_name
	} else {
		original_fn_name // Standalone function uses the same name
	}

	// 3. Basic Signature Check (using expected_wrapper_fn_name)
	expected_sig_start := 'pub fn ${expected_wrapper_fn_name}'
	expected_sig_end := '-> Result<'
	expected_sig_very_end := 'Box<EvalAltResult>>'

	assert code_block.contains(expected_sig_start), 'Wrapper missing signature start: `${expected_sig_start}` in\n${code_block}'
	assert code_block.contains(expected_sig_end), 'Wrapper missing signature end: `${expected_sig_end}` in\n${code_block}'
	assert code_block.contains(expected_sig_very_end), 'Wrapper missing signature very end: `${expected_sig_very_end}` in\n${code_block}'

	// 4. Basic Body Check (Check for call to the *original* function name)
	body_start := code_block.index('{') or { -1 }
	body_end := code_block.last_index('}') or { -1 }
	if body_start != -1 && body_end != -1 && body_start < body_end {
		body := code_block[body_start + 1..body_end]
		// Check for call like `original_fn_name(...)` or `receiver.original_fn_name(...)`
		assert body.contains(original_fn_name + '(') || body.contains('.' + original_fn_name + '('), 'Wrapper body does not appear to call original function `${original_fn_name}` in\n${body}'
	} else {
		assert false, 'Could not find function body `{...}` in wrapper:\n${code_block}'
	}
	// If all checks pass, do nothing (implicitly ok)
}
