module docusaurus

import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.web.doctreeclient
import freeflowuniverse.herolib.web.site { Page, Section, Site }
import freeflowuniverse.herolib.data.markdown.tools as markdowntools
import freeflowuniverse.herolib.ui.console

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
		println("Page List: is header collection and page name per collection.\nAvailable pages:\n${gen.client.list_markdown()!}")
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
