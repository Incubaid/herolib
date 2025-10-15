module escalayer

import incubaid.herolib.clients.openai
import incubaid.herolib.osal.core as osal
import os

// Get an OpenAI client configured for OpenRouter
fn get_openrouter_client() !&openai.OpenAI {
	osal.env_set(key: 'OPENROUTER_API_KEY', value: '')
	// Get API key from environment variable
	api_key := os.getenv('OPENROUTER_API_KEY')
	if api_key == '' {
		return error('OPENROUTER_API_KEY environment variable not set')
	}

	// Create OpenAI client with OpenRouter base URL
	mut client := openai.get(
		name: 'openrouter'
	)!

	return client
}
