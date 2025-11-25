#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.pathlib
import incubaid.herolib.ui.console
import incubaid.herolib.ai.client
import os

fn main() {
	console.print_header('Code Generator - V File Analyzer Using AI')

	// Find herolib root directory using @FILE
	script_dir := os.dir(@FILE)
	// Navigate from examples/core/code to root: up 4 levels
	herolib_root := os.dir(os.dir(os.dir(script_dir)))

	console.print_item('HeroLib Root: ${herolib_root}')

	// The directory we want to analyze (lib/core in this case)
	target_dir := herolib_root + '/lib/core'
	console.print_item('Target Directory: ${target_dir}')
	console.print_lf(1)

	// Load instruction files from aiprompts
	console.print_item('Loading instruction files...')

	mut ai_instructions_file := pathlib.get(herolib_root +
		'/aiprompts/ai_instructions_hero_models.md')
	mut vlang_core_file := pathlib.get(herolib_root + '/aiprompts/vlang_herolib_core.md')

	ai_instructions_content := ai_instructions_file.read()!
	vlang_core_content := vlang_core_file.read()!

	console.print_green('✓ Instruction files loaded successfully')
	console.print_lf(1)

	// Initialize AI client
	console.print_item('Initializing AI client...')
	mut aiclient := client.new()!
	console.print_green('✓ AI client initialized')
	console.print_lf(1)

	// Get all V files from target directory
	console.print_item('Scanning directory for V files...')

	mut target_path := pathlib.get_dir(path: target_dir, create: false)!
	mut all_files := target_path.list(
		regex:     [r'\.v$']
		recursive: true
	)!

	console.print_item('Found ${all_files.paths.len} total V files')

	// TODO: Walk over all files which do NOT end with _test.v and do NOT start with factory
	// Each file becomes a src_file_content object
	mut files_to_process := []pathlib.Path{}

	for file in all_files.paths {
		file_name := file.name()

		// Skip test files
		if file_name.ends_with('_test.v') {
			continue
		}

		// Skip factory files
		if file_name.starts_with('factory') {
			continue
		}

		files_to_process << file
	}

	console.print_green('✓ After filtering: ${files_to_process.len} files to process')
	console.print_lf(2)

	// Process each file with AI
	total_files := files_to_process.len

	for idx, mut file in files_to_process {
		current_idx := idx + 1
		process_file_with_ai(mut aiclient, mut file, ai_instructions_content, vlang_core_content,
			current_idx, total_files)!
	}

	console.print_lf(1)
	console.print_header('✓ Code Generation Complete')
	console.print_item('Processed ${files_to_process.len} files')
	console.print_lf(1)
}

fn process_file_with_ai(mut aiclient client.AIClient, mut file pathlib.Path, ai_instructions string, vlang_core string, current int, total int) ! {
	file_name := file.name()
	src_file_path := file.absolute()

	console.print_item('[${current}/${total}] Analyzing: ${file_name}')

	// Read the file content - this is the src_file_content
	src_file_content := file.read()!

	// Build comprehensive system prompt
	// TODO: Load instructions from prompt files and use in prompt

	// Build the user prompt with context
	user_prompt := '
File: ${file_name}
Path: ${src_file_path}

Current content:
\`\`\`v
${src_file_content}
\`\`\`

Please improve this V file by:
1. Following V language best practices
2. Ensuring proper error handling with ! and or blocks
3. Adding clear documentation comments
4. Following herolib patterns and conventions
5. Improving code clarity and readability

Context from herolib guidelines:

VLANG HEROLIB CORE:
${vlang_core}

AI INSTRUCTIONS FOR HERO MODELS:
${ai_instructions}

Return ONLY the complete improved file wrapped in \`\`\`v code block.
'

	console.print_debug_title('Sending to AI', 'Calling AI model to improve ${file_name}...')

	// TODO: Call AI client with model gemini-3-pro
	aiclient.write_from_prompt(file, user_prompt, [.pro]) or {
		console.print_stderr('Error processing ${file_name}: ${err}')
		return
	}

	mut improved_file := pathlib.get(src_file_path + '.improved')
	improved_content := improved_file.read()!

	// Display improvements summary
	sample_chars := 250
	preview := if improved_content.len > sample_chars {
		improved_content[..sample_chars] + '... (preview truncated)'
	} else {
		improved_content
	}

	console.print_debug_title('AI Analysis Results for ${file_name}', preview)

	// Optional: Save improved version for review
	// Uncomment to enable saving
	// improved_file_path := src_file_path + '.improved'
	// mut improved_file := pathlib.get_file(path: improved_file_path, create: true)!
	// improved_file.write(improved_content)!
	// console.print_green('✓ Improvements saved to: ${improved_file_path}')

	console.print_lf(1)
}

// Extract V code from markdown code block
fn extract_code_block(response string) string {
	// Look for ```v ... ``` block
	start_marker := '\`\`\`v'
	end_marker := '\`\`\`'

	start_idx := response.index(start_marker) or {
		// If no ```v, try to return as-is
		return response
	}

	mut content_start := start_idx + start_marker.len
	if content_start < response.len && response[content_start] == `\n` {
		content_start++
	}

	end_idx := response.index(end_marker) or { return response[content_start..] }

	extracted := response[content_start..end_idx]
	return extracted.trim_space()
}
