module heroprompt

import freeflowuniverse.herolib.develop.codewalker
import os

// Prompt generation functionality for HeroPrompt workspaces

// HeropromptTmpPrompt is the template struct for prompt generation
struct HeropromptTmpPrompt {
pub mut:
	user_instructions string
	file_map          string
	file_contents     string
}

@[params]
pub struct GenerateFileMapParams {
pub mut:
	selected_files []string // List of file paths to mark as selected (optional, if empty all files are selected)
	show_all       bool     // If true, show all files in directories; if false, show only selected files
}

// generate_file_map generates a hierarchical tree structure of the workspace
// with selected files marked with '*'
pub fn (ws &Workspace) generate_file_map(args GenerateFileMapParams) !string {
	mut all_files := []string{}
	mut selected_set := map[string]bool{}

	// Build set of selected files for quick lookup
	for path in args.selected_files {
		selected_set[path] = true
	}

	// Collect all files from directories
	for _, dir in ws.directories {
		content := dir.get_contents() or { continue }
		for file in content.files {
			all_files << file.path
		}
	}

	// Add standalone files
	for file in ws.files {
		all_files << file.path
	}

	// If no specific files selected, select all
	mut files_to_show := if args.selected_files.len > 0 {
		args.selected_files.clone()
	} else {
		all_files.clone()
	}

	// Find common base path
	mut base_path := ''
	if files_to_show.len > 0 {
		base_path = find_common_base_path(files_to_show)
	}

	// Generate tree using codewalker
	mut tree := ''
	if args.show_all {
		// Show full directory tree with selected files marked
		tree = generate_full_tree_with_selection(files_to_show, all_files, base_path)
	} else {
		// Show minimal tree with only selected files
		tree = codewalker.build_file_tree_selected(files_to_show, base_path)
	}

	// Add config note
	mut output := 'Config: directory-only view; selected files shown.\n\n'

	// Add base path if available
	if base_path.len > 0 {
		output += '${os.base(base_path)}\n'
	}

	output += tree

	return output
}

// find_common_base_path finds the common base directory for a list of file paths
fn find_common_base_path(paths []string) string {
	if paths.len == 0 {
		return ''
	}

	if paths.len == 1 {
		return os.dir(paths[0])
	}

	// Split all paths into components
	mut path_parts := [][]string{}
	for path in paths {
		parts := path.split(os.path_separator)
		path_parts << parts
	}

	// Find common prefix
	mut common := []string{}

	// Find minimum length
	mut min_len := path_parts[0].len
	for parts in path_parts {
		if parts.len < min_len {
			min_len = parts.len
		}
	}

	for i in 0 .. min_len - 1 { // -1 to exclude filename
		part := path_parts[0][i]
		mut all_match := true
		for j in 1 .. path_parts.len {
			if path_parts[j][i] != part {
				all_match = false
				break
			}
		}
		if all_match {
			common << part
		} else {
			break
		}
	}

	if common.len == 0 {
		return ''
	}

	return common.join(os.path_separator)
}

// generate_full_tree_with_selection generates a full directory tree with selected files marked
fn generate_full_tree_with_selection(selected_files []string, all_files []string, base_path string) string {
	// For now, use the minimal tree approach
	// TODO: Implement full tree with selective marking
	return codewalker.build_file_tree_selected(selected_files, base_path)
}

@[params]
pub struct GenerateFileContentsParams {
pub mut:
	selected_files []string // List of file paths to include (optional, if empty all files are included)
	include_path   bool = true // Include file path as header
}

// generate_file_contents generates formatted file contents section
pub fn (ws &Workspace) generate_file_contents(args GenerateFileContentsParams) !string {
	mut output := ''
	mut files_to_include := map[string]HeropromptFile{}

	// Collect all files from directories
	for _, dir in ws.directories {
		content := dir.get_contents() or { continue }
		for file in content.files {
			// Normalize path for consistent comparison
			normalized_path := os.real_path(file.path)

			// Create a mutable copy to update selection state
			mut file_copy := file

			// Check if file is selected in directory's selection map
			if normalized_path in dir.selected_files {
				file_copy.is_selected = dir.selected_files[normalized_path]
			}

			files_to_include[normalized_path] = file_copy
		}
	}

	// Add standalone files
	for file in ws.files {
		// Normalize path for consistent comparison
		normalized_path := os.real_path(file.path)
		files_to_include[normalized_path] = file
	}

	// Filter by selected files if specified
	mut files_to_output := []HeropromptFile{}
	if args.selected_files.len > 0 {
		for path in args.selected_files {
			// Normalize the selected path for comparison
			normalized_path := os.real_path(path)
			if normalized_path in files_to_include {
				files_to_output << files_to_include[normalized_path]
			}
		}
	} else {
		for _, file in files_to_include {
			files_to_output << file
		}
	}

	// Sort files by path for consistent output
	files_to_output.sort(a.path < b.path)

	// Generate content for each file
	for file in files_to_output {
		if args.include_path {
			output += 'File: ${file.path}\n'
		}

		// Determine language for syntax highlighting
		ext := file.extension()
		lang := if ext.len > 0 { ext } else { 'text' }

		output += '```${lang}\n'
		output += file.content
		if !file.content.ends_with('\n') {
			output += '\n'
		}
		output += '```\n\n'
	}

	return output
}

@[params]
pub struct GeneratePromptParams {
pub mut:
	instruction    string   // User's instruction/question
	selected_files []string // List of file paths to include (optional, if empty all files are included)
	show_all_files bool     // If true, show all files in file_map; if false, show only selected
}

// generate_prompt generates a complete AI prompt combining file_map, file_contents, and user instructions
// If selected_files is empty, automatically uses files marked as selected in the workspace
pub fn (ws &Workspace) generate_prompt(args GeneratePromptParams) !string {
	// Determine which files to include
	mut files_to_include := args.selected_files.clone()

	// If no files specified, use selected files from workspace
	if files_to_include.len == 0 {
		files_to_include = ws.get_selected_files() or { []string{} }

		// If still no files, return error with helpful message
		if files_to_include.len == 0 {
			return error('no files selected for prompt generation. Use select_file() to select files or provide selected_files parameter')
		}
	}

	// Generate file map
	file_map := ws.generate_file_map(
		selected_files: files_to_include
		show_all:       args.show_all_files
	)!

	// Generate file contents
	file_contents := ws.generate_file_contents(
		selected_files: files_to_include
		include_path:   true
	)!

	// Build user instructions
	mut user_instructions := args.instruction
	if user_instructions.len > 0 && !user_instructions.ends_with('\n') {
		user_instructions += '\n'
	}

	// Use template to generate prompt
	prompt := HeropromptTmpPrompt{
		user_instructions: user_instructions
		file_map:          file_map
		file_contents:     file_contents
	}

	result := $tmpl('./templates/prompt.template')
	return result
}

// generate_prompt_simple is a convenience method that generates a prompt with just an instruction
// and includes all files from the workspace
pub fn (ws &Workspace) generate_prompt_simple(instruction string) !string {
	return ws.generate_prompt(
		instruction:    instruction
		selected_files: []
		show_all_files: false
	)
}

// get_all_file_paths returns all file paths in the workspace
pub fn (ws &Workspace) get_all_file_paths() ![]string {
	mut paths := []string{}

	// Collect from directories
	for _, dir in ws.directories {
		content := dir.get_contents() or { continue }
		for file in content.files {
			paths << file.path
		}
	}

	// Add standalone files
	for file in ws.files {
		paths << file.path
	}

	return paths
}

// filter_files_by_extension filters file paths by extension
pub fn (ws &Workspace) filter_files_by_extension(extensions []string) ![]string {
	all_paths := ws.get_all_file_paths()!
	mut filtered := []string{}

	for path in all_paths {
		ext := os.file_ext(path).trim_left('.')
		if ext in extensions {
			filtered << path
		}
	}

	return filtered
}

// filter_files_by_pattern filters file paths by pattern (simple substring match)
pub fn (ws &Workspace) filter_files_by_pattern(pattern string) ![]string {
	all_paths := ws.get_all_file_paths()!
	mut filtered := []string{}

	pattern_lower := pattern.to_lower()
	for path in all_paths {
		if path.to_lower().contains(pattern_lower) {
			filtered << path
		}
	}

	return filtered
}
