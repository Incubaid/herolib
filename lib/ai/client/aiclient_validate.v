module client

import incubaid.herolib.core.pathlib
import markdown
import os
import prantlf.yaml { parse_text }
import x.json2

pub fn validate_vlang_content(path pathlib.Path) !string {
	// Use `v fmt -check` to validate V language syntax
	// If there are any formatting issues, `v fmt -check` will return a non-zero exit code
	// and print the issues to stderr.
	res := os.system('v fmt -check "${path.str()}" 2>/dev/null')
	if res != 0 {
		return 'V language syntax validation failed. File has formatting or syntax errors.'
	}
	return '' // empty means no error
}

pub fn validate_markdown_content(path_ pathlib.Path) !string {
	// Implement Markdown validation by attempting to convert to HTML
	// If there's an error during conversion, it indicates invalid Markdown.
	mut mypath := path_
	content := mypath.read() or { return 'Failed to read markdown file: ${err}' }
	mut xx := markdown.HtmlRenderer{}
	_ := markdown.render(content, mut xx) or { return 'Invalid Markdown content: ${err}' }
	return '' // empty means no error
}

pub fn validate_yaml_content(path_ pathlib.Path) !string {
	// Implement YAML validation by attempting to load the content
	mut mypath := path_
	content := mypath.read() or { return 'Failed to read YAML file: ${err}' }
	_ := parse_text(content) or { return 'Invalid YAML content: ${err}' }
	return '' // empty means no error
}

pub fn validate_json_content(path_ pathlib.Path) !string {
	// Implement JSON validation by attempting to decode the content
	mut mypath := path_
	content := mypath.read() or { return 'Failed to read JSON file: ${err}' }
	json2.decode[json2.Any](content) or { return 'Invalid JSON content: ${err}' }
	return '' // empty means no error
}
