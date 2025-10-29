# OpenRouter V Client

A V client for the OpenRouter API, providing access to multiple AI models through a unified interface.

## Quick Start

```v
import incubaid.herolib.clients.openrouter
import incubaid.herolib.core.playcmds

// Configure client (key can be read from env vars)
playcmds.run(
    heroscript: '
        !!openrouter.configure name:"default"
            key:"${YOUR_OPENROUTER_KEY}"
            url:"https://openrouter.ai/api/v1"
            model_default:"qwen/qwen-2.5-coder-32b-instruct"
        '
    reset: false
)!

mut client := openrouter.get()!

// Simple chat example
resp := client.chat_completion(
    model: "qwen/qwen-2.5-coder-32b-instruct"
    message: "Hello, world!"
    temperature: 0.6
)!

println('Answer: ${resp.result}')
```

## Environment Variables

The client automatically reads API keys from environment variables if not explicitly configured:

- `OPENROUTER_API_KEY` - OpenRouter API key
- `AIKEY` - Alternative API key variable
- `AIURL` - API base URL (defaults to `https://openrouter.ai/api/v1`)
- `AIMODEL` - Default model (defaults to `qwen/qwen-2.5-coder-32b-instruct`)

## Example with Multiple Messages

```v
import incubaid.herolib.clients.openrouter

mut client := openrouter.get()!

resp := client.chat_completion(
    messages: [
        openrouter.Message{
            role: .system
            content: 'You are a helpful coding assistant.'
        },
        openrouter.Message{
            role: .user
            content: 'Write a hello world in V'
        },
    ]
    temperature: 0.3
    max_completion_tokens: 1024
)!

println(resp.result)
```

## Configuration via Heroscript

```hero
!!openrouter.configure
    name: "default"
    key: "sk-or-v1-..."
    url: "https://openrouter.ai/api/v1"
    model_default: "qwen/qwen-2.5-coder-32b-instruct"
```

## Features

- **Chat Completion**: Generate text completions using various AI models
- **Multiple Models**: Access to OpenRouter's extensive model catalog
- **Environment Variable Support**: Automatic configuration from environment
- **Factory Pattern**: Manage multiple client instances
- **Retry Logic**: Built-in retry mechanism for failed requests

## Available Models

OpenRouter provides access to many models including:

- `qwen/qwen-2.5-coder-32b-instruct` - Qwen 2.5 Coder (default)
- `anthropic/claude-3.5-sonnet`
- `openai/gpt-4-turbo`
- `google/gemini-pro`
- `meta-llama/llama-3.1-70b-instruct`
- And many more...

Check the [OpenRouter documentation](https://openrouter.ai/docs) for the full list of available models.
