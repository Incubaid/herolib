#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.openai
import incubaid.herolib.core.playcmds

playcmds.run(
	heroscript: '
        !!openai.configure name:"default" 
            url:"https://openrouter.ai/api/v1" 
            model_default:"gpt-oss-120b"
        '
	reset:      false
)!

// Get the client instance
mut client := openai.get() or {
	eprintln('Failed to get client: ${err}')
	return
}

println(client.list_models()!)

println('Sending message to OpenRouter...\n')

// Simple hello message
response := client.chat_completion(
	model:                 'qwen/qwen-2.5-coder-32b-instruct'
	message:               'Say hello in a friendly way!'
	temperature:           0.7
	max_completion_tokens: 100
) or {
	eprintln('Failed to get completion: ${err}')
	return
}

println('Response from AI:')
println('─'.repeat(50))
println(response.result)
println('─'.repeat(50))
println('\nTokens used: ${response.usage.total_tokens}')
println('  - Prompt: ${response.usage.prompt_tokens}')
println('  - Completion: ${response.usage.completion_tokens}')
