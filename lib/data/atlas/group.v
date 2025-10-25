module atlas

import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import os

@[heap]
pub struct Group {
pub mut:
	name     string   // normalized to lowercase
	patterns []string // email patterns, normalized to lowercase
}

@[params]
pub struct GroupNewArgs {
pub mut:
	name     string   @[required]
	patterns []string @[required]
}

// Create a new Group
pub fn new_group(args GroupNewArgs) !Group {
	mut name := texttools.name_fix(args.name)
	mut patterns := args.patterns.map(it.to_lower())

	return Group{
		name:     name
		patterns: patterns
	}
}

// Check if email matches any pattern in this group
pub fn (g Group) matches(email string) bool {
	email_lower := email.to_lower()

	for pattern in g.patterns {
		if matches_pattern(email_lower, pattern) {
			return true
		}
	}
	return false
}

// Helper: match email against wildcard pattern
// '*@domain.com' matches 'user@domain.com'
// 'exact@email.com' matches only 'exact@email.com'
fn matches_pattern(email string, pattern string) bool {
	if pattern == '*' {
		return true
	}

	if !pattern.contains('*') {
		return email == pattern
	}

	// Handle wildcard patterns like '*@domain.com'
	if pattern.starts_with('*') {
		suffix := pattern[1..] // Remove the '*'
		return email.ends_with(suffix)
	}

	// Could add more complex patterns here if needed
	return false
}

// parse_group_file parses a single .group file, resolving includes recursively.
fn parse_group_file(filename string, base_path string, mut visited map[string]bool) !Group {
	if filename in visited {
		return error('Circular include detected: ${filename}')
	}

	visited[filename] = true

	mut group := Group{
		name:     texttools.name_fix(filename)
		patterns: []string{}
	}

	mut file_path := pathlib.get_file(path: '${base_path}/${filename}.group')!
	content := file_path.read()!

	for line_orig in content.split_into_lines() {
		line := line_orig.trim_space()
		if line.len == 0 || line.starts_with('//') {
			continue
		}

		if line.starts_with('include:') {
			mut included_name := line.trim_string_left('include:').trim_space()
			included_name = included_name.replace('.group', '') // Remove .group if present
			include_path := '${base_path}/${included_name}.group'
			if !os.exists(include_path) {
				return error('Included group file not found: ${included_name}.group')
			}
			included_group := parse_group_file(included_name, base_path, mut visited)!

			group.patterns << included_group.patterns
		} else {
			group.patterns << line.to_lower()
		}
	}

	return group
}
