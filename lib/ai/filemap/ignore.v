module filemap

import arrays
import os
import incubaid.herolib.core.pathlib

// Default ignore patterns based on .gitignore conventions
const default_gitignore = '
.git/
.svn/
.hg/
.bzr/
node_modules/
__pycache__/
*.py[cod]
*.so
.Python
build/
develop-eggs/
downloads/
eggs/
.eggs/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
.env
.venv
venv/
.tox/
.nox/
.coverage
.coveragerc
coverage.xml
*.cover
*.gem
*.pyc
.cache
.pytest_cache/
.mypy_cache/
.hypothesis/
.DS_Store
Thumbs.db
*.tmp
*.temp
*.log
'

// find_ignore_patterns collects all .gitignore patterns from current directory up to repository root
//
// Walks up the directory tree using parent_find_advanced to locate all .gitignore files,
// stopping when it encounters the .git directory (repository root).
// Patterns are collected from:
//   1. Default ignore patterns (built-in)
//   2. All .gitignore files found from current directory to repository root
//   3. Filter out comments (lines starting with '#') and empty lines
//
// Parameters:
//   - start_path: Optional starting directory path (defaults to current working directory if empty)
//
// Returns:
//   - Combined, sorted, unique ignore patterns from all sources
//   - Error if path operations fail (file not found, permission denied, etc.)
//
// Examples:
//   // Use current working directory
//   patterns := find_ignore_patterns()!
//
//   // Use specific project directory
//   patterns := find_ignore_patterns('/home/user/myproject')!
pub fn find_ignore_patterns(start_path string) ![]string {
	mut patterns := default_gitignore.split_into_lines()

	// Use provided path or current working directory
	mut search_from := start_path
	if search_from == '' { // If an empty string was passed for start_path, use current working directory
		search_from = os.getwd()
	}

	mut current_path := pathlib.get(search_from)

	// Find all .gitignore files up the tree until we hit .git directory (repo root)
	mut gitignore_paths := current_path.parent_find_advanced('.gitignore', '.git')!

	// Read and collect patterns from all found .gitignore files
	for mut gitignore_path in gitignore_paths {
		if gitignore_path.is_file() {
			content := gitignore_path.read() or {
				// Skip files that can't be read (permission issues, etc.)
				continue
			}

			gitignore_lines := content.split_into_lines()
			for line in gitignore_lines {
				trimmed := line.trim_space()

				// Skip empty lines and comment lines
				if trimmed != '' && !trimmed.starts_with('#') {
					patterns << trimmed
				}
			}
		}
	}

	// Sort and get unique patterns to remove duplicates
	patterns.sort()
	patterns = arrays.uniq(patterns)

	return patterns
}
