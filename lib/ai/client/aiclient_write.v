module client

import incubaid.herolib.core.pathlib
import incubaid.herolib.ui.console
import incubaid.herolib.clients.openai
import os

// TODO: do as params for the function

pub fn (mut ac AIClient) write_from_prompt(path_ pathlib.Path, prompt string, models []LLMEnum) ! {
	mut mypath := path_
	original_content := mypath.read()!
	mut backup_path := pathlib.get_file(path: '${mypath.path}.backup', create: true)!
	backup_path.write(original_content)!

	mut selected_models := models.clone()
	if selected_models.len == 0 {
		selected_models = [.best] // Default to best model if none provided
	}

	for model_enum in selected_models {
		model_name, base_url := llm_to_model_url(model_enum)!
		mut llm_client := openai.get(name: model_enum.str())! // Assuming model_enum.str() matches the name used in llms_init

		// 3. Use first model (or default best) to process prompt
		// This part needs to be implemented based on how the OpenAI client's chat completion works
		// For now, let's assume a simple completion call
		// This is a placeholder and needs actual implementation based on the OpenAI client's chat completion method
		// For example:
		// completion := llm_client.chat_completion(prompt)!
		// instructions := completion.choices[0].message.content

		// For now, let's just use the prompt as the "instructions" for modification
		instructions := prompt

		// 5. Use morph model to merge original + instructions
		// This is a placeholder for the merging logic
		// For now, let's just replace the content with instructions
		new_content := instructions // This needs to be replaced with actual merging logic

		// 6. Validate content based on file extension
		mut validation_error := ''
		match mypath.ext()! {
			'.v' {
				validation_error = validate_vlang_content(mypath)!
			}
			'.md' {
				validation_error = validate_markdown_content(mypath)!
			}
			'.yaml', '.yml' {
				validation_error = validate_yaml_content(mypath)!
			}
			'.json' {
				validation_error = validate_json_content(mypath)!
			}
			else {
				// No specific validation for other file types
			}
		}

		if validation_error == '' {
			// Validation passed - write new content
			mypath.write(new_content)!
			backup_path.delete()! // Remove backup on success
			return
		} else {
			console.print_stderr('Validation failed for model ${model_name}. Error: ${validation_error}. Trying next model...')
		}
	}

	// 8. If all fail, restore .backup and error
	original_backup := backup_path.read()!
	mypath.write(original_backup)!
	backup_path.delete()!
	return error('All models failed to generate valid content. Original file restored.')
}
