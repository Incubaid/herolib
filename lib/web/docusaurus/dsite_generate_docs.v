module docusaurus

import incubaid.herolib.core.pathlib
import incubaid.herolib.web.doctreeclient
import incubaid.herolib.web.site { Page, Section, Site }
import incubaid.herolib.data.markdown.tools as markdowntools
import incubaid.herolib.ui.console

// THIS CODE GENERATES A DOCUSAURUS SITE FROM A DOCTREECLIENT AND SITE DEFINITION

struct SiteGenerator {
mut:
	siteconfig_name string
	path            pathlib.Path
	client          &doctreeclient.DocTreeClient
	flat            bool // if flat then won't use sitenames as subdir's
	site            Site
	errors          []string // collect errors here
}

// Generate docs from site configuration
pub fn (mut docsite DocSite) generate_docs() ! {
	c := config()!

	// we generate the docs in the build path
	docs_path := '${c.path_build.path}/docs'

	mut gen := SiteGenerator{
		path:   pathlib.get_dir(path: docs_path, create: true)!
		client: doctreeclient.new()!
		flat:   true
		site:   docsite.website
	}

	for section in gen.site.sections {
		gen.section_generate(section)!
	}

	for page in gen.site.pages {
		gen.page_generate(page)!
	}

	if gen.errors.len > 0 {
		println('Page List: is header collection and page name per collection.\nAvailable pages:\n${gen.client.list_markdown()!}')
		return error('Errors occurred during site generation:\n${gen.errors.join('\n\n')}\n')
	}
}

fn (mut generator SiteGenerator) error(msg string) ! {
	console.print_stderr('Error: ${msg}')
	generator.errors << msg
}

fn (mut generator SiteGenerator) page_generate(args_ Page) ! {
	mut args := args_

	mut content := ['---']

	mut parts := args.src.split(':')
	if parts.len != 2 {
		generator.error("Invalid src format for page '${args.src}', expected format: collection:page_name, TODO: fix in ${args.path}, check the collection & page_name exists in the pagelist")!
		return
	}
	collection_name := parts[0]
	page_name := parts[1]

	mut page_content := generator.client.get_page_content(collection_name, page_name) or {
		generator.error("Couldn't find page '${collection_name}:${page_name}' is formatted as collectionname:pagename.  TODO: fix in ${args.path}, check the collection & page_name exists in the pagelist. ")!
		return
	}

	if args.description.len == 0 {
		descnew := markdowntools.extract_title(page_content)
		if descnew != '' {
			args.description = descnew
		} else {
			args.description = page_name
		}
	}

	if args.title.len == 0 {
		descnew := markdowntools.extract_title(page_content)
		if descnew != '' {
			args.title = descnew
		} else {
			args.title = page_name
		}
	}
	content << "title: '${args.title}'"

	if args.description.len > 0 {
		content << "description: '${args.description}'"
	}

	if args.slug.len > 0 {
		content << "slug: '${args.slug}'"
	}

	if args.hide_title {
		content << 'hide_title: ${args.hide_title}'
	}

	if args.draft {
		content << 'draft: ${args.draft}'
	}

	if args.position > 0 {
		content << 'sidebar_position: ${args.position}'
	}

	content << '---'

	mut c := content.join('\n')

	if args.title_nr > 0 {
		// Set the title number in the page content
		page_content = markdowntools.set_titles(page_content, args.title_nr)
	}

	// Fix links to account for nested categories
	page_content = generator.fix_links(page_content)

	c += '\n${page_content}\n'

	if args.path.ends_with('/') || args.path.trim_space() == '' {
		// means is dir
		args.path += page_name
	}

	if !args.path.ends_with('.md') {
		args.path += '.md'
	}

	mut pagepath := '${generator.path.path}/${args.path}'
	mut pagefile := pathlib.get_file(path: pagepath, create: true)!

	pagefile.write(c)!

	generator.client.copy_images(collection_name, page_name, pagefile.path_dir()) or {
		generator.error("Couldn't copy image ${pagefile} for '${page_name}' in collection '${collection_name}', try to find the image and fix the path is in ${args.path}.}\nError: ${err}")!
		return
	}
}

fn (mut generator SiteGenerator) section_generate(args_ Section) ! {
	mut args := args_

	mut c := '{
    "label": "${args.label}",
    "position": ${args.position},
    "link": {
      "type": "generated-index"
    }
  }'

	mut category_path := '${generator.path.path}/${args.path}/_category_.json'
	mut catfile := pathlib.get_file(path: category_path, create: true)!

	catfile.write(c)!
}

// Fix links to account for nested categories in Docusaurus
// Doctree exports links as ../collection/page.md but Docusaurus may have nested paths
fn (generator SiteGenerator) fix_links(content string) string {
	mut result := content

	// Build a map of collection name to actual directory path
	mut collection_paths := map[string]string{}
	for page in generator.site.pages {
		parts := page.src.split(':')
		if parts.len != 2 {
			continue
		}
		collection := parts[0]

		// Extract directory path from page.path
		// page.path can be like "appendix/internet_today/" or "appendix/internet_today/page.md"
		mut dir_path := page.path.trim('/')

		// If path ends with a filename, remove it to get just the directory
		if dir_path.contains('/') && !dir_path.ends_with('/') {
			// Check if last part looks like a filename (has extension or is a page name)
			last_part := dir_path.all_after_last('/')
			if last_part.contains('.') || last_part == parts[1] {
				dir_path = dir_path.all_before_last('/')
			}
		}

		// If the directory path is different from collection name, store the mapping
		// This handles nested categories like appendix/internet_today
		if dir_path != collection && dir_path != '' {
			collection_paths[collection] = dir_path
		}
	}

	// Replace ../collection/ with ../actual/nested/path/ for nested collections
	for collection, actual_path in collection_paths {
		result = result.replace('../${collection}/', '../${actual_path}/')
	}

	// Remove .md extensions from all links (Docusaurus doesn't use them in URLs)
	result = result.replace('.md)', ')')

	return result
}
