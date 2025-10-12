module escalayer

import incubaid.herolib.clients.openai

// TaskParams defines the parameters for creating a new task
@[params]
pub struct TaskParams {
pub:
	name        string
	description string
}

// Create a new task
pub fn new_task(params TaskParams) &Task {
	return &Task{
		name:           params.name
		description:    params.description
		unit_tasks:     []
		current_result: ''
	}
}

// Default model configurations
pub fn default_base_model() ModelConfig {
	return ModelConfig{
		name:        'qwen2.5-7b-instruct'
		provider:    'openai'
		temperature: 0.7
		max_tokens:  2000
	}
}

pub fn default_retry_model() ModelConfig {
	return ModelConfig{
		name:        'gpt-4'
		provider:    'openai'
		temperature: 0.7
		max_tokens:  4000
	}
}
