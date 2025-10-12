#!/usr/bin/env -S v -n -w -gc none -cg -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.develop.heroprompt
import os

println('=== HeroPrompt: AI Prompt Generation Example ===\n')

// ============================================================================
// STEP 1: Cleanup and Setup
// ============================================================================
// Always start fresh - delete any existing instance
println('Step 1: Cleaning up any existing instance...')
heroprompt.delete(name: 'prompt_demo') or {}
println('✓ Cleanup complete\n')

// ============================================================================
// STEP 2: Create HeroPrompt Instance
// ============================================================================
// Get or create a new HeroPrompt instance
// The 'create: true' parameter will create it if it doesn't exist
println('Step 2: Creating HeroPrompt instance...')
mut hp := heroprompt.get(name: 'prompt_demo', create: true)!
println('✓ Created instance: ${hp.name}\n')

// ============================================================================
// STEP 3: Create Workspace
// ============================================================================
// A workspace is a collection of directories and files
// The first workspace is automatically set as active
println('Step 3: Creating workspace...')
mut workspace := hp.new_workspace(
	name:        'my_project'
	description: 'Example project workspace'
)!
println('✓ Created workspace: ${workspace.name}')
println('  Active: ${workspace.is_active}')
println('  Description: ${workspace.description}\n')

// ============================================================================
// STEP 4: Add Directories to Workspace
// ============================================================================
// Add directories containing code you want to analyze
// The 'scan: true' parameter automatically scans all files and subdirectories
println('Step 4: Adding directories to workspace...')

homepath := os.home_dir()

// Add the examples directory
mut examples_dir := workspace.add_directory(
	path: '${homepath}/code/github/freeflowuniverse/herolib/examples/develop/heroprompt'
	name: 'examples'
	scan: true
)!
println('✓ Added directory: examples')

// Add the library directory
mut lib_dir := workspace.add_directory(
	path: '${homepath}/code/github/freeflowuniverse/herolib/lib/develop/heroprompt'
	name: 'library'
	scan: true
)!
println('✓ Added directory: library\n')

// ============================================================================
// STEP 5: Select Specific Files
// ============================================================================
// You can select specific files from directories for prompt generation
// This is useful when you only want to analyze certain files
println('Step 5: Selecting specific files...')

// Select individual files from the examples directory
examples_dir.select_file(
	path: '${homepath}/code/github/freeflowuniverse/herolib/examples/develop/heroprompt/README.md'
)!
println('✓ Selected: README.md')

examples_dir.select_file(
	path: '${homepath}/code/github/freeflowuniverse/herolib/examples/develop/heroprompt/prompt_example.vsh'
)!
println('✓ Selected: prompt_example.vsh')

// Select all files from the library directory
lib_dir.select_all()!
println('✓ Selected all files in library directory\n')

// ============================================================================
// STEP 6: Generate AI Prompt
// ============================================================================
// Generate a complete prompt with file map, file contents, and instructions
// The prompt automatically includes only the selected files
println('Step 6: Generating AI prompt...')

prompt := workspace.generate_prompt(
	instruction: 'Review the selected files and provide suggestions for improvements.'
)!

println('✓ Generated prompt')
println('  Total length: ${prompt.len} characters\n')

// ============================================================================
// STEP 7: Display Prompt Preview
// ============================================================================
println('Step 7: Prompt preview (first 800 characters)...')
preview_len := if prompt.len > 800 { 800 } else { prompt.len }
println(prompt[..preview_len])

// ============================================================================
// STEP 8: Alternative - Get Active Workspace
// ============================================================================
// You can retrieve the active workspace without knowing its name
println('Step 8: Working with active workspace...')

mut active_ws := hp.get_active_workspace()!
println('✓ Retrieved active workspace: ${active_ws.name}')
println('  Directories: ${active_ws.directories.len}')
println('  Files: ${active_ws.files.len}\n')

// ============================================================================
// STEP 9: Set Different Active Workspace
// ============================================================================
// You can create multiple workspaces and switch between them
println('Step 9: Creating and switching workspaces...')

// Create a second workspace
mut workspace2 := hp.new_workspace(
	name:        'documentation'
	description: 'Documentation workspace'
	is_active:   false
)!
println('✓ Created workspace: ${workspace2.name}')

// Switch active workspace
hp.set_active_workspace('documentation')!
println('✓ Set active workspace to: documentation')

// Verify the switch
active_ws = hp.get_active_workspace()!
println('✓ Current active workspace: ${active_ws.name}\n')

// ============================================================================
// STEP 10: Cleanup
// ============================================================================
println('Step 10: Cleanup...')
heroprompt.delete(name: 'prompt_demo')!
println('✓ Deleted instance\n')
