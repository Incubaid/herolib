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

	mut c := ''
	if args.description.len > 0 {
		c = '{
    "label": "${args.label}",
    "position": ${args.position},
    "link": {
      "type": "generated-index",
      "description": "${args.description}"
    }
  }'
	} else {
		c = '{
    "label": "${args.label}",
    "position": ${args.position},
    "link": {
      "type": "generated-index"
    }
  }'
	}

	mut category_path := '${generator.path.path}/${args.path}/_category_.json'
	mut catfile := pathlib.get_file(path: category_path, create: true)!

	catfile.write(c)!
}

// Strip numeric prefix from filename (e.g., "03_linux_installation" -> "linux_installation")
// Docusaurus automatically strips these prefixes from URLs
fn strip_numeric_prefix(name string) string {
	// Match pattern: digits followed by underscore at the start
	if name.len > 2 && name[0].is_digit() {
		for i := 1; i < name.len; i++ {
			if name[i] == `_` {
				// Found the underscore, return everything after it
				return name[i + 1..]
			}
			if !name[i].is_digit() {
				// Not a numeric prefix pattern, return as-is
				return name
			}
		}
	}
	return name
}

// Fix links to account for nested categories and Docusaurus URL conventions
fn (generator SiteGenerator) fix_links(content string) string {
	mut result := content

	// Build maps for link fixing
	mut collection_paths := map[string]string{} // collection -> directory path (for nested collections)
	mut page_to_path := map[string]string{} // page_name -> full directory path in Docusaurus
	mut collection_page_map := map[string]string{} // "collection:page" -> directory path

	for page in generator.site.pages {
		parts := page.src.split(':')
		if parts.len != 2 {
			continue
		}
		collection := parts[0]
		page_name := parts[1]

		// Extract directory path from page.path
		mut dir_path := page.path.trim('/')
		if dir_path.contains('/') && !dir_path.ends_with('/') {
			last_part := dir_path.all_after_last('/')
			if last_part.contains('.') || last_part == page_name {
				dir_path = dir_path.all_before_last('/')
			}
		}

		// Store collection -> directory mapping for nested collections
		if dir_path != collection && dir_path != '' {
			collection_paths[collection] = dir_path
		}

		// Store page_name -> directory path for fixing same-collection links
		// Strip numeric prefix from page_name for the map key
		clean_page_name := strip_numeric_prefix(page_name)
		page_to_path[clean_page_name] = dir_path

		// Store collection:page -> directory path for fixing collection:page format links
		collection_page_map['${collection}:${clean_page_name}'] = dir_path
	}

	// STEP 1: Strip numeric prefixes from all page references in links FIRST
	mut lines := result.split('\n')
	for i, line in lines {
		if !line.contains('](') {
			continue
		}

		mut new_line := line
		parts := line.split('](')
		if parts.len < 2 {
			continue
		}

		for j := 1; j < parts.len; j++ {
			close_idx := parts[j].index(')') or { continue }
			link_url := parts[j][..close_idx]

			mut new_url := link_url
			if link_url.contains('/') {
				path_part := link_url.all_before_last('/')
				file_part := link_url.all_after_last('/')
				new_file := strip_numeric_prefix(file_part)
				if new_file != file_part {
					new_url = '${path_part}/${new_file}'
				}
			} else {
				new_url = strip_numeric_prefix(link_url)
			}

			if new_url != link_url {
				new_line = new_line.replace('](${link_url})', '](${new_url})')
			}
		}
		lines[i] = new_line
	}
	result = lines.join('\n')

	// STEP 2: Replace ../collection/ with ../actual/nested/path/ for cross-collection links
	for collection, actual_path in collection_paths {
		result = result.replace('../${collection}/', '../${actual_path}/')
	}

	// STEP 3: Fix same-collection links: ./page -> correct path based on Docusaurus structure
	for page_name, target_dir in page_to_path {
		old_link := './${page_name}'
		if result.contains(old_link) && target_dir != '' {
			new_link := '../${target_dir}/${page_name}'
			result = result.replace(old_link, new_link)
		}
	}

	// STEP 4: Convert collection:page format to proper relative paths
	// Pattern: collection:page_name -> ../dir/page_name
	for collection_page, target_dir in collection_page_map {
		old_pattern := collection_page
		if result.contains(old_pattern) {
			// Extract just the page name from "collection:page"
			page_name := collection_page.all_after(':')
			mut new_link := ''
			if target_dir != '' {
				new_link = '../${target_dir}/${page_name}'
			} else {
				new_link = './${page_name}'
			}
			result = result.replace(old_pattern, new_link)
		}
	}

	// STEP 5: Remove .md extensions from all links (Docusaurus doesn't use them in URLs)
	result = result.replace('.md)', ')')

	return result
}
