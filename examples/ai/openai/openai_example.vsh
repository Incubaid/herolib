#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.openai
import incubaid.herolib.core.playcmds

// Configure OpenAI client to use OpenRouter
playcmds.run(
	heroscript: '
		!!openai.configure
			name: "default"
			url: "https://openrouter.ai/api/v1"
			model_default: "qwen/qwen-2.5-coder-32b-instruct"
	'
)!

// Get the client instance
mut client := openai.get()!

println('🤖 OpenRouter Client Example (using OpenAI client)')
println('═'.repeat(50))
println('')

// Example 1: Simple message
println('Example 1: Simple Hello')
println('─'.repeat(50))
mut r := client.chat_completion(
	model:                 'qwen/qwen-2.5-coder-32b-instruct'
	message:               'Say hello in a creative way!'
	temperature:           0.7
	max_completion_tokens: 150
)!

println('AI: ${r.result}')
println('Tokens: ${r.usage.total_tokens}\n')

// Example 2: Conversation with system prompt
println('Example 2: Conversation with System Prompt')
println('─'.repeat(50))
r = client.chat_completion(
	model:                 'qwen/qwen-2.5-coder-32b-instruct'
	messages:              [
		openai.Message{
			role:    .system
			content: 'You are a helpful coding assistant who speaks concisely.'
		},
		openai.Message{
			role:    .user
			content: 'What is V programming language?'
		},
	]
	temperature:           0.3
	max_completion_tokens: 200
)!

println('AI: ${r.result}')
println('Tokens: ${r.usage.total_tokens}\n')

println('═'.repeat(50))
println('✓ Examples completed successfully!')
