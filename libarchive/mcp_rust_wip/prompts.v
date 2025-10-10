module rust

import freeflowuniverse.herolib.ai.mcp
import os
import x.json2 as json

// Prompt specification for Rust functions
const rust_functions_prompt_spec = mcp.Prompt{
	name:        'rust_functions'
	description: 'Provides guidance on working with Rust functions and using the list_functions_in_file tool'
	arguments:   []
}

// Handler for rust_functions prompt
pub fn rust_functions_prompt_handler(arguments []string) ![]mcp.PromptMessage {
	content := os.read_file('${os.dir(@FILE)}/prompts/functions.md')!

	return [
		mcp.PromptMessage{
			role:    'assistant'
			content: mcp.PromptContent{
				typ:  'text'
				text: content
			}
		},
	]
}

// Prompt specification for Rust structs
const rust_structs_prompt_spec = mcp.Prompt{
	name:        'rust_structs'
	description: 'Provides guidance on working with Rust structs and using the list_structs_in_file tool'
	arguments:   []
}

// Handler for rust_structs prompt
pub fn rust_structs_prompt_handler(arguments []string) ![]mcp.PromptMessage {
	content := os.read_file('${os.dir(@FILE)}/prompts/structs.md')!

	return [
		mcp.PromptMessage{
			role:    'assistant'
			content: mcp.PromptContent{
				typ:  'text'
				text: content
			}
		},
	]
}

// Prompt specification for Rust modules
const rust_modules_prompt_spec = mcp.Prompt{
	name:        'rust_modules'
	description: 'Provides guidance on working with Rust modules and using the list_modules_in_dir tool'
	arguments:   []
}

// Handler for rust_modules prompt
pub fn rust_modules_prompt_handler(arguments []string) ![]mcp.PromptMessage {
	content := os.read_file('${os.dir(@FILE)}/prompts/modules.md')!

	return [
		mcp.PromptMessage{
			role:    'assistant'
			content: mcp.PromptContent{
				typ:  'text'
				text: content
			}
		},
	]
}

// Prompt specification for Rust imports
const rust_imports_prompt_spec = mcp.Prompt{
	name:        'rust_imports'
	description: 'Provides guidance on working with Rust imports and using the get_import_statement tool'
	arguments:   []
}

// Handler for rust_imports prompt
pub fn rust_imports_prompt_handler(arguments []string) ![]mcp.PromptMessage {
	content := os.read_file('${os.dir(@FILE)}/prompts/imports.md')!

	return [
		mcp.PromptMessage{
			role:    'assistant'
			content: mcp.PromptContent{
				typ:  'text'
				text: content
			}
		},
	]
}

// Prompt specification for Rust dependencies
const rust_dependencies_prompt_spec = mcp.Prompt{
	name:        'rust_dependencies'
	description: 'Provides guidance on working with Rust dependencies and using the get_module_dependency tool'
	arguments:   []
}

// Handler for rust_dependencies prompt
pub fn rust_dependencies_prompt_handler(arguments []string) ![]mcp.PromptMessage {
	content := os.read_file('${os.dir(@FILE)}/prompts/dependencies.md')!

	return [
		mcp.PromptMessage{
			role:    'assistant'
			content: mcp.PromptContent{
				typ:  'text'
				text: content
			}
		},
	]
}

// Prompt specification for general Rust tools guide
const rust_tools_guide_prompt_spec = mcp.Prompt{
	name:        'rust_tools_guide'
	description: 'Provides a comprehensive guide on all available Rust tools and how to use them'
	arguments:   []
}

// Handler for rust_tools_guide prompt
pub fn rust_tools_guide_prompt_handler(arguments []string) ![]mcp.PromptMessage {
	// Combine all prompt files into one comprehensive guide
	functions_content := os.read_file('${os.dir(@FILE)}/prompts/functions.md')!
	structs_content := os.read_file('${os.dir(@FILE)}/prompts/structs.md')!
	modules_content := os.read_file('${os.dir(@FILE)}/prompts/modules.md')!
	imports_content := os.read_file('${os.dir(@FILE)}/prompts/imports.md')!
	dependencies_content := os.read_file('${os.dir(@FILE)}/prompts/dependencies.md')!

	combined_content := '# Rust Language Tools Guide\n\n' +
		'This guide provides comprehensive information on working with Rust code using the available tools.\n\n' +
		'## Table of Contents\n\n' + '1. [Functions](#functions)\n' + '2. [Structs](#structs)\n' +
		'3. [Modules](#modules)\n' + '4. [Imports](#imports)\n' +
		'5. [Dependencies](#dependencies)\n\n' + '<a name="functions"></a>\n' + functions_content +
		'\n\n' + '<a name="structs"></a>\n' + structs_content + '\n\n' +
		'<a name="modules"></a>\n' + modules_content + '\n\n' + '<a name="imports"></a>\n' +
		imports_content + '\n\n' + '<a name="dependencies"></a>\n' + dependencies_content

	return [
		mcp.PromptMessage{
			role:    'assistant'
			content: mcp.PromptContent{
				typ:  'text'
				text: combined_content
			}
		},
	]
}
