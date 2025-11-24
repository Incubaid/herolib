module codewalker

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

struct IgnoreRule {
	base    string // Directory where ignore file was found
	pattern string // Ignore pattern
}

// IgnoreMatcher checks if paths should be ignored
pub struct IgnoreMatcher {
pub mut:
	rules []IgnoreRule
}

// gitignore_matcher_new creates matcher with default patterns
pub fn gitignore_matcher_new() IgnoreMatcher {
	mut m := IgnoreMatcher{}
	m.add_content(default_gitignore)
	return m
}

// add_content adds global (root-scoped) ignore patterns
pub fn (mut m IgnoreMatcher) add_content(content string) {
	m.add_content_with_base('', content)
}

// add_content_with_base adds ignore patterns scoped to base directory
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

// is_ignored checks if path matches any ignore pattern
pub fn (m IgnoreMatcher) is_ignored(relpath string) bool {
	mut path := relpath.replace('\\', '/').trim_left('/')
	path_low := path.to_lower()
	for rule in m.rules {
		mut pat := rule.pattern.replace('\\', '/').trim_space()
		if pat == '' {
			continue
		}

		// Scope pattern to base directory
		mut sub := path_low
		if rule.base != '' {
			base := rule.base
			if sub == base {
				continue
			}
			if sub.starts_with(base + '/') {
				sub = sub[(base.len + 1)..]
			} else {
				continue
			}
		}

		// Directory pattern
		if pat.ends_with('/') {
			mut dirpat := pat.trim_right('/').trim_left('/').to_lower()
			if sub == dirpat || sub.starts_with(dirpat + '/') || sub.contains('/' + dirpat + '/') {
				return true
			}
			continue
		}
		// Extension pattern
		if pat.starts_with('*.') {
			ext := pat.all_after_last('.').to_lower()
			if sub.ends_with('.' + ext) {
				return true
			}
			continue
		}
		// Wildcard matching
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
		// Substring match
		if sub.contains(pat.to_lower()) {
			return true
		}
	}
	return false
}
