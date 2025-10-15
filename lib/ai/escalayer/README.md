# Escalayer

Escalayer is a module for executing AI tasks with automatic escalation to more powerful models when needed. It provides a framework for creating complex AI workflows by breaking them down into sequential unit tasks.

## Overview

Escalayer allows you to:

1. Create complex AI tasks composed of multiple sequential unit tasks
2. Execute each unit task with a cheap AI model first
3. Automatically retry with a more powerful model if the task fails
4. Process and validate AI responses with custom callback functions

## Architecture

The module is organized into the following components:

- **Task**: Represents a complete AI task composed of multiple sequential unit tasks
- **UnitTask**: Represents a single step in the task with prompt generation and response processing
- **ModelConfig**: Defines the configuration for an AI model
- **OpenRouter Integration**: Uses OpenRouter to access a wide range of AI models

## Usage

### Basic Example

```v
import incubaid.herolib.ai.mcp.aitools.escalayer

fn main() {
    // Create a new task
    mut task := escalayer.new_task(
        name: 'rhai_wrapper_creator'
        description: 'Create Rhai wrappers for Rust functions'
    )
    
    // Define the unit tasks
    task.new_unit_task(
        name: 'separate_functions'
        prompt_function: separate_functions
        callback_function: process_functions
    )
    
    // Initiate the task
    result := task.initiate('path/to/rust/file.rs') or {
        println('Task failed: ${err}')
        return
    }
    
    println('Task completed successfully')
    println(result)
}

// Define the prompt function
fn separate_functions(input string) string {
    return 'Read rust file and separate it into functions ${input}'
}

// Define the callback function
fn process_functions(response string)! string {
    // Process the AI response
    // Return error if processing fails
    if response.contains('error') {
        return error('Failed to process functions: Invalid response format')
    }
    return response
}
```

### Advanced Configuration

You can configure each unit task with different models, retry counts, and other parameters:

```v
// Configure with custom parameters
task.new_unit_task(
    name: 'create_wrappers'
    prompt_function: create_wrappers
    callback_function: process_wrappers
    retry_count: 2
    base_model: escalayer.ModelConfig{
        name: 'claude-3-haiku-20240307'
        provider: 'anthropic'
        temperature: 0.5
        max_tokens: 4000
    }
)
```

## How It Works

1. When you call `task.initiate(input)`, the first unit task is executed with its prompt function.
2. The prompt is sent to the base AI model.
3. The response is processed by the callback function.
4. If the callback returns an error, the task is retried with the same model.
5. After a specified number of retries, the task escalates to a more powerful model.
6. Once a unit task succeeds, its result is passed as input to the next unit task.
7. This process continues until all unit tasks are completed.

## Environment Setup

Escalayer uses OpenRouter for AI model access. Set the following environment variable:

```
OPENROUTER_API_KEY=your_api_key_here
```

You can get an API key from [OpenRouter](https://openrouter.ai/).

## Original Requirements

This module was designed based on the following requirements:

- Create a system for executing AI tasks with a retry mechanism
- Escalate to more powerful models if cheaper models fail
- Use OpenAI client over OpenRouter for AI calls
- Break down complex tasks into sequential unit tasks
- Each unit task has a function that generates a prompt and a callback that processes the response
- Retry if the callback returns an error, with the error message prepended to the input string

For a detailed architecture overview, see [escalayer_architecture.md](./escalayer_architecture.md).

For a complete example, see [example.v](../servers/rhai).
