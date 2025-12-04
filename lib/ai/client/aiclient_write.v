module client

import incubaid.herolib.core.pathlib
import incubaid.herolib.ui.console
import incubaid.herolib.clients.openai
import os

// WritePromptArgs holds the parameters for write_from_prompt function
@[params]
pub struct WritePromptArgs {
pub mut:
	path          pathlib.Path
	prompt        string
	models        []LLMEnum = [.best]
	temperature   f64       = 0.5
	max_tokens    int       = 16000
	system_prompt string    = 'You are a helpful assistant that modifies files based on user instructions.'
}

// write_from_prompt modifies a file based on AI-generated modification instructions
//
// The process:
// 1. Uses the first model to generate modification instructions from the prompt
// 2. Uses the morph model to apply those instructions to the original content
// 3. Validates the result based on file type (.v, .md, .yaml, .json)
// 4. On validation failure, retries with the next model in the list
// 5. Restores from backup if all models fail
pub fn (mut ac AIClient) write_from_prompt(args WritePromptArgs) ! {
	mut mypath := args.path
	original_content := mypath.read()!
	mut backup_path := pathlib.get_file(path: '${mypath.path}.backup', create: true)!
	backup_path.write(original_content)!

	mut selected_models := args.models.clone()
	if selected_models.len == 0 {
		selected_models = [.best]
	}

	for model_enum in selected_models {
		model_name, _ := llm_to_model_url(model_enum)!

		// Step 1: Get modification instructions from the selected model
		// Get the appropriate LLM client for instruction generation
		mut llm_client := get_llm_client(mut ac, model_enum)

		instruction_prompt := generate_instruction_prompt(original_content, mypath.ext()!,
			args.prompt)

		instructions_response := llm_client.chat_completion(
			message:               instruction_prompt
			temperature:           args.temperature
			max_completion_tokens: args.max_tokens
		)!

		instructions := instructions_response.result.trim_space()

		// Step 2: Use morph model to apply instructions to original content
		morph_prompt := generate_morph_prompt(original_content, instructions)

		morph_response := ac.llms.llm_morph.chat_completion(
			message:               morph_prompt
			temperature:           args.temperature
			max_completion_tokens: args.max_tokens
		)!

		new_content := morph_response.result.trim_space()

		// Step 3: Validate content based on file extension
		mut validation_error := ''

		// Create a temporary file for validation
		file_ext := mypath.ext()!
		mut temp_path := pathlib.get_file(
			path:   '${mypath.path}.validate_temp${file_ext}'
			create: true
		)!
		temp_path.write(new_content)!

		match file_ext {
			'.v' {
				validation_error = validate_vlang_content(temp_path)!
			}
			'.md' {
				validation_error = validate_markdown_content(temp_path)!
			}
			'.yaml', '.yml' {
				validation_error = validate_yaml_content(temp_path)!
			}
			'.json' {
				validation_error = validate_json_content(temp_path)!
			}
			else {
				// No specific validation for other file types
			}
		}

		// Clean up temporary validation file
		if temp_path.exists() {
			temp_path.delete()!
		}

		if validation_error == '' {
			// Validation passed - write new content
			mypath.write(new_content)!
			backup_path.delete()! // Remove backup on success
			console.print_stdout('✓ Successfully modified ${mypath.str()} using model ${model_name}')
			return
		} else {
			console.print_stderr('✗ Validation failed for model ${model_name}. Error: ${validation_error}. Trying next model...')
		}
	}

	// Step 4: If all models fail, restore backup and error
	original_backup := backup_path.read()!
	mypath.write(original_backup)!
	backup_path.delete()!
	return error('All models failed to generate valid content. Original file restored from backup.')
}

// get_llm_client returns the appropriate LLM client for the given model enum
fn get_llm_client(mut ac AIClient, model LLMEnum) &openai.OpenAI {
	return match model {
		.maverick { ac.llms.llm_maverick }
		.qwen { ac.llms.llm_qwen }
		.embed { ac.llms.llm_embed }
		.llm_120b { ac.llms.llm_120b }
		.best { ac.llms.llm_best }
		.flash { ac.llms.llm_flash }
		.pro { ac.llms.llm_pro }
		.morph { ac.llms.llm_morph }
		.local { ac.llms.llm_local }
	}
}

// generate_instruction_prompt creates the prompt for generating modification instructions
fn generate_instruction_prompt(content string, file_ext string, user_prompt string) string {
	return 'You are a file modification assistant specializing in ${file_ext} files.

The user will provide a file and a modification request. Your task is to analyze the request and respond with ONLY clear, concise modification instructions.

Do NOT apply the modifications yourself. Just provide step-by-step instructions that could be applied to transform the file.

Original file content:
\`\`\`${file_ext}
${content}
\`\`\`

File type: ${file_ext}

User modification request:
${user_prompt}

Provide only the modification instructions. Be specific and clear. Format your response as a numbered list of changes to make.'
}

// generate_morph_prompt creates the prompt for the morph model to apply instructions
fn generate_morph_prompt(original_content string, instructions string) string {
	return 'You are an expert code and file modifier. Your task is to apply modification instructions to existing file content.

Take the original file content and the modification instructions, then generate the modified version.

IMPORTANT: Return ONLY the modified file content. Do NOT include:
- Markdown formatting or code blocks
- Explanations or commentary
- "Here is the modified file:" prefixes
- Any text other than the actual modified content

Original file content:
\`\`\`
${original_content}
\`\`\`

Modification instructions to apply:
${instructions}

Return the complete modified file content:'
}
