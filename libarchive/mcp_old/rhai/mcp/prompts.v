module mcp

import incubaid.herolib.mcp
import incubaid.herolib.develop.codetools as code
import incubaid.herolib.mcp.rhai.logic
import incubaid.herolib.schemas.jsonschema
import incubaid.herolib.lang.rust
import x.json2 as json

// Tool definition for the create_rhai_wrapper function
const rhai_wrapper_prompt_spec = Prompt{
	name:        'rhai_wrapper'
	description: 'provides a prompt for creating Rhai wrappers for Rust functions that follow builder pattern and create examples corresponding to the provided example file'
	arguments:   [
		PromptArgument{
			name:        'source_path'
			description: 'Path to the source directory'
			required:    true
		},
	]
}

// Tool handler for the create_rhai_wrapper function
pub fn rhai_wrapper_prompt_handler(arguments []string) ![]PromptMessage {
	source_path := arguments[0]

	// Read and combine all Rust files in the source directory
	source_code := rust.read_source_code(source_path)!

	// Extract the module name from the directory path (last component)
	name := rust.extract_module_name_from_path(source_path)

	result := logic.rhai_wrapper_generation_prompt(name, source_code)!
	return [
		PromptMessage{
			role:    'assistant'
			content: PromptContent{
				typ:  'text'
				text: result
			}
		},
	]
}
