module codewalker

import arrays

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

pub fn find_ignore_patterns() []string {
	mut patterns := default_gitignore.split_into_lines()
	patterns.sort()
	patterns = arrays.uniq(patterns)
	
	return patterns
}
