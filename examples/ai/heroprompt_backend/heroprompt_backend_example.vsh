#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

//! HeroPrompt Backend Example
//!
//! This example demonstrates how to use the heroprompt_backend module
//! for managing workspaces, directories, and generating code context.
//!
//! Run with: ./examples/ai/heroprompt_backend/heroprompt_backend_example.vsh

import incubaid.herolib.ai.heroprompt_backend
import incubaid.herolib.ui.console
import os

console.print_header('HeroPrompt Backend Example')

// ============================================
// 1. Create a new backend instance
// ============================================
console.print_header('Step 1: Initialize Backend')

mut backend := heroprompt_backend.new(name: 'example')!
println('Backend initialized: ${backend.name}')

// ============================================
// 2. Create a workspace
// ============================================
console.print_header('Step 2: Create Workspace')

mut ws := backend.create_workspace(name: 'My Code Project')!
println('Created workspace: ${ws.name}')
println('  ID: ${ws.id}')
println('  Created at: ${ws.created_at}')

// ============================================
// 3. Add directories to the workspace
// ============================================
console.print_header('Step 3: Add Directories')

// Use current directory or a specific path
project_path := os.getwd()
println('Adding directory: ${project_path}')

dir := backend.add_dir(
	workspace_id: ws.id
	path:         project_path
	name:         'herolib'
) or {
	println('Error adding directory: ${err}')
	return
}
println('Added directory: ${dir.name}')
println('  ID: ${dir.id}')
println('  Path: ${dir.path}')

// ============================================
// 4. List workspaces and directories
// ============================================
console.print_header('Step 4: List Workspaces & Directories')

workspaces := backend.list_workspaces()
println('Total workspaces: ${workspaces.len}')

for workspace in workspaces {
	println('\nWorkspace: ${workspace.name} (${workspace.id})')
	dirs := backend.list_dirs(workspace_id: workspace.id) or { continue }
	for d in dirs {
		println('  - ${d.name}: ${d.path}')
	}
}

// ============================================
// 5. List files (with ignore patterns)
// ============================================
console.print_header('Step 5: List Files')

files := backend.list_files(workspace_id: ws.id) or {
	println('Error listing files: ${err}')
	return
}

mut file_count := 0
for dir_id, file_map in files {
	println('\nDirectory ${dir_id}:')
	for path, _ in file_map.content {
		if file_count < 10 {
			println('  - ${path}')
		}
		file_count++
	}
	if file_count >= 10 {
		println('  ... and ${file_map.content.len - 10} more files')
	}
}
println('\nTotal files found: ${file_count}')

// ============================================
// 6. Search within workspace
// ============================================
console.print_header('Step 6: Search')

search_query := 'fn main'
println('Searching for: "${search_query}"')

results := backend.search(
	workspace_id: ws.id
	query:        search_query
	max_results:  5
) or {
	println('Error searching: ${err}')
	return
}

println('Found ${results.len} results:')
for result in results {
	println('  ${result.path}:${result.line_number}')
	println('    ${result.line.trim_space()}')
}

// ============================================
// 7. Update workspace
// ============================================
console.print_header('Step 7: Update Workspace')

backend.update_workspace(
	id:   ws.id
	name: 'Updated Project Name'
) or {
	println('Error updating workspace: ${err}')
	return
}

updated_ws := backend.get_workspace(id: ws.id) or {
	println('Error getting workspace: ${err}')
	return
}
println('Updated workspace name: ${updated_ws.name}')

// ============================================
// 8. Cleanup (optional)
// ============================================
console.print_header('Step 8: Cleanup')

backend.delete_workspace(id: ws.id) or {
	println('Error deleting workspace: ${err}')
	return
}
println('Workspace deleted successfully')

console.print_header('Example Complete!')

