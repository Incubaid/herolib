# openai

The OpenAI client library provides a comprehensive interface for interacting with OpenAI and OpenAI-compatible APIs (like OpenRouter and Groq).

## Quick Start

### Using Environment Variables

The easiest way to configure the OpenAI client is through environment variables:

```bash
export AIKEY='your-api-key-here'
export AIURL='https://api.openai.com/v1'  # optional, defaults to OpenRouter
export AIMODEL='gpt-4o'                    # optional, sets default model
```

Supported environment variables:

- `AIKEY` - Your API key (fallback for all providers)
- `AIURL` - The API base URL
- `AIMODEL` - Default model to use
- `OPENROUTER_API_KEY` - OpenRouter specific API key (preferred for OpenRouter)
- `GROQKEY` - Groq specific API key (preferred for Groq)

### Basic Usage

```v
import incubaid.herolib.clients.openai

// Get the default client (uses AIKEY from environment)
mut client := openai.get()!

// Send a simple message
response := client.chat_completion(
    message: 'Hello, world!'
    temperature: 0.7
    max_completion_tokens: 1024
)!

println(response.result)
```

## Configuration with HeroScript

For more control, use HeroScript configuration:

```v
import incubaid.herolib.clients.openai
import incubaid.herolib.core.playcmds

playcmds.run(
    heroscript: '
        !!openai.configure name:"default" 
            url:"https://openrouter.ai/api/v1" 
            api_key:"sk-or-v1-..." 
            model_default:"gpt-oss-120b"
    '
    reset: false
)!

mut client := openai.get()!
```

in case of using heroscript, we don't have to fill in the api_key it will be loaded from the environment variable `OPENROUTER_API_KEY` or `GROQKEY` depending on the url used.

## Examples

### Using OpenRouter

```v
#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.openai
import incubaid.herolib.core.playcmds

playcmds.run(
    heroscript: '
        !!openai.configure name:"default" 
            url:"https://openrouter.ai/api/v1" 
            model_default:"gpt-oss-120b"
    '
    reset: false
)!

mut client := openai.get()!

response := client.chat_completion(
    model: 'qwen/qwen-2.5-coder-32b-instruct'
    message: 'Write a hello world program in V'
    temperature: 0.7
    max_completion_tokens: 500
)!

println('Response:')
println(response.result)
println('Tokens used: ${response.usage.total_tokens}')
```

### Using Groq

```bash
export GROQKEY='gsk_...'

```v
import incubaid.herolib.clients.openai
import incubaid.herolib.core.playcmds

playcmds.run(
    heroscript: '
        !!openai.configure name:"qroq" 
            url:"https://api.groq.com/openai/v1" 
            model_default:"gpt-oss-120b"
    '
    reset: true
)!

mut client := openai.get(name:"groq")!

response := client.chat_completion(
    message: 'Explain quantum computing in simple terms'
    temperature: 0.5
    max_completion_tokens: 1024
)!

println(response.result)
```

## Chat Completion

### Simple Message

```v
mut client := openai.get()!

response := client.chat_completion(
    message: 'What is 2 + 2?'
)!

println(response.result)
```

### Multi-Message Conversation

```v
response := client.chat_completion(
    model: 'gpt-4o'
    messages: [
        Message{
            role: .system
            content: 'You are a helpful programming assistant.'
        },
        Message{
            role: .user
            content: 'How do I read a file in V?'
        },
    ]
    temperature: 0.7
    max_completion_tokens: 2048
)!

println(response.result)
```

## Features

- **Chat Completions** - Generate text responses
- **Image Generation** - Create, edit, and generate variations of images
- **Audio** - Transcribe and translate audio files
- **Embeddings** - Generate text embeddings
- **File Management** - Upload and manage files for fine-tuning
- **Fine-tuning** - Create and manage fine-tuned models
- **Content Moderation** - Check content for policy violations
- **Multiple Providers** - Works with OpenAI, OpenRouter, Groq, and compatible APIs

## Advanced Usage: Coding Agent

Here's an example of building a coding assistant agent:

```v
#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.openai
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools

fn analyze_code(mut client openai.OpenAI, code string) !string {
	response := client.chat_completion(
		messages: [
			openai.Message{
				role: .system
				content: 'You are an expert code analyzer. Analyze code and provide:
					1. Code quality issues
					2. Performance suggestions
					3. Security concerns
					4. Refactoring recommendations'
			},
			openai.Message{
				role: .user
				content: 'Analyze this code:\n\`\`\`\n${code}\n\`\`\`'
			},
		]
		temperature: 0.3
		max_completion_tokens: 2048
	)!
	return response.result
}

fn generate_code(mut client openai.OpenAI, requirement string, language string) !string {
	response := client.chat_completion(
		messages: [
			openai.Message{
				role: .system
				content: 'You are an expert ${language} programmer. Generate clean, efficient, 
					well-documented code. Include comments and error handling.'
			},
			openai.Message{
				role: .user
				content: 'Generate ${language} code for: ${requirement}'
			},
		]
		temperature: 0.5
		max_completion_tokens: 2048
	)!
	return response.result
}

fn test_code(mut client openai.OpenAI, code string, language string) !string {
	response := client.chat_completion(
		messages: [
			openai.Message{
				role: .system
				content: 'You are an expert ${language} test engineer. Generate comprehensive 
					unit tests with good coverage.'
			},
			openai.Message{
				role: .user
				content: 'Write tests for this ${language} code:\n\`\`\`\n${code}\n\`\`\`'
			},
		]
		temperature: 0.4
		max_completion_tokens: 2048
	)!
	return response.result
}

fn refactor_code(mut client openai.OpenAI, code string, language string) !string {
	response := client.chat_completion(
		messages: [
			openai.Message{
				role: .system
				content: 'You are an expert code refactorer. Improve code readability, 
					maintainability, and follow best practices for ${language}.'
			},
			openai.Message{
				role: .user
				content: 'Refactor this ${language} code:\n\`\`\`\n${code}\n\`\`\`'
			},
		]
		temperature: 0.3
		max_completion_tokens: 2048
	)!
	return response.result
}

// Main coding agent loop
fn main() ! {
	mut client := openai.get()!
	mut console := console.new()

	println('═'.repeat(60))
	println('  Coding Agent - Your AI Programming Assistant')
	println('═'.repeat(60))

	loop {
		action := console.ask_dropdown(
			description: 'What would you like to do?'
			items: ['Generate Code', 'Analyze Code', 'Generate Tests', 'Refactor Code', 'Exit']
		)!

		match action {
			'Generate Code' {
				requirement := console.ask_question(
					description: 'Code Generation'
					question: 'What code do you need? (describe the requirement)'
				)!

				language := console.ask_dropdown(
					description: 'Programming Language'
					items: ['V', 'Python', 'JavaScript', 'Rust', 'Go', 'C++']
				)!

				println('\n⏳ Generating code...\n')
				generated := generate_code(mut client, requirement, language)!
				
				console.cprint(
					text: generated
					foreground: .green
				)
			}
			'Analyze Code' {
				code := console.ask_question(
					description: 'Code Analysis'
					question: 'Paste your code (can be multiline):'
				)!

				println('\n⏳ Analyzing code...\n')
				analysis := analyze_code(mut client, code)!
				
				console.cprint(
					text: analysis
					foreground: .cyan
				)
			}
			'Generate Tests' {
				code := console.ask_question(
					description: 'Test Generation'
					question: 'Paste your code:'
				)!

				language := console.ask_dropdown(
					description: 'Programming Language'
					items: ['V', 'Python', 'JavaScript', 'Rust', 'Go', 'C++']
				)!

				println('\n⏳ Generating tests...\n')
				tests := test_code(mut client, code, language)!
				
				console.cprint(
					text: tests
					foreground: .yellow
				)
			}
			'Refactor Code' {
				code := console.ask_question(
					description: 'Code Refactoring'
					question: 'Paste your code:'
				)!

				language := console.ask_dropdown(
					description: 'Programming Language'
					items: ['V', 'Python', 'JavaScript', 'Rust', 'Go', 'C++']
				)!

				println('\n⏳ Refactoring code...\n')
				refactored := refactor_code(mut client, code, language)!
				
				console.cprint(
					text: refactored
					foreground: .green
				)
			}
			'Exit' {
				println('\n👋 Goodbye!')
				break
			}
			else {
				println('Invalid option')
			}
		}

		println('\n')
	}
}
```

## Supported Providers

- **OpenAI** - `https://api.openai.com/v1`
- **OpenRouter** - `https://openrouter.ai/api/v1` (default)
- **Groq** - `https://api.groq.com/openai/v1`
- **Compatible APIs** - Any OpenAI-compatible endpoint