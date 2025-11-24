module pathlib

import os
import regex
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools.regext

@[params]
pub struct ListArgs {
pub mut:
	// Include if matches any regex pattern
	regex []string
	// Exclude if matches any regex pattern
	regex_ignore []string
	// Include if matches any wildcard pattern (* = any sequence)
	filter []string
	// Exclude if matches any wildcard pattern
	filter_ignore []string
	// Traverse directories recursively
	recursive bool = true
	// Ignore files starting with . and _
	ignore_default bool = true
	// Include symlinks
	include_links bool
	// Return only directories
	dirs_only bool
	// Return only files
	files_only bool
}

// Result of list operation
pub struct PathList {
pub mut:
	// Root directory where listing started
	root string
	// Found paths
	paths []Path
}

// List files and directories with filtering
//
// Parameters:
//   - regex: Include if matches regex pattern (e.g., `r'.*\.v$'`)
//   - regex_ignore: Exclude if matches regex pattern
//   - filter: Include if matches wildcard pattern (e.g., `'*.txt'`, `'test*'`, `'config'`)
//   - filter_ignore: Exclude if matches wildcard pattern
//   - recursive: Traverse directories (default: true)
//   - ignore_default: Ignore files starting with . and _ (default: true)
//   - dirs_only: Return only directories
//   - files_only: Return only files
//   - include_links: Include symlinks in results
//
// Examples:
//   dir.list(regex: [r'.*\.v$'], recursive: true)!
//   dir.list(filter: ['*.txt', 'config*'], filter_ignore: ['*.bak'])!
//   dir.list(regex: [r'.*test.*'], regex_ignore: [r'.*_test\.v$'])!
pub fn (mut path Path) list(args_ ListArgs) !PathList {
	mut r := []regex.RE{}

	// Add regex patterns
	for regexstr in args_.regex {
		mut re := regex.regex_opt(regexstr) or {
			return error("cannot create regex for:'${regexstr}'")
		}
		r << re
	}

	// Convert wildcard filters to regex and add
	for filter_pattern in args_.filter {
		regex_pattern := regext.wildcard_to_regex(filter_pattern)
		mut re := regex.regex_opt(regex_pattern) or {
			return error("cannot create regex from filter:'${filter_pattern}'")
		}
		r << re
	}

	mut r_ignore := []regex.RE{}

	// Add regex ignore patterns
	for regexstr in args_.regex_ignore {
		mut re := regex.regex_opt(regexstr) or {
			return error("cannot create ignore regex for:'${regexstr}'")
		}
		r_ignore << re
	}

	// Convert wildcard ignore filters to regex and add
	for filter_pattern in args_.filter_ignore {
		regex_pattern := regext.wildcard_to_regex(filter_pattern)
		mut re := regex.regex_opt(regex_pattern) or {
			return error("cannot create ignore regex from filter:'${filter_pattern}'")
		}
		r_ignore << re
	}

	mut args := ListArgsInternal{
		regex:          r
		regex_ignore:   r_ignore
		recursive:      args_.recursive
		ignore_default: args_.ignore_default
		dirs_only:      args_.dirs_only
		files_only:     args_.files_only
		include_links:  args_.include_links
	}
	paths := path.list_internal(args)!
	mut pl := PathList{
		root:  path.path
		paths: paths
	}
	return pl
}

@[params]
pub struct ListArgsInternal {
mut:
	regex          []regex.RE
	regex_ignore   []regex.RE
	recursive      bool = true
	ignore_default bool = true
	dirs_only      bool
	files_only     bool
	include_links  bool
}

fn (mut path Path) list_internal(args ListArgsInternal) ![]Path {
	debug := false
	path.check()

	if !path.is_dir() && (!path.is_dir_link() || !args.include_links) {
		return []Path{}
	}
	if debug {
		console.print_header(' ${path.path}')
	}
	mut ls_result := os.ls(path.path) or { []string{} }
	ls_result.sort()
	mut all_list := []Path{}

	for item in ls_result {
		if debug {
			console.print_stdout('  - ${item}')
		}
		p := os.join_path(path.path, item)
		mut new_path := get(p)

		// Check for broken symlinks
		if !new_path.exists() {
			continue
		}

		// Skip symlinks if not included
		if new_path.is_link() && !args.include_links {
			continue
		}

		// Skip hidden/underscore files if ignore_default
		if args.ignore_default {
			if item.starts_with('_') || item.starts_with('.') {
				continue
			}
		}

		// Process directories
		if new_path.is_dir() || (new_path.is_dir_link() && args.include_links) {
			if args.recursive {
				mut rec_list := new_path.list_internal(args)!
				all_list << rec_list
			} else {
				if !args.files_only {
					all_list << new_path
				}
				continue
			}
		}

		// Check exclude patterns
		mut ignore_this := false
		for r_ignore in args.regex_ignore {
			if r_ignore.matches_string(item) {
				ignore_this = true
				break
			}
		}

		if ignore_this {
			continue
		}

		// Check include patterns
		mut include_this := false

		if args.regex.len == 0 {
			include_this = true
		} else {
			for r in args.regex {
				if r.matches_string(item) {
					include_this = true
					break
				}
			}
		}

		// Add to results if matches and not dirs_only
		if include_this && !args.dirs_only {
			if !args.files_only || new_path.is_file() {
				all_list << new_path
			}
		}
	}
	return all_list
}

// Copy all paths to destination directory
pub fn (mut pathlist PathList) copy(dest string) ! {
	for mut path in pathlist.paths {
		path.copy(dest: dest)!
	}
}

// Delete all paths
pub fn (mut pathlist PathList) delete() ! {
	for mut path in pathlist.paths {
		path.delete()!
	}
}
