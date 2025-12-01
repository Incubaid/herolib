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

// get_first_doc_from_sidebar recursively finds the first doc ID in the sidebar.
// Used to determine which page should get slug: / in frontmatter when url_home ends with "/".
fn get_first_doc_from_sidebar(items []site.NavItem) string {
	for item in items {
		match item {
			site.NavDoc {
				return site.extract_page_id(item.id)
			}
			site.NavCat {
				// Recursively search in category items
				doc := get_first_doc_from_sidebar(item.items)
				if doc.len > 0 {
					return doc
				}
			}
			site.NavLink {
				// Skip links, we want docs
				continue
			}
		}
	}
	return ''
}

// link_docs generates markdown files from site page definitions.
// Pages are fetched from Atlas collections and written with frontmatter.
pub fn (mut docsite DocSite) link_docs() ! {
	c := config()!
	docs_path := '${c.path_build.path}/docs'

	reset_docs_dir(docs_path)!
	console.print_header('Linking docs to ${docs_path}')

	mut client := atlas_client.new(export_dir: c.atlas_dir)!
	mut errors := []string{}

	// Determine if we need to set a docs landing page (when url_home ends with "/")
	first_doc_page := if docsite.website.siteconfig.url_home.ends_with('/') {
		get_first_doc_from_sidebar(docsite.website.nav.my_sidebar)
	} else {
		''
	}

	for _, page in docsite.website.pages {
		process_page(mut client, docs_path, page, first_doc_page, mut errors)
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

fn process_page(mut client atlas_client.AtlasClient, docs_path string, page site.Page, first_doc_page string, mut errors []string) {
	collection, page_name := parse_page_src(page.src) or {
		errors << err.msg()
		return
	}

	content := client.get_page_content(collection, page_name) or {
		errors << "Page not found: '${collection}:${page_name}'"
		return
	}

	// Check if this page is the docs landing page
	is_landing_page := first_doc_page.len > 0 && page_name == first_doc_page

	write_page(docs_path, page_name, page, content, is_landing_page) or {
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

fn write_page(docs_path string, page_name string, page site.Page, content string, is_landing_page bool) ! {
	frontmatter := build_frontmatter(page, content, is_landing_page)
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

fn build_frontmatter(page site.Page, content string, is_landing_page bool) string {
	title := get_title(page, content)
	description := get_description(page, title)

	mut lines := ['---']
	lines << "title: '${escape_yaml(title)}'"
	lines << "description: '${escape_yaml(description)}'"

	// Add slug: / for the docs landing page so /docs/ works directly
	if is_landing_page {
		lines << 'slug: /'
	}

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
