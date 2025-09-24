module codewalker

// A minimal gitignore-like matcher used by CodeWalker
// Supports:
// - Directory patterns ending with '/': ignores any path that has this segment prefix
// - Extension patterns like '*.pyc' or '*.<ext>'
// - Simple substrings and '*' wildcards
// - Lines starting with '#' are comments; empty lines ignored
// No negation support for simplicity

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

struct IgnoreRule {
	base    string // relative dir from source root where the ignore file lives ('' means global)
	pattern string
}

pub struct IgnoreMatcher {
pub mut:
	rules []IgnoreRule
}

pub fn gitignore_matcher_new() IgnoreMatcher {
	mut m := IgnoreMatcher{}
	m.add_content(default_gitignore)
	return m
}

// Add raw .gitignore-style content as global (root-scoped) rules
pub fn (mut m IgnoreMatcher) add_content(content string) {
	m.add_content_with_base('', content)
}

// Add raw .gitignore/.heroignore-style content scoped to base_rel
pub fn (mut m IgnoreMatcher) add_content_with_base(base_rel string, content string) {
	mut base := base_rel.replace('\\', '/').trim('/').to_lower()
	for raw_line in content.split_into_lines() {
		mut line := raw_line.trim_space()
		if line.len == 0 || line.starts_with('#') {
			continue
		}
		m.rules << IgnoreRule{
			base:    base
			pattern: line
		}
	}
}

// Very simple glob/substring-based matching with directory scoping
pub fn (m IgnoreMatcher) is_ignored(relpath string) bool {
	mut path := relpath.replace('\\', '/').trim_left('/')
	path_low := path.to_lower()
	for rule in m.rules {
		mut pat := rule.pattern.replace('\\', '/').trim_space()
		if pat == '' {
			continue
		}

		// Determine subpath relative to base
		mut sub := path_low
		if rule.base != '' {
			base := rule.base
			if sub == base {
				// path equals the base dir; ignore rules apply to entries under base, not the base itself
				continue
			}
			if sub.starts_with(base + '/') {
				sub = sub[(base.len + 1)..]
			} else {
				continue // rule not applicable for this path
			}
		}

		// Directory pattern (relative to base)
		if pat.ends_with('/') {
			mut dirpat := pat.trim_right('/')
			dirpat = dirpat.trim_left('/').to_lower()
			if sub == dirpat || sub.starts_with(dirpat + '/') || sub.contains('/' + dirpat + '/') {
				return true
			}
			continue
		}
		// Extension pattern *.ext
		if pat.starts_with('*.') {
			ext := pat.all_after_last('.').to_lower()
			if sub.ends_with('.' + ext) {
				return true
			}
			continue
		}
		// Simple wildcard * anywhere -> sequential contains match
		if pat.contains('*') {
			mut parts := pat.to_lower().split('*')
			mut idx := 0
			mut ok := true
			for part in parts {
				if part == '' {
					continue
				}
				pos := sub.index_after(part, idx) or { -1 }
				if pos == -1 {
					ok = false
					break
				}
				idx = pos + part.len
			}
			if ok {
				return true
			}
			continue
		}
		// Fallback: substring match (case-insensitive) on subpath
		if sub.contains(pat.to_lower()) {
			return true
		}
	}
	return false
}
