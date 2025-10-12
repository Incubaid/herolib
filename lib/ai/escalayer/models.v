module escalayer

import incubaid.herolib.clients.openai

// ModelConfig defines the configuration for an AI model
pub struct ModelConfig {
pub mut:
	name        string
	provider    string
	temperature f32
	max_tokens  int
}

// Create model configs
const claude_3_sonnet = ModelConfig{
	name:        'anthropic/claude-3.7-sonnet'
	provider:    'anthropic'
	temperature: 0.7
	max_tokens:  25000
}

const gpt4 = ModelConfig{
	name:        'gpt-4'
	provider:    'openai'
	temperature: 0.7
	max_tokens:  25000
}

// Call an AI model using OpenRouter
fn call_ai_model(prompt string, model ModelConfig) !string {
	// Get OpenAI client (configured for OpenRouter)
	mut client := get_openrouter_client()!

	// Create the message for the AI
	mut m := openai.Messages{
		messages: [
			openai.Message{
				role:    .system
				content: 'You are a helpful assistant.'
			},
			openai.Message{
				role:    .user
				content: prompt
			},
		]
	}

	// Call the AI model
	res := client.chat_completion(
		msgs:                  m
		model:                 model.name
		temperature:           model.temperature
		max_completion_tokens: model.max_tokens
	)!

	// Extract the response content
	if res.choices.len > 0 {
		return res.choices[0].message.content
	}

	return error('No response from AI model')
}
