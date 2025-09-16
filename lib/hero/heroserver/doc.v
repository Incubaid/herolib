module heroserver

import freeflowuniverse.herolib.schemas.openrpc
import os
import freeflowuniverse.herolib.schemas.jsonschema

// Documentation registry for managing multiple API docs
pub struct DocRegistry {
pub mut:
	apis          map[string]ApiDocInfo
	templates_dir string // Directory where user-provided markdown templates are stored
	discovered    bool   // Flag to prevent multiple template discoveries
}

pub struct ApiDocInfo {
pub:
	name        string
	title       string
	description string
	version     string
	spec        openrpc.OpenRPC
	handler     openrpc.Handler
}

pub fn new_doc_registry() &DocRegistry {
	templates_dir := os.join_path(os.dir(@FILE), 'templates', 'pages')
	return &DocRegistry{
		templates_dir: templates_dir
	}
}

// Register an API for documentation
pub fn (mut dr DocRegistry) register_api(name string, spec openrpc.OpenRPC, handler openrpc.Handler) {
	dr.apis[name] = ApiDocInfo{
		name:        name
		title:       spec.info.title
		description: spec.info.description
		version:     spec.info.version
		spec:        spec
		handler:     handler
	}
}

// Register the core HeroServer API documentation
pub fn (mut dr DocRegistry) register_core_api() {
	// Create a minimal OpenRPC spec for the core API
	core_spec := openrpc.OpenRPC{
		openrpc: '1.2.6'
		info:    openrpc.Info{
			title:       'HeroServer Core API'
			description: 'Core authentication and system endpoints for HeroServer'
			version:     '1.0.0'
		}
		methods: []
	}

	dr.apis['heroserver'] = ApiDocInfo{
		name:        'heroserver'
		title:       'HeroServer Core API'
		description: 'Core authentication and system endpoints for HeroServer'
		version:     '1.0.0'
		spec:        core_spec
		handler:     openrpc.Handler{
			specification: core_spec
		}
	}
}

// Discover and register documentation from template files
pub fn (mut dr DocRegistry) discover_template_docs() ! {
	// Prevent multiple discoveries
	if dr.discovered {
		return
	}
	dr.discovered = true

	if !os.exists(dr.templates_dir) {
		println('Templates directory does not exist: ${dr.templates_dir}')
		return
	}

	// Get all .md files in the templates directory
	files := os.ls(dr.templates_dir) or {
		println('Failed to read templates directory: ${err}')
		return
	}

	for file in files {
		if file.ends_with('.md') && file != 'doc.md' {
			// Extract API name from filename (remove .md extension)
			api_name := file.replace('.md', '')

			// Skip if already registered (e.g., heroserver_core_api.md becomes heroserver)
			if api_name == 'heroserver_core_api' {
				continue
			}

			// Read the markdown file to extract title and description
			file_path := os.join_path(dr.templates_dir, file)
			content := os.read_file(file_path) or {
				println('Failed to read template file ${file}: ${err}')
				continue
			}

			// Extract title and description from markdown
			title, description := dr.extract_doc_metadata(content, api_name)

			// Create a minimal spec for template-based docs
			template_spec := openrpc.OpenRPC{
				openrpc: '1.2.6'
				info:    openrpc.Info{
					title:       title
					description: description
					version:     '1.0.0'
				}
				methods: []
			}

			// Register the template-based API
			dr.apis[api_name] = ApiDocInfo{
				name:        api_name
				title:       title
				description: description
				version:     '1.0.0'
				spec:        template_spec
				handler:     openrpc.Handler{
					specification: template_spec
				}
			}

			println('Discovered documentation template: ${api_name} (${title})')
		}
	}
}

// Extract title and description from markdown content
fn (dr DocRegistry) extract_doc_metadata(content string, fallback_name string) (string, string) {
	lines := content.split('\n')
	mut title := fallback_name.replace('_', ' ').title()
	mut description := 'API documentation for ${title}'

	for line in lines {
		trimmed := line.trim_space()

		// Look for the first H1 heading as title
		if trimmed.starts_with('# ') && title == fallback_name.replace('_', ' ').title() {
			title = trimmed[2..].trim_space()
		}

		// Look for description in the first paragraph after title
		if trimmed.len > 0 && !trimmed.starts_with('#') && !trimmed.starts_with('**')
			&& !trimmed.starts_with('```') && description == 'API documentation for ${title}' {
			description = trimmed
			break
		}
	}

	return title, description
}

// Setup documentation system
pub fn (mut s HeroServer) setup_docs_site() ! {
	// Discover documentation templates first
	s.doc_registry.discover_template_docs()!

	println('Documentation system ready with ${s.doc_registry.apis.len} APIs')
	println('Available documentation:')
	for name, api_info in s.doc_registry.apis {
		println('  - ${api_info.title} (${name})')
	}
}

// Generate HTML documentation viewer for a specific API
pub fn (s HeroServer) generate_docs_viewer(api_name string) !string {
	// Load the HTML template
	template_path := os.join_path(os.dir(@FILE), 'templates/docs_viewer.html')
	template_content := os.read_file(template_path) or {
		return error('Failed to read docs viewer template: ${err}')
	}

	// Generate sidebar items
	mut sidebar_items := ''
	for name, api_info in s.doc_registry.apis {
		active_class := if name == api_name { ' class="active"' } else { '' }
		sidebar_items += '<li><a href="/docs/${name}"${active_class}>${api_info.title}</a></li>\n'
	}

	// Get the markdown content for the requested API
	content := s.get_api_markdown_content(api_name) or {
		return error('Failed to get markdown content for ${api_name}: ${err}')
	}

	// Convert markdown to HTML (simple conversion for now)
	html_content := s.markdown_to_html(content)

	// Get the API title
	api_info := s.doc_registry.apis[api_name] or { return error('API ${api_name} not found') }

	// Replace template variables
	mut result := template_content
	result = result.replace('@{title}', api_info.title)
	result = result.replace('@{sidebar_items}', sidebar_items)
	result = result.replace('@{content}', html_content)

	return result
}

// Get markdown content for an API
fn (s HeroServer) get_api_markdown_content(api_name string) !string {
	// Check if there's a custom template file for this API
	custom_template_path := os.join_path(s.doc_registry.templates_dir, '${api_name}.md')
	if os.exists(custom_template_path) {
		return os.read_file(custom_template_path) or {
			return error('Failed to read custom template for ${api_name}: ${err}')
		}
	}

	// For core HeroServer API, use the special template
	if api_name == 'heroserver' {
		core_template_path := os.join_path(os.dir(@FILE), 'templates/heroserver_core_api.md')
		return os.read_file(core_template_path) or {
			return error('Failed to read core API template: ${err}')
		}
	}

	// For OpenRPC-based APIs, generate from spec
	spec := s.handler_registry.get_spec(api_name) or {
		return error('No documentation found for ${api_name}')
	}

	// Load and process the generic template
	template_path := os.join_path(os.dir(@FILE), 'templates/doc.md')
	template_content := os.read_file(template_path) or {
		return error('Failed to read documentation template: ${err}')
	}

	// Process template with spec data
	return process_doc_template(template_content, spec, api_name)
}

// Simple markdown to HTML converter (basic implementation)
fn (s HeroServer) markdown_to_html(markdown string) string {
	mut html := markdown

	// Process headers more carefully
	html = s.process_headers(html)

	// Convert code blocks and process line by line
	lines := html.split('\n')
	mut result_lines := []string{}
	mut in_code_block := false

	for line in lines {
		if line.starts_with('```') {
			if in_code_block {
				result_lines << '</code></pre>'
				in_code_block = false
			} else {
				code_lang := line[3..].trim_space()
				result_lines << '<pre><code class="language-${code_lang}">'
				in_code_block = true
			}
		} else if in_code_block {
			// Escape HTML in code blocks
			escaped_line := line.replace('&', '&amp;').replace('<', '&lt;').replace('>',
				'&gt;')
			result_lines << escaped_line
		} else {
			// Process regular markdown
			mut processed_line := line

			// Process inline code first (before other replacements)
			processed_line = s.process_inline_code(processed_line)

			// Bold text
			processed_line = processed_line.replace('**', '<strong>').replace('**', '</strong>')

			// Paragraphs
			if processed_line.trim_space() == '' {
				processed_line = '</p><p>'
			}

			result_lines << processed_line
		}
	}

	html = result_lines.join('\n')

	// Wrap in paragraph tags
	html = '<p>' + html + '</p>'

	// Clean up empty paragraphs and code elements
	html = html.replace('<p></p>', '')
	html = html.replace('<p></p><p>', '<p>')
	html = html.replace('<code></code>', '')

	return html
}

// Process inline code with proper backtick handling
fn (s HeroServer) process_inline_code(line string) string {
	mut result := line
	mut in_code := false
	mut chars := result.runes()
	mut new_chars := []rune{}
	mut i := 0

	for i < chars.len {
		if chars[i] == `\`` {
			if in_code {
				// Closing backtick
				new_chars << '</code>'.runes()
				in_code = false
			} else {
				// Opening backtick
				new_chars << '<code>'.runes()
				in_code = true
			}
		} else {
			new_chars << chars[i]
		}
		i++
	}

	// If we ended with an unclosed code tag, close it
	if in_code {
		new_chars << '</code>'.runes()
	}

	return new_chars.string()
}

// Process headers with better detection to avoid false positives
fn (s HeroServer) process_headers(content string) string {
	lines := content.split('\n')
	mut result_lines := []string{}

	for line in lines {
		mut processed_line := line

		// Only process lines that start with # and have space after
		if line.starts_with('# ') && line.len > 2 {
			processed_line = '<h1>' + line[2..].trim_space() + '</h1>'
		} else if line.starts_with('## ') && line.len > 3 {
			processed_line = '<h2>' + line[3..].trim_space() + '</h2>'
		} else if line.starts_with('### ') && line.len > 4 {
			processed_line = '<h3>' + line[4..].trim_space() + '</h3>'
		} else if line.starts_with('#### ') && line.len > 5 {
			processed_line = '<h4>' + line[5..].trim_space() + '</h4>'
		}

		result_lines << processed_line
	}

	return result_lines.join('\n')
}

// Legacy function for backward compatibility - now redirects to markdown generation
pub fn (s HeroServer) generate_documentation(handler_type string, handler openrpc.Handler) !string {
	return 'Documentation is now served via built-in viewer at http://localhost:8080/docs'
}

// Process the markdown template with OpenRPC spec data
fn process_doc_template(template string, spec openrpc.OpenRPC, handler_type string) string {
	mut content := template

	// Replace template variables
	content = content.replace('@{handler_type}', handler_type)
	content = content.replace('@{spec.info.title}', spec.info.title)
	content = content.replace('@{spec.info.description}', spec.info.description)
	content = content.replace('@{spec.info.version}', spec.info.version)

	// Generate methods documentation
	mut methods_doc := ''
	for method in spec.methods {
		methods_doc += generate_method_doc(method)
	}
	content = content.replace('@{methods}', methods_doc)

	return content
}

// Generate documentation for a single method
fn generate_method_doc(method openrpc.Method) string {
	mut doc := '## ${method.name}\n\n'

	if method.description.len > 0 {
		doc += '${method.description}\n\n'
	}

	// Parameters
	if method.params.len > 0 {
		doc += '### Parameters\n\n'
		for param in method.params {
			// Handle both ContentDescriptor and Reference
			if param is openrpc.ContentDescriptor {
				if param.schema is jsonschema.Schema {
					schema := param.schema as jsonschema.Schema
					doc += '- **${param.name}** (${schema.typ}): ${param.description}\n'
				}
			}
		}
		doc += '\n'
	}

	// Result
	if method.result is openrpc.ContentDescriptor {
		result := method.result as openrpc.ContentDescriptor
		doc += '### Returns\n\n'
		doc += '${result.description}\n\n'
	}

	// Examples (would need to be added to OpenRPC spec or handled differently)
	doc += '### Example\n\n'
	doc += '```json\n'
	doc += '// Request example would go here\n'
	doc += '```\n\n'

	return doc
}
