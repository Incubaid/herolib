module mcp

import x.json2

interface Backend {
	// Resource methods
	resource_exists(uri string) !bool
	resource_get(uri string) !Resource
	resource_list() ![]Resource
	resource_subscribed(uri string) !bool
	resource_contents_get(uri string) ![]ResourceContent
	resource_templates_list() ![]ResourceTemplate

	// Prompt methods
	prompt_exists(name string) !bool
	prompt_get(name string) !Prompt
	prompt_call(name string, arguments []string) ![]PromptMessage
	prompt_list() ![]Prompt
	prompt_messages_get(name string, arguments map[string]string) ![]PromptMessage

	// Tool methods
	tool_exists(name string) !bool
	tool_get(name string) !Tool
	tool_list() ![]Tool
	tool_call(name string, arguments map[string]json2.Any) !ToolCallResult
mut:
	resource_subscribe(uri string) !
	resource_unsubscribe(uri string) !
}
