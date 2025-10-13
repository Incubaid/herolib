module escalayer

import log
import incubaid.herolib.clients.openai

// UnitTask represents a single step in the task
pub struct UnitTask {
pub mut:
	name              string
	prompt_function   fn (string) string
	callback_function fn (string) !string
	base_model        ModelConfig
	retry_model       ModelConfig
	retry_count       int
}

// Execute the unit task
pub fn (mut ut UnitTask) execute(input string) !string {
	// Generate the prompt using the prompt function
	prompt := ut.prompt_function(input)

	// Try with the base model first
	mut current_model := ut.base_model
	mut attempts := 0
	mut max_attempts := ut.retry_count + 1 // +1 for the initial attempt
	mut absolute_max_attempts := 1 // Hard limit on total attempts
	mut last_error := ''

	for attempts < max_attempts && attempts < absolute_max_attempts {
		attempts++

		// If we've exhausted retries with the base model, switch to the retry model
		if attempts > ut.retry_count {
			log.error('Escalating to more powerful model: ${ut.retry_model.name}')
			current_model = ut.retry_model
			// Calculate remaining attempts but don't exceed absolute max
			max_attempts = attempts + ut.retry_count
			if max_attempts > absolute_max_attempts {
				max_attempts = absolute_max_attempts
			}
		}

		log.error('Attempt ${attempts} with model ${current_model.name}')

		// Prepare the prompt with error feedback if this is a retry
		mut current_prompt := prompt
		if last_error != '' {
			current_prompt = 'Previous attempt failed with error: ${last_error}\n\n${prompt}'
		}

		// Call the AI model
		response := call_ai_model(current_prompt, current_model) or {
			log.error('AI call failed: ${err}')
			last_error = err.str()
			continue // Try again
		}

		// Process the response with the callback function
		result := ut.callback_function(response) or {
			// If callback returns an error, retry with the error message
			log.error('Callback returned error: ${err}')
			last_error = err.str()
			continue // Try again
		}

		// If we get here, the callback was successful
		return result
	}

	return error('Failed to execute unit task after ${attempts} attempts. Last error: ${last_error}')
}
