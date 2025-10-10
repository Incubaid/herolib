module mcp

import x.json2

pub struct MemoryBackend {
pub mut:
	// Resource related fields
	resources          map[string]Resource
	subscriptions      []string // list of subscribed resource uri's
	resource_contents  map[string][]ResourceContent
	resource_templates map[string]ResourceTemplate

	// Prompt related fields
	prompts         map[string]Prompt
	prompt_messages map[string][]PromptMessage
	prompt_handlers map[string]PromptHandler

	// Tool related fields
	tools         map[string]Tool
	tool_handlers map[string]ToolHandler
}

pub type ToolHandler = fn (arguments map[string]json2.Any) !ToolCallResult

pub type PromptHandler = fn (arguments []string) ![]PromptMessage

fn (b &MemoryBackend) resource_exists(uri string) !bool {
	return uri in b.resources
}

fn (b &MemoryBackend) resource_get(uri string) !Resource {
	return b.resources[uri] or { return error('resource not found') }
}

fn (b &MemoryBackend) resource_list() ![]Resource {
	return b.resources.values()
}

fn (mut b MemoryBackend) resource_subscribe(uri string) ! {
	if uri !in b.subscriptions {
		b.subscriptions << uri
	}
}

fn (b &MemoryBackend) resource_subscribed(uri string) !bool {
	return uri in b.subscriptions
}

fn (mut b MemoryBackend) resource_unsubscribe(uri string) ! {
	b.subscriptions = b.subscriptions.filter(it != uri)
}

fn (b &MemoryBackend) resource_contents_get(uri string) ![]ResourceContent {
	return b.resource_contents[uri] or { return error('resource contents not found') }
}

fn (b &MemoryBackend) resource_templates_list() ![]ResourceTemplate {
	return b.resource_templates.values()
}

// Prompt related methods

fn (b &MemoryBackend) prompt_exists(name string) !bool {
	return name in b.prompts
}

fn (b &MemoryBackend) prompt_get(name string) !Prompt {
	return b.prompts[name] or { return error('prompt not found') }
}

fn (b &MemoryBackend) prompt_list() ![]Prompt {
	return b.prompts.values()
}

fn (b &MemoryBackend) prompt_messages_get(name string, arguments map[string]string) ![]PromptMessage {
	// Get the base messages for this prompt
	base_messages := b.prompt_messages[name] or { return error('prompt messages not found') }

	// Apply arguments to the messages
	mut messages := []PromptMessage{}

	for msg in base_messages {
		mut content := msg.content

		// If the content is text, replace argument placeholders
		if content.typ == 'text' {
			mut text := content.text

			// Replace each argument in the text
			for arg_name, arg_value in arguments {
				text = text.replace('{{${arg_name}}}', arg_value)
			}

			content = PromptContent{
				typ:      content.typ
				text:     text
				data:     content.data
				mimetype: content.mimetype
				resource: content.resource
			}
		}

		messages << PromptMessage{
			role:    msg.role
			content: content
		}
	}

	return messages
}

fn (b &MemoryBackend) prompt_call(name string, arguments []string) ![]PromptMessage {
	// Get the tool handler
	handler := b.prompt_handlers[name] or { return error('tool handler not found') }

	// Call the handler with the provided arguments
	return handler(arguments) or { panic(err) }
}

// Tool related methods

fn (b &MemoryBackend) tool_exists(name string) !bool {
	return name in b.tools
}

fn (b &MemoryBackend) tool_get(name string) !Tool {
	return b.tools[name] or { return error('tool not found') }
}

fn (b &MemoryBackend) tool_list() ![]Tool {
	return b.tools.values()
}

fn (b &MemoryBackend) tool_call(name string, arguments map[string]json2.Any) !ToolCallResult {
	// Get the tool handler
	handler := b.tool_handlers[name] or { return error('tool handler not found') }

	// Call the handler with the provided arguments
	return handler(arguments) or {
		// If the handler throws an error, return it as a tool error
		return ToolCallResult{
			is_error: true
			content:  [
				ToolContent{
					typ:  'text'
					text: 'Error: ${err.msg()}'
				},
			]
		}
	}
}
