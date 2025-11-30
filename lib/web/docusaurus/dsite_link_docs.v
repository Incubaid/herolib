module docusaurus

import incubaid.herolib.core.pathlib
import incubaid.herolib.data.atlas.client as atlas_client
import incubaid.herolib.data.markdown.tools as markdowntools
import incubaid.herolib.ui.console
import incubaid.herolib.web.site
import os

// ============================================================================
// Doc Linking - Generate Docusaurus docs from Atlas collections
// ============================================================================

// link_docs generates markdown files from site page definitions.
// Pages are fetched from Atlas collections and written with frontmatter.
pub fn (mut docsite DocSite) link_docs() ! {
	c := config()!
	docs_path := '${c.path_build.path}/docs'

	reset_docs_dir(docs_path)!
	console.print_header('Linking docs to ${docs_path}')

	mut client := atlas_client.new(export_dir: c.atlas_dir)!
	mut errors := []string{}

	for _, page in docsite.website.pages {
		process_page(mut client, docs_path, page, mut errors)
	}

	if errors.len > 0 {
		report_errors(mut client, errors)!
	}

	console.print_green('Successfully linked ${docsite.website.pages.len} pages to docs folder')
}

fn reset_docs_dir(docs_path string) ! {
	if os.exists(docs_path) {
		os.rmdir_all(docs_path) or {}
	}
	os.mkdir_all(docs_path)!
}

fn report_errors(mut client atlas_client.AtlasClient, errors []string) ! {
	available := client.list_markdown() or { 'Could not list available pages' }
	console.print_stderr('Available pages:\n${available}')
	return error('Errors during doc generation:\n${errors.join('\n\n')}')
}

// ============================================================================
// Page Processing
// ============================================================================

fn process_page(mut client atlas_client.AtlasClient, docs_path string, page site.Page, mut errors []string) {
	collection, page_name := parse_page_src(page.src) or {
		errors << err.msg()
		return
	}

	content := client.get_page_content(collection, page_name) or {
		errors << "Page not found: '${collection}:${page_name}'"
		return
	}

	write_page(docs_path, page_name, page, content) or {
		errors << "Failed to write page '${page_name}': ${err.msg()}"
		return
	}

	copy_page_assets(mut client, docs_path, collection, page_name)
	console.print_item('Generated: ${page_name}.md')
}

fn parse_page_src(src string) !(string, string) {
	parts := src.split(':')
	if parts.len != 2 {
		return error("Invalid src format '${src}' - expected 'collection:page_name'")
	}
	return parts[0], parts[1]
}

fn write_page(docs_path string, page_name string, page site.Page, content string) ! {
	frontmatter := build_frontmatter(page, content)
	final_content := frontmatter + '\n\n' + content

	output_path := '${docs_path}/${page_name}.md'
	mut file := pathlib.get_file(path: output_path, create: true)!
	file.write(final_content)!
}

fn copy_page_assets(mut client atlas_client.AtlasClient, docs_path string, collection string, page_name string) {
	client.copy_images(collection, page_name, docs_path) or {}
	client.copy_files(collection, page_name, docs_path) or {}
}

// ============================================================================
// Frontmatter Generation
// ============================================================================

fn build_frontmatter(page site.Page, content string) string {
	title := get_title(page, content)
	description := get_description(page, title)

	mut lines := ['---']
	lines << "title: '${escape_yaml(title)}'"
	lines << "description: '${escape_yaml(description)}'"

	if page.draft {
		lines << 'draft: true'
	}
	if page.hide_title {
		lines << 'hide_title: true'
	}

	lines << '---'
	return lines.join('\n')
}

fn get_title(page site.Page, content string) string {
	if page.title.len > 0 {
		return page.title
	}
	extracted := markdowntools.extract_title(content)
	if extracted.len > 0 {
		return extracted
	}
	return page.src.split(':').last()
}

fn get_description(page site.Page, title string) string {
	if page.description.len > 0 {
		return page.description
	}
	return title
}

fn escape_yaml(s string) string {
	return s.replace("'", "''")
}
