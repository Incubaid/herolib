module ui

import os

// Recursive menu renderer
pub fn menu_html(items []MenuItem, depth int, prefix string) string {
	mut out := []string{}
	for i, it in items {
		id := '${prefix}_${depth}_${i}'
		if it.children.len > 0 {
			// expandable group
			out << '<div class="item">'
			out << '<a class="list-group-item list-group-item-action d-flex justify-content-between align-items-center" data-bs-toggle="collapse" href="#${id}" role="button" aria-expanded="${if depth == 0 {
				'true'
			} else {
				'false'
			}}" aria-controls="${id}">'
			out << '<span>${it.title}</span><span class="chev">&rsaquo;</span>'
			out << '</a>'
			out << '<div class="collapse ${if depth == 0 { 'show' } else { '' }}" id="${id}">'
			out << '<div class="ms-2 mt-1">'
			out << menu_html(it.children, depth + 1, id)
			out << '</div>'
			out << '</div>'
			out << '</div>'
		} else {
			// leaf
			out << '<a href="${it.href}" class="list-group-item list-group-item-action">${it.title}</a>'
		}
	}
	return out.join('\n')
}

// Language detection utility for code files
pub fn detect_lang(path string) string {
	ext := os.file_ext(path).trim_left('.')
	return match ext.to_lower() {
		'v' { 'v' }
		'js' { 'javascript' }
		'ts' { 'typescript' }
		'py' { 'python' }
		'rs' { 'rust' }
		'go' { 'go' }
		'java' { 'java' }
		'c', 'h' { 'c' }
		'cpp', 'hpp', 'cc', 'hh' { 'cpp' }
		'sh', 'bash' { 'bash' }
		'json' { 'json' }
		'yaml', 'yml' { 'yaml' }
		'html', 'htm' { 'html' }
		'css' { 'css' }
		'md' { 'markdown' }
		else { 'text' }
	}
}
